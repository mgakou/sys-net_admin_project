# 04 — RBAC de l'indexer : chaque client ne lit que ses alertes

## Principe

OpenSearch Security contrôle qui peut lire quels index. Pour chaque client :

| Objet | Nom | Rôle |
|---|---|---|
| Rôle | `client_cla_ro` | Lecture seule sur `wazuh-alerts-4.x-cla-*` |
| Rattachement (role mapping) | `client_cla_ro` ← backend role `client_cla` | Relie le rôle aux utilisateurs |
| Utilisateur de test | `clienta_test` | Backend roles `kibanauser` (accès dashboard) + `client_cla` |

## Préparation

Saisir le mot de passe admin une seule fois (non affiché, absent de l'historique) :

```bash
read -s -p "Mot de passe admin indexer : " ADMINPW; echo
API="https://localhost:9200/_plugins/_security/api"
```

## 1. Créer le rôle

Modèle : [configs/indexer/role-client.json](../configs/indexer/role-client.json)

```bash
curl -sk -u "admin:$ADMINPW" -X PUT "$API/roles/client_cla_ro" \
 -H 'Content-Type: application/json' -d '{
  "cluster_permissions": ["cluster_composite_ops_ro"],
  "index_permissions": [{
    "index_patterns": ["wazuh-alerts-4.x-cla-*"],
    "allowed_actions": ["read"]
  }]
}'; echo
```

## 2. Créer l'utilisateur de test

Vérifier d'abord que `kibanauser` est le backend role qui donne accès au dashboard :

```bash
curl -sk -u "admin:$ADMINPW" "$API/rolesmapping/kibana_user?pretty"
```

Puis :

```bash
read -s -p "Mot de passe de clienta_test : " CLIPW; echo
curl -sk -u "admin:$ADMINPW" -X PUT "$API/internalusers/clienta_test" \
 -H 'Content-Type: application/json' -d "{
  \"password\": \"$CLIPW\",
  \"backend_roles\": [\"kibanauser\", \"client_cla\"],
  \"description\": \"Utilisateur de test - client A\"
}"; echo
```

## 3. Créer le rattachement

```bash
curl -sk -u "admin:$ADMINPW" -X PUT "$API/rolesmapping/client_cla_ro" \
 -H 'Content-Type: application/json' -d '{ "backend_roles": ["client_cla"] }'; echo
```

Vérifier les rôles effectifs :

```bash
curl -sk -u clienta_test "https://localhost:9200/_plugins/_security/authinfo?pretty" | grep -A4 '"roles"'
```

`client_cla_ro` doit apparaître à côté de `kibana_user`.

> **Piège rencontré** : l'utilisateur avait ses backend roles, mais le rattachement n'avait pas été créé → `rolesmapping 'client_cla_ro' not found`. Toujours vérifier la réponse de chaque `PUT` (`CREATED` ou `OK`).

## 4. Tests d'isolation

Automatisés par [`scripts/check_isolation.sh`](../scripts/check_isolation.sh).

| Test | Requête | Attendu | Obtenu |
|---|---|---|---|
| 1. Ses propres données | `wazuh-alerts-4.x-cla-*/_count` | un nombre | `"count" : 14` ✅ |
| 2. Données d'un autre client | `wazuh-alerts-4.x-clb-*/_count` | 403 | `security_exception`, `"status" : 403` ✅ |
| 3. Motif global (dashboard) | `wazuh-alerts-*/_search` | voir ci-dessous | 403 (avant correctif) |

Extrait du test 2 :

```json
"type" : "security_exception",
"reason" : "no permissions for [indices:data/read/search] and User [name=clienta_test, backend_roles=[kibanauser, client_cla], requestedTenant=null]"
"status" : 403
```

## 5. Rendre le dashboard utilisable : `do_not_fail_on_forbidden`

Le test 3 échoue en 403 : par défaut, OpenSearch refuse **toute** la recherche dès que le motif `wazuh-alerts-*` englobe un index interdit. Ce n'est pas une fuite, mais le dashboard Wazuh (qui utilise ce motif) ne fonctionnerait pas pour le client.

Avec `do_not_fail_on_forbidden: true`, les index interdits sont **ignorés** au lieu de faire échouer la recherche.

```bash
cd /etc/wazuh-indexer/opensearch-security/
sudo cp config.yml config.yml.orig
sudo vi config.yml
```

Sous `config:` → `dynamic:` (extrait : [configs/indexer/config-dynamic.yml](../configs/indexer/config-dynamic.yml)) :

```yaml
config:
  dynamic:
    do_not_fail_on_forbidden: true
```

Appliquer **uniquement** ce fichier (`-t config` : utilisateurs et rôles non touchés) :

```bash
sudo JAVA_HOME=/usr/share/wazuh-indexer/jdk/ \
 /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
 -f /etc/wazuh-indexer/opensearch-security/config.yml -t config \
 -icl -nhnv \
 -cacert /etc/wazuh-indexer/certs/root-ca.pem \
 -cert /etc/wazuh-indexer/certs/admin.pem \
 -key /etc/wazuh-indexer/certs/admin-key.pem \
 -h 127.0.0.1
```

Attendu après correctif :

- test 3 avec `clienta_test` : environ 14 documents, un seul bucket `cla` ;
- même requête avec `admin` : `cla`, `clb` et `unassigned` (les analystes ne perdent rien).

## 6. Vérification dans le dashboard

Connecté avec `clienta_test` :

- **Last 24 hours alerts** : 2 (medium) + 12 (low) = **14 alertes**, exactement le contenu de `wazuh-alerts-4.x-cla-*` ✅
- **Agents summary** : « aucun agent » → attendu à ce stade : la liste des agents vient de l'API Wazuh, qui a son propre RBAC (voir [05-rbac-api-wazuh.md](05-rbac-api-wazuh.md)).

## À faire

- Retirer au client l'accès au **tenant global** (actuellement `global_tenant: true`), où se trouvent les tableaux de bord partagés du SOC.
