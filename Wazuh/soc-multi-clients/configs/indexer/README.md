# Modèles de configuration de l'indexer

| Fichier | Usage |
|---|---|
| `role-client.json` | Rôle lecture seule d'un client. `__CODE__` est remplacé par le code client (ex. `cla`). |
| `rolesmapping-client.json` | Rattache le rôle au backend role `client_<code>`. |
| `config-dynamic.yml` | Extrait de `config.yml` : active `do_not_fail_on_forbidden`. |

Utilisés par `scripts/onboard_client.sh`.
