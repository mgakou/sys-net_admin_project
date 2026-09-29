# 05 — RBAC de l'API Wazuh (en cours)

## Pourquoi une deuxième couche

Le dashboard affiche deux sources de données, chacune avec ses propres permissions :

| Zone du dashboard | Source | Permission appliquée |
|---|---|---|
| Alertes, graphiques, Discover | Indexer (OpenSearch) | Rôle `client_<code>_ro` ([04](04-rbac-indexer.md)) |
| Liste des agents, inventaire, SCA, configuration | API Wazuh du manager (port 55000) | **RBAC de l'API Wazuh** |

Sans RBAC côté API, un compte client voit soit aucun agent (état actuel, sûr mais trop restrictif), soit les agents de **tous** les clients (fuite).

## Prérequis : `run_as`

Le dashboard doit appliquer les droits de l'utilisateur connecté, et non ceux du compte technique :

```bash
sudo grep -n "run_as" /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml
# attendu : run_as: true
sudo systemctl restart wazuh-dashboard   # si modifié
```

## Configuration (dashboard, en admin)

Menu ☰ → **Server management** → **Security**.

**1. Politique** `client-cla-read`

| Actions | Ressource | Effet |
|---|---|---|
| `agent:read` | `agent:group:client-cla` | allow |
| `syscheck:read`, `sca:read`, `syscollector:read`, `rootcheck:read` | `agent:group:client-cla` | allow |
| `group:read` | `group:id:client-cla` | allow |

Si l'interface n'accepte qu'un type de ressource par politique, créer deux politiques (`agent:group` et `group:id`).

**2. Rôle** `client_cla`, auquel on attache la ou les politiques.

**3. Rattachement** (Roles mapping) : rôle `client_cla` ← utilisateur interne `clienta_test`.

## Test attendu

Reconnecté avec `clienta_test` :

- **1 agent** visible : `LABSIEM-UBUNTU` ;
- aucune trace de `LABSIEM-W10` ni de `labsiem-service` ;
- les onglets de détail de l'agent (inventaire, SCA, FIM) s'affichent. Toute erreur de permission indique une action à ajouter à la politique.

## Statut

🔄 Configuration en cours. Cette page sera complétée avec les résultats et, à terme, l'automatisation via l'API Wazuh (`/security/policies`, `/security/roles`, `/security/rules`) dans `onboard_client.sh`.
