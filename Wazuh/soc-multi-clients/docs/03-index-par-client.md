# 03 — Un index par client : modification du pipeline Filebeat

## Principe

Par défaut, toutes les alertes Wazuh vont dans un index commun (`wazuh-alerts-4.x-AAAA.MM.JJ`). On modifie **une seule fois** le pipeline d'ingestion Filebeat pour qu'il construise le nom d'index à partir du label client de chaque alerte :

```
wazuh-alerts-4.x-<client>-AAAA.MM.JJ
```

Le pipeline ne contient **aucun nom de client** : un nouveau client obtient son index automatiquement dès que ses agents portent le label.

## Les deux modifications

Fichier : `/usr/share/filebeat/module/wazuh/alerts/ingest/pipeline.json`

**1. Juste après le processeur `json`** (premier de la liste), ajouter :

```json
{ "set": { "field": "agent.labels.client", "value": "unassigned", "override": false } },
{ "lowercase": { "field": "agent.labels.client", "ignore_missing": true } }
```

- `set` avec `override: false` : écrit `unassigned` **uniquement** si l'alerte n'a pas de label (alertes du manager, agents non affectés).
- `lowercase` : OpenSearch refuse les majuscules dans les noms d'index.

**2. Dans le processeur `date_index_name`**, remplacer le préfixe :

```diff
- "index_name_prefix": "{{fields.index_prefix}}",
+ "index_name_prefix": "{{fields.index_prefix}}{{agent.labels.client}}-",
```

Extrait complet : [configs/filebeat/processeurs-client.json](../configs/filebeat/processeurs-client.json)

## Application

### Option A — script (recommandé, idempotent)

```bash
sudo python3 scripts/patch_pipeline.py            # sauvegarde + modification
sudo python3 scripts/patch_pipeline.py --check    # vérifie (utile après une mise à jour)
```

### Option B — à la main

```bash
cd /usr/share/filebeat/module/wazuh/alerts/ingest/
sudo cp pipeline.json pipeline.json.orig
sudo vi pipeline.json
sudo python3 -m json.tool pipeline.json > /dev/null && echo "JSON OK"
```

### Recharger dans l'indexer

```bash
sudo filebeat setup --pipelines

# Vérifier que la version chargée contient bien la modification
curl -sk -u admin "https://localhost:9200/_ingest/pipeline/filebeat-7.10.2-wazuh-alerts-pipeline?pretty" \
  | grep -E 'unassigned|index_name_prefix'
```

> `-u admin` sans mot de passe : curl le demande, il n'apparaît pas dans l'historique.

## Test à blanc (`_simulate`)

On fait passer deux fausses alertes dans le pipeline, sans rien indexer :

```bash
curl -sk -u admin -X POST \
 "https://localhost:9200/_ingest/pipeline/filebeat-7.10.2-wazuh-alerts-pipeline/_simulate?pretty" \
 -H 'Content-Type: application/json' -d '{
 "docs": [
  {"_source": {"fields": {"index_prefix": "wazuh-alerts-4.x-"},
   "message": "{\"timestamp\":\"2026-09-26T21:00:00.000+0000\",\"agent\":{\"id\":\"010\",\"name\":\"LABSIEM-UBUNTU\",\"labels\":{\"client\":\"cla\"}},\"rule\":{\"id\":\"5710\"}}"}},
  {"_source": {"fields": {"index_prefix": "wazuh-alerts-4.x-"},
   "message": "{\"timestamp\":\"2026-09-26T21:00:00.000+0000\",\"agent\":{\"id\":\"000\",\"name\":\"wazuh-server\"},\"rule\":{\"id\":\"5710\"}}"}}
 ]}' | grep '"_index"'
```

Résultat obtenu :

```
"_index" : "<wazuh-alerts-4.x-cla-{2026.09.26||/d{yyyy.MM.dd|UTC}}>"
"_index" : "<wazuh-alerts-4.x-unassigned-{2026.09.26||/d{yyyy.MM.dd|UTC}}>"
```

C'est une *expression de date* que l'indexer résout à l'indexation (→ `wazuh-alerts-4.x-cla-2026.09.26`).

> Si la commande ne renvoie rien, un processeur a échoué : relancer sans `| grep` pour lire l'erreur.

## Activation

```bash
sudo systemctl restart filebeat
sudo filebeat test output
```

## Résultats

Index créés après génération d'alertes chez chaque client :

```
$ curl -sk -u admin "https://localhost:9200/_cat/indices/wazuh-alerts-*?v&s=index"
health status index                                   pri rep docs.count  store.size
green  open   wazuh-alerts-4.x-cla-2026.09.26           3   0         14     158.8kb
green  open   wazuh-alerts-4.x-clb-2026.09.26           3   0          4     183.1kb
green  open   wazuh-alerts-4.x-unassigned-2026.09.26    3   0       2169       1.9mb
```

Contrôle : **aucun agent client ne doit apparaître dans `unassigned`** (voir aussi [`scripts/audit_routage.sh`](../scripts/audit_routage.sh)) :

```
$ curl ... "wazuh-alerts-4.x-unassigned-*/_search" -d '{"aggs":{"agents":{"terms":{"field":"agent.name"}}}}'
"buckets" : [
  { "key" : "labsiem-service", "doc_count" : 2529 },
  { "key" : "wazuh-server",    "doc_count" : 16 }
]
```

Seuls le manager et l'agent volontairement non affecté y figurent : ✅ routage correct.

## Points d'attention

- **Mises à jour Wazuh** : une mise à jour du module Filebeat peut réécrire `pipeline.json`. Relancer `patch_pipeline.py --check` après chaque mise à jour.
- **Données existantes** : les alertes antérieures restent dans l'ancien index commun ; on les laisse expirer.
- **Date en UTC** : l'index du jour suivant est créé à minuit UTC (2 h, heure de Paris en été).
- **`unassigned` sert d'alarme** : tout agent client qui y apparaît est un agent oublié à affecter.
- Les nouveaux index commencent toujours par `wazuh-alerts-4.x-` : le modèle d'index Wazuh (mappings) et le motif `wazuh-alerts-*` du dashboard continuent de fonctionner.

## Retour arrière

```bash
cd /usr/share/filebeat/module/wazuh/alerts/ingest/
sudo cp pipeline.json.orig pipeline.json
sudo filebeat setup --pipelines && sudo systemctl restart filebeat
```
