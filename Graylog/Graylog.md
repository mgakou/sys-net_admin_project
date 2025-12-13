# TP - Détection et Analyse de Logs avec Graylog

Atelier Cybersécurité - Détection de Menaces
📖 Introduction

* Cet atelier combine trois composants essentiels : SIEM (Graylog) : centralisation et analyse des logs
* Antivirus (ClamWin) : détection par signatures
* Logs Windows (Sysmon) : événements système détaillés

Objectif : Comprendre comment ces outils se complètent pour une détection efficace.

## 🎯 Objectifs
* Installer Graylog, ClamWin, Sysmon et NXLog
* Centraliser les logs dans Graylog
* Créer des alertes de détection
* Simuler et analyser une attaque ClickFix
* Comparer antivirus vs détection comportementale

## 🐧 Partie 1 : Installation de Graylog (Machine Linux)
### 1.1 Installation de Docker

```
# Télécharger le script d'installation
curl -fsSL https://get.docker.com -o get-docker.sh
# Exécuter le script
sudo sh get-docker.sh
# Créer le groupe docker
sudo groupadd docker
# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
# Redémarrer la session (déconnexion/reconnexion)
# Ou utiliser : newgrp docker
```

Vérification :
```

docker --version
docker compose version
```

### 1.2 Configuration système pour DataNode
Avant de lancer Graylog, il est nécessaire d'augmenter la limite de map count pour Elasticsearch/DataNode :
```
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf 
sudo sysctl -p
```

### 1.3 Création du fichier docker-compose.yml
```

nano docker-compose.yml
```

Contenu du fichier docker-compose.yml 
```
version: "3.8"

services:
  # --------------------------------------------------
  # MongoDB
  # --------------------------------------------------
  mongodb:
    image: mongo:7.0
    restart: on-failure
    networks:
      - graylog
    volumes:
      - mongodb_data:/data/db
      - mongodb_config:/data/configdb

  # --------------------------------------------------
  # Graylog Data Node
  # --------------------------------------------------
  datanode:
    image: "${DATANODE_IMAGE:-graylog/graylog-datanode:7.0}"
    hostname: datanode
    restart: on-failure
    networks:
      - graylog
    environment:
      GRAYLOG_DATANODE_NODE_ID_FILE: "/var/lib/graylog-datanode/node-id"
      GRAYLOG_DATANODE_PASSWORD_SECRET: "${GRAYLOG_PASSWORD_SECRET:?Please configure GRAYLOG_PASSWORD_SECRET in the .env file}"
      GRAYLOG_DATANODE_MONGODB_URI: "mongodb://mongodb:27017/graylog"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    ports:
      - "8999:8999/tcp"  # DataNode API
      - "9200:9200/tcp"
      - "9300:9300/tcp"
    volumes:
      - graylog-datanode:/var/lib/graylog-datanode

  # --------------------------------------------------
  # Graylog Server
  # --------------------------------------------------
  graylog:
    image: "${GRAYLOG_IMAGE:-graylog/graylog:7.0}"
    hostname: server
    restart: on-failure
    entrypoint: "/usr/bin/tini -- /docker-entrypoint.sh"
    networks:
      - graylog
    depends_on:
      mongodb:
        condition: service_started
      datanode:
        condition: service_started
    environment:
      GRAYLOG_NODE_ID_FILE: "/usr/share/graylog/data/data/node-id"
      GRAYLOG_PASSWORD_SECRET: "${GRAYLOG_PASSWORD_SECRET:?Please configure GRAYLOG_PASSWORD_SECRET in the .env file}"
      GRAYLOG_ROOT_PASSWORD_SHA2: "${GRAYLOG_ROOT_PASSWORD_SHA2:?Please configure GRAYLOG_ROOT_PASSWORD_SHA2 in the .env file}"
      GRAYLOG_HTTP_BIND_ADDRESS: "0.0.0.0:9000"
      GRAYLOG_HTTP_EXTERNAL_URI: "http://localhost:9000/"
      GRAYLOG_MONGODB_URI: "mongodb://mongodb:27017/graylog"
    ports:
      - "5044:5044/tcp"   # Beats
      - "5140:5140/udp"   # Syslog UDP
      - "5140:5140/tcp"   # Syslog TCP
      - "5555:5555/tcp"   # RAW TCP
      - "5555:5555/udp"   # RAW UDP
      - "9000:9000/tcp"   # Web UI/API
      - "12201:12201/tcp" # GELF TCP
      - "12201:12201/udp" # GELF UDP
      - "13301:13301/tcp" # Forwarder data
      - "13302:13302/tcp" # Forwarder config
    volumes:
      - graylog_data:/usr/share/graylog/data/data

# --------------------------------------------------
# Networks
# --------------------------------------------------
networks:
  graylog:
    driver: bridge

# --------------------------------------------------
# Volumes
# --------------------------------------------------
volumes:
  mongodb_data:
  mongodb_config:
  graylog-datanode:
  graylog_data:

```

### 1.4 Création du fichier .env
Créez un fichier .env dans le répertoire open-core :
```nano .env ```
Contenu du fichier .env :
```
# --------------------------------------------------
# Secret pour le chiffrement des mots de passe Graylog
# ATTENTION : utilisez une valeur unique et sécurisée en production.
# Pour générer : pwgen -N 1 -s 96
# --------------------------------------------------
GRAYLOG_PASSWORD_SECRET=H7829YXtEo2qrpd7T1pio2Gd4FM0rkiJW2WEHQeRgNtkmxURLRbwAAEd8HTRbytNkIqwm0

# --------------------------------------------------
# Mot de passe root Graylog (hash SHA256)
# Pour générer : echo -n "VotreMotDePasse" | sha256sum
# --------------------------------------------------
GRAYLOG_ROOT_PASSWORD_SHA2=975eab3ae73885531ce63cbe71f3f68101f658b533278f233d7e8a1ba99be20c

# --------------------------------------------------
# Images personnalisables (optionnel)
# --------------------------------------------------
DATANODE_IMAGE=graylog/graylog-datanode:7.0
GRAYLOG_IMAGE=graylog/graylog:7.0
```

### 1.5 Démarrage de Graylog
```
# Lancer la stack en arrière-plan
docker compose up -d
# Vérifier les logs
docker compose logs -f graylog
```
![](/image1.png)
### 1.6 Première connexion
1. Ouvrez votre navigateur et accédez à : http://<IPSERVEUR_LINUX>:9000

2. Lors de la **première connexion**, suivez l'assistant de configuration (Data Node setup). 
Le username est **admin** et le mot de passe est disponible dans les logs du docker.
3. Connectez-vous avec :
Utilisateur : admin
Mot de passe : MasterSSIR
🔍 Vérification :
L'interface Graylog doit s'afficher correctement
Configurez le DataNode
![](/image2.png)

Après, nous retouvons la page d'accueil de Graylog
![](/image3.png)
### 1.7 Création de l'Input GELF TCP
Nous créons l'input maintenant pour être prêt à recevoir les logs.
1. Dans Graylog, allez dans System > Inputs
2. Dans la liste déroulante "Select input", choisissez GELF TCP
3. Cliquez sur Launch new input
4. Configurez :

* Title : Windows Logs (ClamWin & Sysmon)
* Bind address : 0.0.0.0
* Port : 12201

Laissez les autres paramètres par défaut

5. Cliquez sur Save
6. Sélectionnez Set-up Input (en jaune) > Select Stream > Next > Start Input
![](/image4.png)
![](/image5.png)
![](/image6.png)
![](/image7.png)


---

✅ L'input devrait afficher "RUNNING" en vert
📝 Note sur TCP vs UDP : Dans ce TP, nous utilisons TCP pour garantir la fiabilité de la transmission des logs (pas
de perte de paquets). En environnement de production, UDP est souvent préféré pour ses meilleures performances,
mais peut entraîner des pertes de logs en cas de congestion réseau


# 🪟 Partie 2 : Installation de ClamWin (Machine Windows)

2.1 Téléchargement et installation

1. Téléchargez ClamWin depuis : <https://clamwin.com/>
2. Installez ClamWin avec les paramètres par défaut
3. Lors de la première utilisation, mettez à jour les définitions de virus (indispensable !)

## 2.2 Test de détection avec EICAR
Le fichier EICAR est un fichier de test standard pour antivirus, totalement inoffensif mais détecté comme malware.
**Téléchargement du fichier EICAR :**

Désactiver Windows Defender puis depuis PowerShell (en tant qu'administrateur) :

![](/image8.png)
![](/image9.png)
![](/image10.png)

**Lancement du scan :**
1. Ouvrez ClamWin
2. Sélectionnez le dossier C:\Users\Public\
3. Cliquez sur Scan
4. ClamWin devrait détecter le fichier EICAR comme Eicar-Signature
![](/image10.png)
![](/image11.png)


✅ Vérification :
Vérifiez les logs de ClamWin dans le fichier configuré (généralement :
C:\ProgramData\.clamwin\log\ClamScanLog.txt )

![](/image12.png)
![](/image13.png)
# 📨 Partie 3 : Envoi des Logs ClamWin vers Graylog
## 3.1 Installation de NXLog
1. Téléchargez NXLog Community Edition depuis : https://nxlog.co/downloads/nxlog-ce#nxlog-community- edition
2. Choisissez la version Windows (MSI)
3. Installez avec les paramètres par défaut

## 3.2 Configuration de NXLog pour ClamWin

Ce que ce fichier fait exactement

* ✔ Surveille le fichier ClamScanLog.txt
* ✔ Lit les nouvelles lignes automatiquement (mode tail)
* ✔ Envoie chaque ligne au format GELF (compatible Graylog)
* ✔ Utilise TCP (fiable, recommandé pour antivirus)
* ✔ Ajoute des champs personnalisés visibles dans Graylog (source, application)

Éditez le fichier de configuration NXLog :

```
############################################################
#     NXLog - Envoi des logs ClamWin vers Graylog (GELF TCP)
############################################################

###########################################
# INPUT : Lecture du fichier ClamWin
###########################################
<Input clamwin>
    Module      im_file
    File        "C:\\ProgramData\\.clamwin\\log\\ClamScanLog.txt"

    SavePos     TRUE
    ReadFromLast TRUE

    # Extraction de la ligne brute
    Exec $Message = $raw_event;
</Input>


###########################################
# EXTENSION GELF
###########################################
<Extension gelf>
    Module  xm_gelf
</Extension>


###########################################
# OUTPUT : Envoi vers Graylog (GELF TCP)
###########################################
<Output graylog_tcp>
    Module      om_tcp
    Host        <IP_SERVEUR_GRAYLOG>
    Port        12201

    OutputType  GELF_TCP

    # Champs personnalisés
    Exec $source = "clamwin";
    Exec $application = "antivirus";
</Output>


###########################################
# ROUTE : Input → Output
###########################################
<Route clamwin_to_graylog>
    Path clamwin => graylog_tcp
</Route>
```
**⚠ IMPORTANT :**
Tu dois remplacer par l’adresse de ton Graylog
Redemarrage des services
![](/image15.png)


## 3.4 Vérification de l'envoi des logs ClamWin
1. Relancez un scan ClamWin sur le fichier EICAR
2. Allez dans Graylog > Search
3. Recherchez : SourceModuleName:"inclamwin"


## Partie 4 : Installation et Configuration de Sysmon
Sysmon (System Monitor) est un outil de Microsoft qui enregistre des événements système détaillés.
## 4.1 Installation de Sysinternals Suite Via winget (recommandé) :```winget install Microsoft.Sysinternals.Suite```

## 4.2 Création du fichier de configuration Sysmon
Créez un fichier sysmon-config.xml :
```
# Créer le fichier de configuration
New-Item -ItemType Directory -Force -Path C:\Tools
New-Item -ItemType File -Path C:\Tools\sysmon-config.xml -Force
notepad C:\Tools\sysmon-config.xml
```

Avec ce contenu

```
<Sysmon schemaversion="4.90">

  <!-- Enable all hash algorithms -->
  <HashAlgorithms>*</HashAlgorithms>

  <!-- Enable certificate revocation checks -->
  <CheckRevocation/>

  <EventFiltering>

    <!-- Event ID 1: Process creation -->
    <RuleGroup name="ProcessCreate" groupRelation="or">
      <ProcessCreate onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 3: Network connection -->
    <RuleGroup name="NetworkConnect" groupRelation="or">
      <NetworkConnect onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 5: Process termination -->
    <RuleGroup name="ProcessTerminate" groupRelation="or">
      <ProcessTerminate onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 6: Driver load -->
    <RuleGroup name="DriverLoad" groupRelation="or">
      <DriverLoad onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 7: Image load -->
    <RuleGroup name="ImageLoad" groupRelation="or">
      <ImageLoad onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 8: CreateRemoteThread -->
    <RuleGroup name="CreateRemoteThread" groupRelation="or">
      <CreateRemoteThread onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 9: Raw access read -->
    <RuleGroup name="RawAccessRead" groupRelation="or">
      <RawAccessRead onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 10: ProcessAccess -->
    <RuleGroup name="ProcessAccess" groupRelation="or">
      <ProcessAccess onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 11: FileCreate -->
    <RuleGroup name="FileCreate" groupRelation="or">
      <FileCreate onmatch="exclude" />
    </RuleGroup>

    <!-- Event IDs 12-14: Registry events -->
    <RuleGroup name="RegistryEvent" groupRelation="or">
      <RegistryEvent onmatch="exclude" />
    </RuleGroup>

    <!-- Event IDs 17-18: Pipe events -->
    <RuleGroup name="PipeEvent" groupRelation="or">
      <PipeEvent onmatch="exclude" />
    </RuleGroup>

    <!-- Event IDs 19-21: WMI events -->
    <RuleGroup name="WmiEvent" groupRelation="or">
      <WmiEvent onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 22: DNS Query -->
    <RuleGroup name="DnsQuery" groupRelation="or">
      <DnsQuery onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 24: Clipboard changes -->
    <RuleGroup name="ClipboardChange" groupRelation="or">
      <ClipboardChange onmatch="exclude" />
    </RuleGroup>

    <!-- Event ID 25: Process tampering -->
    <RuleGroup name="ProcessTampering" groupRelation="or">
      <ProcessTampering onmatch="exclude" />
    </RuleGroup>

  </EventFiltering>
</Sysmon>
```

La configuration inclut tous les EventID principaux : 1, 3, 5, 6, 7, 8, 9, 10, 11, 12-14, 17-18, 19-21, 22, 24, 25
**Note :** Cette configuration est volontairement très permissive (irréaliste en production). L'objectif est pédagogique : comprendre la méthodologie, pas optimiser Sysmon.


1. Télécharge Sysmon (officiel Microsoft)
<https://download.sysinternals.com/files/Sysmon.zip>
2. Extraire correctement Sysmon. Après extraction, tu dois avoir :
Sysmon.exe
Sysmon64.exe
Eula.txt
````
Copy-Item "C:\Users\<Your-NAME>\Downloads\Sysmon.exe" C:\Tools
Copy-Item "C:\Users\<Your-NAME>\Downloads\Sysmon64.exe" C:\Tools
```