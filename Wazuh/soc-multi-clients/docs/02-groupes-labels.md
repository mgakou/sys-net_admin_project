# 02 — Groupes d'agents et labels client

## Principe

Chaque client a **un groupe d'agents** sur le manager. Le fichier `agent.conf` de ce groupe définit un **label** `client: <code>`, automatiquement poussé à tous les agents du groupe. Ce label se retrouve ensuite dans chaque alerte (`agent.labels.client`).

Pourquoi par le groupe plutôt que dans la configuration locale de l'agent ? Le groupe est piloté par le manager : un administrateur côté client ne peut pas modifier son label pour lire les données d'un autre.

## 1. Créer les groupes (manager)

```bash
sudo /var/ossec/bin/agent_groups -a -g client-cla -q
sudo /var/ossec/bin/agent_groups -a -g client-clb -q
```

## 2. Définir le label de chaque groupe

`/var/ossec/etc/shared/client-cla/agent.conf` (voir [configs/manager/shared/client-cla/agent.conf](../configs/manager/shared/client-cla/agent.conf)) :

```xml
<agent_config>
  <labels>
    <label key="client">cla</label>
  </labels>
</agent_config>
```

> Éditer avec `sudo vi` directement. Le fichier doit rester lisible par l'utilisateur `wazuh` (`chown wazuh:wazuh`).

## 3. Affecter un agent existant à un groupe

Méthode recommandée : **depuis le manager**, sans supprimer ni ré-enrôler l'agent.

```bash
sudo /var/ossec/bin/agent_groups -a -i 007 -g client-clb -q   # ajouter au groupe
sudo /var/ossec/bin/agent_groups -r -i 007 -g default -q      # retirer de default
sudo /var/ossec/bin/agent_groups -s -i 007                    # vérifier
sudo /var/ossec/bin/agent_groups -l -g client-clb             # agents du groupe
```

L'agent récupère la configuration du groupe en quelques minutes, sans redémarrage.

## 4. Filet de sécurité côté agent : bloc `<enrollment>`

Si un agent se ré-enrôle un jour (clé perdue, suppression), il retomberait dans `default` et perdrait son label. Ce bloc, dans la section `<client>` de son `ossec.conf`, fixe le groupe (voir [configs/agent/enrollment.xml](../configs/agent/enrollment.xml)) :

```xml
<enrollment>
  <enabled>yes</enabled>
  <groups>client-cla</groups>
</enrollment>
```

| Système | Fichier | Redémarrage |
|---|---|---|
| Linux | `/var/ossec/etc/ossec.conf` | `sudo systemctl restart wazuh-agent` |
| Windows | `C:\Program Files (x86)\ossec-agent\ossec.conf` (éditeur en administrateur, encodage UTF-8/ANSI) | `Restart-Service -Name WazuhSvc` |

À l'installation d'un nouvel agent, les variables `WAZUH_AGENT_GROUP` et `WAZUH_AGENT_NAME` écrivent ce bloc automatiquement (voir [06-onboarding-client.md](06-onboarding-client.md)).

## 5. Vérifier que le label arrive dans les alertes

Sur l'agent :

```bash
sudo cat /var/ossec/etc/shared/agent.conf     # doit contenir le label
```

Sur le manager, après avoir provoqué une alerte (ex. `ssh fauxcompte@localhost` sur l'Ubuntu) :

```bash
sudo tail -n 500 /var/ossec/logs/alerts/alerts.json \
  | grep -o '"labels":{[^}]*}' | sort | uniq -c
```

Résultat obtenu dans le lab :

```
      5 "labels":{"client":"cla"}
      2 "labels":{"client":"clb"}
```

## État du lab

| ID | Agent | Système | Groupe |
|---|---|---|---|
| 005 | labsiem-service | Ubuntu 20.04 | `default` (non affecté) |
| 007 | LABSIEM-W10 | Windows 10 Pro | `client-clb` |
| 010 | LABSIEM-UBUNTU | Ubuntu 22.04 | `client-cla` |
