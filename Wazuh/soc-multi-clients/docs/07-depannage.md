# 07 — Dépannage : problèmes rencontrés et solutions

Problèmes réellement rencontrés pendant la mise en place du lab.

| # | Symptôme | Cause | Solution |
|---|---|---|---|
| 1 | `agent_control: command not found` sur l'agent | Commande propre au **manager** | Lancer `agent_control`, `cluster_control`, `manage_agents -r` sur le manager |
| 2 | L'agent supprimé revient avec un nouvel ID (004 → 008 → 009 → 010) | L'agent tournait encore : clé refusée, il se ré-enrôle automatiquement | **Arrêter l'agent avant** de le supprimer côté manager |
| 3 | Manager 4.14.4, agent 4.14.8 | Agent plus récent que le manager (non supporté) | Mise à jour de la stack : indexer → manager → dashboard → agents |
| 4 | Manager arrêté : `Error reading XML file 'etc/ossec.conf' (line 0)`, `wazuh-db->failed`, `Cannot find 'queue/db/wdb'` | `ossec.conf` en `root:root` : l'utilisateur `wazuh` ne peut plus le lire | `chown root:wazuh` + `chmod 660` (voir ci-dessous) |
| 5 | Journal : `Duplicate name ..., rejecting enrollment` | Conséquence du #4 (wazuh-db indisponible) ; ou vrai doublon de nom | Réparer #4 ; en production, préfixer les noms d'agents par client |
| 6 | Service Windows « démarré puis arrêté » | Erreur de syntaxe / d'encodage dans `ossec.conf` après ajout de `<enrollment>` | Bloc dans `<client>`, un seul `<enrollment>`, enregistrer en UTF-8/ANSI, lire `ossec.log` |
| 7 | `Error 1751 - Could not assign agent to group` | L'agent est déjà dans le groupe | `agent_groups -s -i <ID>` |
| 8 | `curl` ne renvoie rien | Mot de passe d'exemple laissé tel quel | `-u admin` seul : saisie interactive |
| 9 | `_simulate` renvoie une expression `<…{date\|\|/d…}>` | Normal : expression de date résolue à l'indexation | Rien à faire |
| 10 | L'utilisateur client n'a pas le rôle attendu | Le rattachement (role mapping) n'existait pas | Recréer le rolesmapping, vérifier avec `_security/authinfo` |
| 11 | 403 sur `wazuh-alerts-*` pour un client | Comportement par défaut d'OpenSearch | `do_not_fail_on_forbidden: true` ([04](04-rbac-indexer.md)) |
| 12 | Dashboard client : alertes visibles, « aucun agent » | Deux couches de permissions : l'API Wazuh n'a pas encore de RBAC client | Configurer le RBAC de l'API ([05](05-rbac-api-wazuh.md)) |

## Focus : le manager qui ne démarre plus (#4)

Le message pointait vers le **contenu** du fichier (« line 0 »), mais le fichier était intact (9 Ko, en-tête valide). La vraie cause était ses **droits** :

```
-rw-rw----. 1 root root 9427 ... /var/ossec/etc/ossec.conf     # attendu : root wazuh
```

Correction :

```bash
sudo chown root:wazuh /var/ossec/etc/ossec.conf
sudo chmod 660 /var/ossec/etc/ossec.conf
sudo ls -l /var/ossec/etc/          # tout doit appartenir au groupe wazuh
sudo systemctl restart wazuh-manager
sudo /var/ossec/bin/wazuh-control status
```

Prévention : éditer les fichiers Wazuh directement avec `sudo vi`, sans les recopier par `cp`/`mv` depuis un autre emplacement (perte du groupe `wazuh`).

## Commandes de diagnostic

```bash
# Manager
sudo /var/ossec/bin/wazuh-control status
sudo /var/ossec/bin/agent_control -l
sudo /var/ossec/bin/agent_control -i <ID>
sudo tail -n 30 /var/ossec/logs/ossec.log

# Agent Linux
sudo /var/ossec/bin/wazuh-control status
sudo cat /var/ossec/etc/client.keys
sudo cat /var/ossec/etc/shared/agent.conf
sudo tail -n 30 /var/ossec/logs/ossec.log
```

```powershell
# Agent Windows
Get-Service -Name WazuhSvc
Get-Content "C:\Program Files (x86)\ossec-agent\shared\agent.conf"
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20
```
