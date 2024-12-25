# Context 
* This tutorial explores the LDAP directory service. We give a brief introduction to the components of a directory, and then study the configuration of a directory service based on OpenLDAP software. We then look at how to configure access to directory entries from a client workstation. The information delivered by the directory is the user account properties stored in the posixAccount object class.



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
