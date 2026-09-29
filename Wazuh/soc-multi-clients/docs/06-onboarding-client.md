# 06 — Intégrer un nouveau client

Exemple : un client C (`clc`) avec 4 machines. Le pipeline et l'infrastructure ne changent pas ; seuls des éléments « par client » sont ajoutés.

## 0. Informations à collecter

| Élément | Exemple |
|---|---|
| Code client | `clc` |
| Plage NAT réservée au SOC | `100.64.3.0/24` |
| Rétention | 90 jours |
| Accès dashboard pour le client | oui / non |

| Nom Wazuh | Système | Rôle |
|---|---|---|
| `CLC-DC01` | Windows Server 2022 | Contrôleur de domaine |
| `CLC-FS01` | Windows Server 2022 | Serveur de fichiers |
| `CLC-WEB01` | Ubuntu 22.04 | Serveur web |
| `CLC-PC01` | Windows 11 | Poste utilisateur |

Les agents s'enregistrent avec l'IP `any` : pour Wazuh, ce qui compte est le **nom** (unique) et le **groupe**.

## 1. Réseau (pfSense)

- Tunnel IPsec entre le pare-feu du client et le SOC.
- NAT du réseau client vers sa plage dédiée (évite les collisions entre clients qui utilisent le même adressage).
- N'autoriser que **1514 et 1515/TCP** de cette plage vers le manager.

## 2 à 4. Script d'intégration

```bash
sudo ./scripts/onboard_client.sh clc                  # groupe, label, rôle, rattachement
sudo ./scripts/onboard_client.sh clc --create-user clientc_portail   # + utilisateur client
```

Le script :

1. crée le groupe `client-clc` et son `agent.conf` avec le label `client: clc` ;
2. crée le rôle `client_clc_ro` (lecture seule sur `wazuh-alerts-4.x-clc-*`) et son rattachement au backend role `client_clc` ;
3. crée éventuellement un utilisateur avec les backend roles `kibanauser` + `client_clc` ;
4. affiche les commandes d'installation des agents, prêtes à l'emploi ;
5. rappelle l'étape RBAC de l'API Wazuh (manuelle pour l'instant, voir [05](05-rbac-api-wazuh.md)).

Il est **idempotent** : le relancer ne casse rien.

## 5. Déployer les agents

L'agent doit être en version **égale ou inférieure** au manager.

**Linux** (dépôt Wazuh ajouté) :

```bash
sudo WAZUH_MANAGER="<IP_MANAGER>" WAZUH_AGENT_GROUP="client-clc" WAZUH_AGENT_NAME="CLC-WEB01" \
  apt-get install -y wazuh-agent=4.14.8-1
sudo systemctl daemon-reload && sudo systemctl enable --now wazuh-agent
```

**Windows** (PowerShell administrateur) :

```powershell
msiexec /i wazuh-agent-4.14.8-1.msi /q WAZUH_MANAGER="<IP_MANAGER>" `
  WAZUH_AGENT_GROUP="client-clc" WAZUH_AGENT_NAME="CLC-DC01"
NET START WazuhSvc
```

Chez un vrai client, déploiement en masse par GPO, SCCM ou Intune avec la même commande.

## 6. Vérifications

```bash
sudo /var/ossec/bin/agent_groups -l -g client-clc           # 4 agents actifs
./scripts/audit_routage.sh                                  # index clc créé, rien de CLC dans unassigned
./scripts/check_isolation.sh --client clc --user clientc_portail --other cla
```

## Ce qui est automatisé

| Étape | Automatisée |
|---|---|
| Réseau (tunnel, NAT) | Non (configuration avec le client) |
| Groupe et label | ✅ |
| Rôle, rattachement, utilisateur | ✅ |
| RBAC API Wazuh | 🔄 à venir |
| Rétention ISM | 🔄 à venir |
| Agents | Commandes générées |
| Vérifications | ✅ scripts |
