# Context 
* This tutorial explores the LDAP directory service. We give a brief introduction to the components of a directory, and then study the configuration of a directory service based on OpenLDAP software. We then look at how to configure access to directory entries from a client workstation. The information delivered by the directory is the user account properties stored in the posixAccount object class.

# I use 2 machines : One for the LDAP server and the other for the client

# LDAP Server Configuration

```
etu@serveur:~$ apt search ^OpenLDAP
ldap-utils/testing 2.5.18+dfsg-3 amd64
  OpenLDAP utilities

libldap-2.5-0/testing,now 2.5.18+dfsg-3 amd64  [installé, automatique]
  Bibliothèques OpenLDAP

libldap-common/testing 2.5.18+dfsg-3 all
  fichiers communs OpenLDAP pour les bibliothèques

libldap-dev/testing 2.5.18+dfsg-3 amd64
  bibliothèques de développement pour OpenLDAP
Package configuration





    ┌────────────────────────┤ Configuring slapd ├─────────────────────────┐
    │ Veuillez entrer à nouveau le mot de passe de l'administrateur de     │
    │ l'annuaire LDAP afin de vérifier qu'il a été saisi correctement.     │
    │                                                                      │
    │ Mot de passe de l'administrateur :                                   │
    │                                                                      │
    │ *****_______________________________________________________________ │
    │                                                                      │
    │                                <Ok>                                  │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘






Sélection du paquet libargon2-1:amd64 précédemment désélectionné.
(Lecture de la base de données... 27620 fichiers et répertoires déjà installés.)
Préparation du dépaquetage de .../libargon2-1_0~20190702+dfsg-4+b1_amd64.deb ...
Dépaquetage de libargon2-1:amd64 (0~20190702+dfsg-4+b1) ...
Sélection du paquet libltdl7:amd64 précédemment désélectionné.
Préparation du dépaquetage de .../libltdl7_2.4.7-7+b1_amd64.deb ...
Dépaquetage de libltdl7:amd64 (2.4.7-7+b1) ...
Sélection du paquet libodbc2:amd64 précédemment désélectionné.
Préparation du dépaquetage de .../libodbc2_2.3.12-1+b2_amd64.deb ...
Dépaquetage de libodbc2:amd64 (2.3.12-1+b2) ...
Sélection du paquet slapd précédemment désélectionné.
Préparation du dépaquetage de .../slapd_2.5.18+dfsg-3_amd64.deb ...
Dépaquetage de slapd (2.5.18+dfsg-3) ...
Sélection du paquet ldap-utils précédemment désélectionné.
Préparation du dépaquetage de .../ldap-utils_2.5.18+dfsg-3_amd64.deb ...
Dépaquetage de ldap-utils (2.5.18+dfsg-3) ...
Paramétrage de libargon2-1:amd64 (0~20190702+dfsg-4+b1) ...
Paramétrage de ldap-utils (2.5.18+dfsg-3) ...
Paramétrage de libltdl7:amd64 (2.4.7-7+b1) ...
Paramétrage de libodbc2:amd64 (2.3.12-1+b2) ...
Paramétrage de slapd (2.5.18+dfsg-3) ...
  Creating new user openldap... done.
  Creating initial configuration... done.
  Creating LDAP directory... done.
Traitement des actions différées (« triggers ») pour man-db (2.13.0-1) ...
Traitement des actions différées (« triggers ») pour libc-bin (2.40-2) ...
Scanning processes...
Scanning linux images...

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
```
* List ldap process
```
etu@serveur:~$ ps aux |grep l[d]ap
openldap     772  0.0  0.8 1158600 7812 ?        Ssl  10:16   0:00 /usr/sbin/slapd -h ldap:/// ldapi:/// -g openldap -u openldap -F /etc/ldap/slapd.d
etu@serveur:~$ sudo lsof -i | grep l[d]ap
slapd     772        openldap    8u  IPv4   1788      0t0  TCP *:ldap (LISTEN)
slapd     772        openldap    9u  IPv6   1789      0t0  TCP *:ldap (LISTEN)
etu@serveur:~$ ss -tau | grep l[d]ap
tcp   LISTEN 0      2048         0.0.0.0:ldap        0.0.0.0:*
tcp   LISTEN 0      2048            [::]:ldap           [::]:*
etu@serveur:~$ grep ldap /etc/services
ldap            389/tcp                 # Lightweight Directory Access Protocol
ldap            389/udp
ldaps           636/tcp                         # LDAP over SSL
ldaps           636/udp
```
* The configuration management mode for services
```
etu@serveur:~$ sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" \

> olcDatabase={1}mdb
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
# extended LDIF
#
# LDAPv3
# base <cn=config> with scope subtree
# filter: olcDatabase={1}mdb
# requesting: ALL
#

# {1}mdb, config
dn: olcDatabase={1}mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: {1}mdb
olcDbDirectory: /var/lib/ldap
olcSuffix: dc=nodomain
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to attrs=shadowLastChange by self write by * read
olcAccess: {2}to * by * read
olcLastMod: TRUE
olcRootDN: cn=admin,dc=nodomain
olcRootPW: {SSHA}lJTvXYsn8s7caHJJJy+O9diHZrgiEKOp
olcDbCheckpoint: 512 30
olcDbIndex: objectClass eq
olcDbIndex: cn,uid eq
olcDbIndex: uidNumber,gidNumber eq
olcDbIndex: member,memberUid eq
olcDbMaxSize: 1073741824

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
etu@serveur:~$ sudo ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" \
> olcSuffix | grep ^olcSuffix
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
olcSuffix: dc=nodomain
etu@serveur:~$ sudo ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" \
> olcSchemaConfig | grep ^cn
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
cn: config
cn: module{0}
cn: schema
cn: {0}core
cn: {1}cosine
cn: {2}nis
cn: {3}inetorgperson
etu@serveur:~$ sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" \
> olcDbDirectory | grep ^olcDbDirectory
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
olcDbDirectory: /var/lib/ldap
etu@serveur:~$ ls -lAh /var/lib/ldap/
total 40K
-rw------- 1 openldap openldap  36K 12 sept. 10:16 data.mdb
-rw------- 1 openldap openldap 8,0K 12 sept. 10:16 lock.mdb
etu@serveur:~$
```

# Resetting the LDAP directory database

* Let's check for the status of the slapd
```
etu@serveur:~$ systemctl status slapd
● slapd.service - LSB: OpenLDAP standalone server (Lightweight Directory Access>
     Loaded: loaded (/etc/init.d/slapd; generated)
    Drop-In: /usr/lib/systemd/system/slapd.service.d
             └─slapd-remain-after-exit.conf
     Active: active (running) since Thu 2024-09-12 10:16:49 CEST; 7min ago
 Invocation: 61e45d22a5024362b3da2f5cc8b008ea
       Docs: man:systemd-sysv-generator(8)
    Process: 766 ExecStart=/etc/init.d/slapd start (code=exited, status=0/SUCCE>
      Tasks: 4 (limit: 1087)
     Memory: 5.5M (peak: 6.5M)
        CPU: 67ms
     CGroup: /system.slice/slapd.service
             └─772 /usr/sbin/slapd -h "ldap:/// ldapi:///" -g openldap -u openl>

sept. 12 10:16:49 serveur systemd[1]: Starting slapd.service - LSB: OpenLDAP st>
sept. 12 10:16:49 serveur slapd[771]: @(#) $OpenLDAP: slapd 2.5.18+dfsg-3 (Aug >
                                              Debian OpenLDAP Maintainers <pkg->
sept. 12 10:16:49 serveur slapd[772]: slapd starting
sept. 12 10:16:49 serveur slapd[766]: Starting OpenLDAP: slapd.
sept. 12 10:16:49 serveur systemd[1]: Started slapd.service - LSB: OpenLDAP sta>
```
* We cans see that the slapd service is running
* Now we have to stop the slapd service to reset the ldap directory database bye following the steps
* We will create a domain name Dogobah.starwars
```
etu@serveur:~$ sudo systemctl stop slapd
etu@serveur:~$ systemctl status slapd
○ slapd.service - LSB: OpenLDAP standalone server (Lightweight Directory Access>
     Loaded: loaded (/etc/init.d/slapd; generated)
Package configuration






    ┌────────────────────────┤ Configuring slapd ├─────────────────────────┐
    │                                                                      │
    │                                                                      │
    │                                                                      │
    │ Faut-il supprimer la base de données lors de la purge du paquet ?    │
    │                                                                      │
    │                   <Oui>                      <Non>                   │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘







  Creating initial configuration... done.
  Creating LDAP directory... done.
etu@serveur:~$ sudo ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" \
> olcSuffix | grep ^olcSuffix
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
olcSuffix: dc=Dagobah,dc=starwars
```

# Composition of a new LDAP directory
* Search on Dagobah.starwars DC
```
etu@serveur:~$sudo ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "dc=Dagobah,dc=starwars" \ 
> -D cn=admin,dc=Dagobah,dc=starwars -W
Enter LDAP Password:
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
dn: dc=Dagobah,dc=starwars
objectClass: top
objectClass: dcObject
objectClass: organization
o: Dagobah.starwars
dc: Dagobah
```
* Show the current journalisation level of LDAP

```
etu@serveur:~$ sudo ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" \
> olcLogLevel | grep ^olcLogLevel
SASL/EXTERNAL authentication started
olcLogLevel: none
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
```
* Let's now create a file to change the level of the log. We put the olcLogLevel to stats
```  
etu@serveur:~$ mkdir -p $HOME/ldif && cd $HOME/ldif
etu@serveur:~/ldif$ cat > setolcLogLevel2stats.ldif << EOF
> # Set olcLogLevel to "stats"
> dn: cn=config
> changetype: modify
> replace: olcLogLevel
> olcLogLevel: stats
> EOF
```
* Apply the modification with ldapmodify command and show again the level of log
```                                         
etu@serveur:~/ldif$ sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f setolcLogLevel2stats.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "cn=config"

sudo ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" \
> olcLogLevel | grep ^olcLogLevel
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
olcLogLevel: stats
```
## Create an LDIF file named setolcLogLevel2none.ldif to change the LDAP logging level (olcLogLevel) to none.
	- dn: cn=config : Specifies that the modification applies to the global configuration.
	- changetype: modify: Indicates that we are modifying an existing entry.
	- replace: olcLogLevel : Replaces the current value of olcLogLevel with none.
```
etu@serveur:~/ldif$ cat > setolcLogLevel2none.ldif << EOF
> # Set olcLogLevel to "none"
> dn: cn=config
> changetype: modify
> replace: olcLogLevel
> olcLogLevel: none
> EOF

etu@serveur:~/ldif$ cat setolcLogLevel2none.ldif
# Set olcLogLevel to "none"
dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: none
```
* Objective: Create an LDIF (or .ldif) file to define two organizational units (people and groups) under the Dagobah.starwars domain.
	- dn: ou=people,dc=Dagobah,dc=starwars : Defines an OU people.
	- dn: ou=groups,dc=Dagobah,dc=starwars : Defines a groups OU.
	- objectClass: organizationalUnit: Indicates that these entries are organizational units.
```
etu@serveur:~/ldif$ cat > ou.ldif << EOF
> dn: ou=people,dc=Dagobah,dc=starwars
> objectClass: organizationalUnit
> ou: people
>
> dn: ou=groups,dc=Dagobah,dc=starwars
> objectClass: organizationalUnit
> ou: groups
> EOF
```

* Add and verify the organizational units defined in or.ldif to the LDAP server.
	-c: Continue on error.
	-x: Use simple authentication instead of SASL.
	-W: Requests LDAP administrator password.
 ```
etu@serveur:~/ldif$ sudo ldapadd -cxWD cn=admin,dc=Dagobah,dc=starwars -f ou.ldif=admin,dc=Dagobah,dc=starwars -f ou.ldif
Enter LDAP Password:
adding new entry "ou=people,dc=Dagobah,dc=starwars"

adding new entry "ou=groups,dc=Dagobah,dc=starwars"
etu@serveur:~/ldif$ sudo ldapsearch -LLL -x -H ldap:/// -b "dc=Dagobah,dc=starwars" \H ldap:/// -b "dc=Dagobah,dc=starwars" \
> -D cn=admin,dc=Dagobah,dc=starwars -W
Enter LDAP Password:
dn: dc=Dagobah,dc=starwars
objectClass: top
objectClass: dcObject
objectClass: organization
o: Dagobah.starwars
dc: Dagobah

dn: ou=people,dc=Dagobah,dc=starwars
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=Dagobah,dc=starwars
objectClass: organizationalUnit
ou: groups

```

* Generate a pwd
```
etu@serveur:~/ldif$ man -k passwd | grep -i ldap
ldappasswd (1)       - change the password of an LDAP entry
slappasswd (8)       - OpenLDAP password utility
etu@serveur:~/ldif$ sudo slappasswd
New password:
Re-enter new password:
{SSHA}MCKOSU7CGakkcCout6fL5x7yMO1WWYHZ

etu@serveur:~/ldif$ openssl rand -base64 16 | tr -d '=' > user.passwd
etu@serveur:~/ldif$ cat user.passwd
Lrx1t7GokAdOj0m2q70pgQ
etu@serveur:~/ldif$ sudo slappasswd -v -h "{SSHA}" -s $(cat user.passwd)
{SSHA}youOHH/XnoNUsDmT+lG1fAYIKCLU5lfw
```

* Add a users padme, anakin, leai and luke to LDAP
```
etu@serveur:~/ldif$ sudo ldapadd -cxWD cn=admin,dc=Dagobah,dc=starwars -f users.ldif
Enter LDAP Password:
adding new entry "uid=padme,ou=people,dc=Dagobah,dc=starwars"

adding new entry "uid=anakin,ou=people,dc=Dagobah,dc=starwars"

adding new entry "uid=leia,ou=people,dc=Dagobah,dc=starwars"

adding new entry "uid=luke,ou=people,dc=Dagobah,dc=starwars"

etu@serveur:~/ldif$
```
* Check if they have been added
```
etu@serveur:~/ldif$ sudo ldapsearch -LLL -x -H ldap:/// -b "dc=Dagobah,dc=starwars" \
> -D cn=admin,dc=Dagobah,dc=starwars -W
Enter LDAP Password:
dn: dc=Dagobah,dc=starwars
objectClass: top
objectClass: dcObject
objectClass: organization
o: Dagobah.starwars
dc: Dagobah

dn: ou=people,dc=Dagobah,dc=starwars
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=Dagobah,dc=starwars
objectClass: organizationalUnit
ou: groups

dn: uid=padme,ou=people,dc=Dagobah,dc=starwars
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: posixAccount
cn: Padme
sn:: UGFkbcOpIEFtaWRhbGEgU2t5d2Fsa2Vy
uid: padme
uidNumber: 10000
gidNumber: 10000
loginShell: /bin/bash
homeDirectory: /ahome/padme
userPassword:: e1NTSEF9eW91T0hIL1hub05Vc0RtVCtsRzFmQVlJS0NMVTVsZnc=
gecos: Padme Amidala Skywalker

dn: uid=anakin,ou=people,dc=Dagobah,dc=starwars
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: posixAccount
cn: Anakin
sn: Anakin Skywalker
uid: anakin
uidNumber: 10001
gidNumber: 10001
loginShell: /bin/bash
homeDirectory: /ahome/anakin
userPassword:: e1NTSEF9eW91T0hIL1hub05Vc0RtVCtsRzFmQVlJS0NMVTVsZnc=
gecos: Anakin Skywalker

dn: uid=leia,ou=people,dc=Dagobah,dc=starwars
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: posixAccount
cn: Leia
sn: Leia Organa
uid: leia
uidNumber: 10002
gidNumber: 10002
loginShell: /bin/bash
homeDirectory: /ahome/leia
userPassword:: e1NTSEF9eW91T0hIL1hub05Vc0RtVCtsRzFmQVlJS0NMVTVsZnc=
gecos: Leia Organa Skywalker

dn: uid=luke,ou=people,dc=Dagobah,dc=starwars
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: posixAccount
cn: Luke
sn: Luke Skywalker
uid: luke
uidNumber: 10003
gidNumber: 10003
loginShell: /bin/bash
homeDirectory: /ahome/luke
userPassword:: e1NTSEF9eW91T0hIL1hub05Vc0RtVCtsRzFmQVlJS0NMVTVsZnc=
gecos: Luke Skywalker
```

# Setting Client

* Now that we have set up the server, we can now install a client to connect to the LDAP server
* The manipulations presented here are designed to make access to user account attributes transparent. The Name Service Switch mechanism switches access to these attributes between local files and the various network services available. Here, the LDAP directory is used as a reference repository for storing user account attributes.
* First, we have to install the ldap-utils and libnss-ldapd on the client machine
```
etu@client:~$ sudo apt -y install ldap-utils && sudo apt install libnss-ldapd
[sudo] Mot de passe de etu :
Installing:
  ldap-utils

Paquets suggérés :
  libsasl2-modules             | libsasl2-modules-gssapi-heimdal
  libsasl2-modules-gssapi-mit

Summary:
  Upgrading: 0, Installing: 1, Removing: 0, Not Upgrading: 0
  Download size: 148 kB
  Space needed: 796 kB / 70,6 GB available

Réception de :1 file:/etc/apt/mirrors/debian.list Mirrorlist [30 B]
Réception de :2 https://deb.debian.org/debian trixie/main amd64 ldap-utils amd64 2.5.18+dfsg-3 [148 kB]
148 ko réceptionnés en 5s (27,0 ko/s)
Sélection du paquet ldap-utils précédemment désélectionné.
(Lecture de la base de données... 27620 fichiers et répertoires déjà installés.)
Préparation du dépaquetage de .../ldap-utils_2.5.18+dfsg-3_amd64.deb ...
Dépaquetage de ldap-utils (2.5.18+dfsg-3) ...
Paramétrage de ldap-utils (2.5.18+dfsg-3) ...
Traitement des actions différées (« triggers ») pour man-db (2.13.0-1) ...
Scanning processes...
Scanning linux images...

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
```
* On the client machine, we try to connect to the ldap server machine by its ip 10.13.0.2 and we are looking for the padme user which is specify by the uid parameters
```
etu@client:~$ sudo ldapsearch -LLL -H ldap://[10.13.0.2] \
> -b dc=Dagobah,dc=starwars -D cn=admin,dc=Dagobah,dc=starwars -W uid=padme
Enter LDAP Password:
dn: uid=padme,ou=people,dc=Dagobah,dc=starwars
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: posixAccount
cn: Padme
sn:: UGFkbcOpIEFtaWRhbGEgU2t5d2Fsa2Vy
uid: padme
uidNumber: 10000
gidNumber: 10000
loginShell: /bin/bash
homeDirectory: /ahome/padme
userPassword:: e1NTSEF9eW91T0hIL1hub05Vc0RtVCtsRzFmQVlJS0NMVTVsZnc=
gecos: Padme Amidala Skywalker
```
* We can even try to change the user pwd by usin g the commands below
```
etu@client:~$ sudo ldappasswd -x -H ldap://[10.13.0.2] \  
> -D cn=admin,dc=Dagobah,dc=starwars -W -S uid=padme,ou=people,dc=Dagobah,dc=starwars
[sudo] Mot de passe de etu :
New password:
Re-enter new password:
Enter LDAP Password:
```
> For the purposes of practical work or setting up LDAP authentication, it is useful to restart the cache services each time the directory access conditions are modified.
```
etu@client:~$ sudo systemctl restart nslcd
etu@client:~$ sudo systemctl restart nscd
```
* Confirms that users, groups and passwords can be searched via LDAP and local files.
```
etu@client:~$ grep ldap /etc/nsswitch.conf
passwd:         files ldap
group:          files ldap
shadow:         files ldap
```
* List user via getent (we see the presence of padme, luke, anakin and liea, user we have created on the ldap server)
```
etu@client:~$ getent passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin
systemd-timesync:x:997:997:systemd Time Synchronization:/:/usr/sbin/nologin
uuidd:x:100:101::/run/uuidd:/usr/sbin/nologin
messagebus:x:101:102::/nonexistent:/usr/sbin/nologin
tcpdump:x:102:103::/nonexistent:/usr/sbin/nologin
systemd-resolve:x:992:992:systemd Resolver:/:/usr/sbin/nologin
sshd:x:103:65534::/run/sshd:/usr/sbin/nologin
polkitd:x:991:991:User for polkitd:/:/usr/sbin/nologin
etu:x:1000:1000:,,,:/home/etu:/bin/bash
nslcd:x:104:105:nslcd name service LDAP connection daemon,,,:/run/nslcd:/usr/sbin/nologin
padme:x:10000:10000:Padme Amidala Skywalker:/ahome/padme:/bin/bash
anakin:x:10001:10001:Anakin Skywalker:/ahome/anakin:/bin/bash
leia:x:10002:10002:Leia Organa Skywalker:/ahome/leia:/bin/bash
luke:x:10003:10003:Luke Skywalker:/ahome/luke:/bin/bash
```
* Let's connect to the user padme by using su command...
```
etu@client:~$ su - padme
Mot de passe :
su: warning: cannot change directory to /ahome/padme: Aucun fichier ou dossier de ce nom
padme@client:/home/etu$
```
* ... Or by using the ssh commande (since padme is on the ldap server machine)
```
etu@client:~$ ssh padme@localhost
The authenticity of host 'localhost (::1)' can't be established.
ED25519 key fingerprint is SHA256:jxdxFO/jYTC/7x8vMF3f9cmC5abEarQMDB2dc2MHJ/Q.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
padme@localhost's password:
Linux client 6.10.6-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.10.6-1 (2024-08-19) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Could not chdir to home directory /ahome/padme: No such file or directory
padme@client:/$ exit
déconnexion
Connection to localhost closed.
```
