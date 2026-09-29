# 01 — Architecture

## Objectif

Simuler un **SOC mutualisé** capable de servir plusieurs clients depuis une seule plateforme Wazuh, avec :

- une isolation stricte des données de chaque client ;
- aucune infrastructure dédiée par client ;
- une procédure d'ajout de client répétable et automatisable.

## Machines du lab

| VM | Rôle | Réseau |
|---|---|---|
| LABSIEM-FIREWALL | pfSense : passerelle, pare-feu, VPN WireGuard | LAN `192.168.99.1`, VPN `10.10.200.1` |
| LABSIEM-WAZUH | SOC central : manager + indexer + dashboard (all-in-one, v4.14.8) | LAN |
| LABSIEM-UBUNTU | **Client A** — agent Wazuh, groupe `client-cla` | `192.168.99.20` |
| LABSIEM-W10 | **Client B** — agent Wazuh, groupe `client-clb` | `192.168.99.10` |
| labsiem-service | Agent non affecté (volontairement) → index `unassigned` | `192.168.99.100` |
| LABSIEM-KALI | Attaquant (scénarios à venir) | LAN |

**Accès analyste** : un poste client se connecte en WireGuard (`10.10.200.2`) à pfSense (UDP sur le WAN), avec accès au LAN du lab.

> Toutes les adresses sont privées et propres au lab.

## Rôle des composants Wazuh

| Composant | Rôle |
|---|---|
| **Manager** | Reçoit les événements des agents, applique les règles, produit les alertes. Expose l'API Wazuh (55000). |
| **Master** | Manager « chef » d'un cluster : détient règles, groupes et clés, les synchronise vers les workers. |
| **Worker** | Manager qui absorbe la charge des agents ; reçoit sa configuration du master. |
| **Indexer** | Cluster OpenSearch : stocke et rend cherchables les alertes. N'analyse rien. |
| **Dashboard** | Interface web ; interroge l'indexer (alertes) et l'API du master (agents, configuration). |

Le lab est actuellement en **all-in-one** (un manager, un indexer). Le passage en cluster master/worker est prévu (voir [feuille de route](08-feuille-de-route.md)).

## Matrice de flux (cible)

| Source | Destination | Port | Usage |
|---|---|---|---|
| Agents clients | Manager / worker | 1514/TCP | Événements |
| Agents clients | Manager | 1515/TCP | Enrôlement |
| Worker | Master | 1516/TCP | Synchronisation cluster |
| Manager (Filebeat) | Indexer | 9200/TCP | Envoi des alertes |
| Dashboard | Indexer | 9200/TCP | Requêtes |
| Dashboard | Master | 55000/TCP | API Wazuh |
| Analystes (VPN) | Dashboard | 443/TCP | Interface |

## Conventions multi-clients

| Élément | Convention | Client A | Client B |
|---|---|---|---|
| Code client | 3 lettres minuscules | `cla` | `clb` |
| Groupe d'agents | `client-<code>` | `client-cla` | `client-clb` |
| Label | `client: <code>` | `client: cla` | `client: clb` |
| Index | `wazuh-alerts-4.x-<code>-AAAA.MM.JJ` | `…-cla-*` | `…-clb-*` |
| Rôle indexer | `client_<code>_ro` | `client_cla_ro` | `client_clb_ro` |
| Backend role | `client_<code>` | `client_cla` | `client_clb` |
| Agents sans label | index `unassigned` | — | — |

> **Noms d'agents** : dans le lab, les noms d'origine sont conservés. En production, préfixer par le code client (`CLA-SRV-DC01`) est recommandé : les noms doivent être **uniques** sur tout le manager, sinon l'enrôlement est refusé (« Duplicate name »).

## Les trois couches de cloisonnement

1. **Collecte** — le groupe d'agents, piloté par le manager, pousse un label `client`. Le client ne peut pas le modifier.
2. **Stockage** — le pipeline Filebeat lit ce label et range l'alerte dans l'index du client.
3. **Accès** — deux RBAC distincts :
   - OpenSearch Security (indexer) : qui lit quels index ;
   - RBAC de l'API Wazuh : qui voit quels agents et quelle configuration dans le dashboard.

## Choix d'architecture

| Choix | Alternative écartée | Raison |
|---|---|---|
| Un socle mutualisé + conventions | Une stack Wazuh par client | Coût et exploitation qui explosent avec le nombre de clients |
| Label poussé par le groupe | Label dans `ossec.conf` de l'agent | Le client pourrait modifier son propre label |
| Index par client | Un index commun + DLS | Rétention par client possible (ISM), filtrage plus simple et plus sûr |
| `do_not_fail_on_forbidden` | Motif d'index dédié par client dans le dashboard | Le dashboard Wazuh utilise `wazuh-alerts-*` partout |

Pour un client aux contraintes fortes (réglementation, souveraineté), une stack dédiée reste possible, interrogée depuis le SOC par *cross-cluster search*.
