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

etu@serveur:~/ldif$ cat > ou.ldif << EOF
> dn: ou=people,dc=Dagobah,dc=starwars
> objectClass: organizationalUnit
> ou: people
>
> dn: ou=groups,dc=Dagobah,dc=starwars
> objectClass: organizationalUnit
> ou: groups
> EOF

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



etu@serveur:~/ldif$ sudo ldapadd -cxWD cn=admin,dc=Dagobah,dc=starwars -f users.ldif
Enter LDAP Password:
adding new entry "uid=padme,ou=people,dc=Dagobah,dc=starwars"

adding new entry "uid=anakin,ou=people,dc=Dagobah,dc=starwars"

adding new entry "uid=leia,ou=people,dc=Dagobah,dc=starwars"

adding new entry "uid=luke,ou=people,dc=Dagobah,dc=starwars"

etu@serveur:~/ldif$
