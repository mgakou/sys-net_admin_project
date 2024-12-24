# Config machine 
## Server 
```
etu@localhost:~$ cat /etc/netplan/enp0s1.yaml 
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: false
      dhcp6: false
      accept-ra: true
      addresses:
        - 192.168.237.124/27
        - 2001:678:3fc:ed::56/64
      routes:
        - to: default
          via: 192.168.237.129/27 
        - to: "::/0"
          via: "fe80:ed::1"
          on-link: true
      nameservers:
        addresses:
          - 172.16.0.2
          - 2001:678:3fc:3::2
etu@localhost:~$ ping 192.168.237.123
PING 192.168.237.123 (192.168.237.123) 56(84) bytes of data.
64 bytes from 192.168.237.123: icmp_seq=1 ttl=64 time=1.22 ms
64 bytes from 192.168.237.123: icmp_seq=2 ttl=64 time=0.715 ms
64 bytes from 192.168.237.123: icmp_seq=3 ttl=64 time=0.615 ms
64 bytes from 192.168.237.123: icmp_seq=4 ttl=64 time=0.618 ms

--- 192.168.237.123 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3011ms
rtt min/avg/max/mdev = 0.615/0.792/1.222/0.251 ms
etu@localhost:~$ ip neighbor
192.168.237.123 dev enp0s1 lladdr b8:ad:ca:fe:00:37 STALE 
172.16.0.2 dev enp0s1 FAILED 
fe80:ed::1 dev enp0s1 lladdr e8:eb:34:cc:f4:ca router STALE 
```
## Client
```
cat /etc/netplan/cat /etc/netplan/enp0s1.yaml 
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: false
      dhcp6: false
      accept-ra: true
      addresses:
        - 192.168.237.123/27
        - 2001:678:3fc:ed::55/64
      routes:
        - to: default
          via: 192.168.237.129/27 
        - to: "::/0"
          via: "fe80:ed::1"
          on-link: true
      nameservers:
        addresses:
          - 172.16.0.2
          - 2001:678:3fc:3::2
etu@localhost:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether b8:ad:ca:fe:00:37 brd ff:ff:ff:ff:ff:ff
    inet 192.168.237.123/27 brd 192.168.237.127 scope global enp0s1
       valid_lft forever preferred_lft forever
    inet6 2001:678:3fc:ed:baad:caff:fefe:37/64 scope global dynamic mngtmpaddr noprefixroute 
       valid_lft 2591915sec preferred_lft 604715sec
    inet6 2001:678:3fc:ed::55/64 scope global 
       valid_lft forever preferred_lft forever
    inet6 fe80::baad:caff:fefe:37/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
etu@localhost:~$ ping 192.168.237.124
PING 192.168.237.124 (192.168.237.124) 56(84) bytes of data.
64 bytes from 192.168.237.124: icmp_seq=1 ttl=64 time=18.0 ms
64 bytes from 192.168.237.124: icmp_seq=2 ttl=64 time=0.628 ms

--- 192.168.237.124 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.628/9.333/18.039/8.705 ms
etu@localhost:~$ ip 4 neighbor
Object "4" is unknown, try "ip help".
etu@localhost:~$ ip  neighbor
172.16.0.2 dev enp0s1 FAILED 
192.168.237.124 dev enp0s1 lladdr b8:ad:ca:fe:00:38 REACHABLE 
fe80:ed::1 dev enp0s1 lladdr e8:eb:34:cc:f4:ca router STALE 
etu@localhost:~$ 
```

# Installation et config RPC

## Sur client

```
etu@localhost:~$ rpcinfo -s
   program version(s) netid(s)                         service     owner
    100000  2,3,4     local,udp,tcp,udp6,tcp6          portmapper  superuser
etu@localhost:~$ sudo lsof -i | grep rpc[b]ind
rpcbind   1207            _rpc    4u  IPv4   6985      0t0  TCP *:sunrpc (LISTEN)
rpcbind   1207            _rpc    5u  IPv4   9635      0t0  UDP *:sunrpc 
rpcbind   1207            _rpc    6u  IPv6   5820      0t0  TCP *:sunrpc (LISTEN)
rpcbind   1207            _rpc    7u  IPv6   6987      0t0  UDP *:sunrpc 
etu@localhost:~$ 

etu@localhost:~$ sudo lsof -i | grep rpc[b]ind
rpcbind   1207            _rpc    4u  IPv4   6985      0t0  TCP *:sunrpc (LISTEN)
rpcbind   1207            _rpc    5u  IPv4   9635      0t0  UDP *:sunrpc 
rpcbind   1207            _rpc    6u  IPv6   5820      0t0  TCP *:sunrpc (LISTEN)
rpcbind   1207            _rpc    7u  IPv6   6987      0t0  UDP *:sunrpc 

etu@localhost:~$ rpcinfo -s 192.168.237.124
   program version(s) netid(s)                         service     owner
    100000  2,3,4     local,udp,tcp,udp6,tcp6          portmapper  superuser

etu@localhost:~$ rpcinfo -s 192.168.237.123
   program version(s) netid(s)                         service     owner
    100000  2,3,4     local,udp,tcp,udp6,tcp6          portmapper  superuser
```
## Sur Serveur 
```
etu@localhost:~$ rpcinfo -s
   program version(s) netid(s)                         service     owner
    100000  2,3,4     local,udp,tcp,udp6,tcp6          portmapper  superuser
etu@localhost:~$ 
etu@localhost:~$ sudo lsof -i | grep rpc[b]ind
rpcbind   1136            _rpc    4u  IPv4   8508      0t0  TCP *:sunrpc (LISTEN)
rpcbind   1136            _rpc    5u  IPv4   9606      0t0  UDP *:sunrpc 
rpcbind   1136            _rpc    6u  IPv6   8510      0t0  TCP *:sunrpc (LISTEN)
rpcbind   1136            _rpc    7u  IPv6   9608      0t0  UDP *:sunrpc 

etu@localhost:~$ rpcinfo -s 192.168.237.124
   program version(s) netid(s)                         service     owner
    100000  2,3,4     local,udp,tcp,udp6,tcp6          portmapper  superuser
```
## Installation NFS-kernel et gestion sur le serveur 

```
etu@localhost:~$ sudo apt install nfs-kernel-server
Installing:                                     
  nfs-kernel-server

Installing dependencies:
  keyutils  libnfsidmap1  nfs-common

Paquets suggérés :
  open-iscsi  watchdog

Summary:
  Upgrading: 0, Installing: 4, Removing: 0, Not Upgrading: 20
  Download size: 562 kB
  Space needed: 2 409 kB / 70,7 GB available

Continue? [O/n] O
Réception de :1 file:/etc/apt/mirrors/debian.list Mirrorlist [30 B]
Réception de :2 https://deb.debian.org/debian trixie/main amd64 libnfsidmap1 amd64 1:2.6.4-6 [56,8 kB]
Réception de :3 https://deb.debian.org/debian trixie/main amd64 keyutils amd64 1.6.3-3 [54,8 kB]
Réception de :4 https://deb.debian.org/debian trixie/main amd64 nfs-common amd64 1:2.6.4-6 [265 kB]
Réception de :5 https://deb.debian.org/debian trixie/main amd64 nfs-kernel-server amd64 1:2.6.4-6 [185 kB]
562 ko réceptionnés en 1s (1 108 ko/s) 
Sélection du paquet libnfsidmap1:amd64 précédemment désélectionné.
(Lecture de la base de données... 27640 fichiers et répertoires déjà installés.)
Préparation du dépaquetage de .../libnfsidmap1_1%3a2.6.4-6_amd64.deb ...
Dépaquetage de libnfsidmap1:amd64 (1:2.6.4-6) ...
Sélection du paquet keyutils précédemment désélectionné.
Préparation du dépaquetage de .../keyutils_1.6.3-3_amd64.deb ...
Dépaquetage de keyutils (1.6.3-3) ...
Sélection du paquet nfs-common précédemment désélectionné.
Préparation du dépaquetage de .../nfs-common_1%3a2.6.4-6_amd64.deb ...
Dépaquetage de nfs-common (1:2.6.4-6) ...
Sélection du paquet nfs-kernel-server précédemment désélectionné.
Préparation du dépaquetage de .../nfs-kernel-server_1%3a2.6.4-6_amd64.deb ...
Dépaquetage de nfs-kernel-server (1:2.6.4-6) ...
Paramétrage de libnfsidmap1:amd64 (1:2.6.4-6) ...
Paramétrage de keyutils (1.6.3-3) ...
Paramétrage de nfs-common (1:2.6.4-6) ...

Creating config file /etc/idmapd.conf with new version

Creating config file /etc/nfs.conf with new version
info: Selecting UID from range 100 to 999 ...

info: Adding system user `statd' (UID 105) ...
info: Adding new user `statd' (UID 105) with group `nogroup' ...
info: Not creating home directory `/var/lib/nfs'.
Created symlink '/etc/systemd/system/multi-user.target.wants/nfs-client.target' → '/usr/lib/systemd/system/nfs-client.target'.
Created symlink '/etc/systemd/system/remote-fs.target.wants/nfs-client.target' → '/usr/lib/systemd/system/nfs-client.target'.
auth-rpcgss-module.service is a disabled or a static unit, not starting it.
nfs-idmapd.service is a disabled or a static unit, not starting it.
nfs-utils.service is a disabled or a static unit, not starting it.
proc-fs-nfsd.mount is a disabled or a static unit, not starting it.
rpc-gssd.service is a disabled or a static unit, not starting it.
rpc-statd-notify.service is a disabled or a static unit, not starting it.
rpc-statd.service is a disabled or a static unit, not starting it.
rpc-svcgssd.service is a disabled or a static unit, not starting it.
[ 6973.381274] RPC: Registered named UNIX socket transport module.
[ 6973.381642] RPC: Registered udp transport module.
[ 6973.381938] RPC: Registered tcp transport module.
[ 6973.382215] RPC: Registered tcp-with-tls transport module.
[ 6973.382514] RPC: Registered tcp NFSv4.1 backchannel transport module.
Paramétrage de nfs-kernel-server (1:2.6.4-6) ...
Created symlink '/etc/systemd/system/nfs-mountd.service.requires/fsidd.service' → '/usr/lib/systemd/system/fsidd.service'.
Created symlink '/etc/systemd/system/nfs-server.service.requires/fsidd.service' → '/usr/lib/systemd/system/fsidd.service'.
Created symlink '/etc/systemd/system/nfs-client.target.wants/nfs-blkmap.service' → '/usr/lib/systemd/system/nfs-blkmap.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/nfs-server.service' → '/usr/lib/systemd/system/nfs-server.service'.
nfs-mountd.service is a disabled or a static unit, not starting it.
nfsdcld.service is a disabled or a static unit, not starting it.
[ 6974.734348] NFSD: Using nfsdcld client tracking operations.
[ 6974.735739] NFSD: no clients to reclaim, skipping NFSv4 grace period (net f0000000)

Creating config file /etc/exports with new version

Creating config file /etc/default/nfs-kernel-server with new version
Traitement des actions différées (« triggers ») pour man-db (2.12.1-3) ...
Traitement des actions différées (« triggers ») pour libc-bin (2.39-7) ...
Scanning processes...                                                                          
Scanning linux images...                                                                       

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
etu@localhost:~$ systemctl status nfs-kernel-server
● nfs-server.service - NFS server and services
     Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; preset: enabled)
     Active: active (exited) since Thu 2024-09-05 18:19:16 CEST; 10s ago
 Invocation: abae2c4b21ec431c9064035c38aa7621
   Main PID: 1733 (code=exited, status=0/SUCCESS)
   Mem peak: 1.6M
        CPU: 27ms

sept. 05 18:19:15 localhost systemd[1]: Starting nfs-server.service - NFS server and services.>
sept. 05 18:19:15 localhost exportfs[1732]: exportfs: can't open /etc/exports for reading
sept. 05 18:19:16 localhost systemd[1]: Finished nfs-server.service - NFS server and services.
lines 1-11/11 (END)

etu@localhost:~$ systemctl status nfs-kernel-server
Unit nfs-kernel-server.service could not be found.
etu@localhost:~$ apt install nfs-kernel-server
Error: Impossible d'ouvrir le fichier verrou /var/lib/dpkg/lock-frontend - open (13: Permission non accordée)
Error: Impossible d'obtenir le verrou de dpkg (/var/lib/dpkg/lock-frontend). Avez-vous les droits du superutilisateur ?
etu@localhost:~$ sudo apt install nfs-kernel-server
Installing:                                     
  nfs-kernel-server

Installing dependencies:
  keyutils  libnfsidmap1  nfs-common

Paquets suggérés :
  open-iscsi  watchdog

Summary:
  Upgrading: 0, Installing: 4, Removing: 0, Not Upgrading: 20
  Download size: 562 kB
  Space needed: 2 409 kB / 70,7 GB available

Continue? [O/n] O
Réception de :1 file:/etc/apt/mirrors/debian.list Mirrorlist [30 B]
Réception de :2 https://deb.debian.org/debian trixie/main amd64 libnfsidmap1 amd64 1:2.6.4-6 [56,8 kB]
Réception de :3 https://deb.debian.org/debian trixie/main amd64 keyutils amd64 1.6.3-3 [54,8 kB]
Réception de :4 https://deb.debian.org/debian trixie/main amd64 nfs-common amd64 1:2.6.4-6 [265 kB]
Réception de :5 https://deb.debian.org/debian trixie/main amd64 nfs-kernel-server amd64 1:2.6.4-6 [185 kB]
562 ko réceptionnés en 1s (1 108 ko/s) 
Sélection du paquet libnfsidmap1:amd64 précédemment désélectionné.
(Lecture de la base de données... 27640 fichiers et répertoires déjà installés.)
Préparation du dépaquetage de .../libnfsidmap1_1%3a2.6.4-6_amd64.deb ...
Dépaquetage de libnfsidmap1:amd64 (1:2.6.4-6) ...
Sélection du paquet keyutils précédemment désélectionné.
Préparation du dépaquetage de .../keyutils_1.6.3-3_amd64.deb ...
Dépaquetage de keyutils (1.6.3-3) ...
Sélection du paquet nfs-common précédemment désélectionné.
Préparation du dépaquetage de .../nfs-common_1%3a2.6.4-6_amd64.deb ...
Dépaquetage de nfs-common (1:2.6.4-6) ...
Sélection du paquet nfs-kernel-server précédemment désélectionné.
Préparation du dépaquetage de .../nfs-kernel-server_1%3a2.6.4-6_amd64.deb ...
Dépaquetage de nfs-kernel-server (1:2.6.4-6) ...
Paramétrage de libnfsidmap1:amd64 (1:2.6.4-6) ...
Paramétrage de keyutils (1.6.3-3) ...
Paramétrage de nfs-common (1:2.6.4-6) ...

Creating config file /etc/idmapd.conf with new version

Creating config file /etc/nfs.conf with new version
info: Selecting UID from range 100 to 999 ...

info: Adding system user `statd' (UID 105) ...
info: Adding new user `statd' (UID 105) with group `nogroup' ...
info: Not creating home directory `/var/lib/nfs'.
Created symlink '/etc/systemd/system/multi-user.target.wants/nfs-client.target' → '/usr/lib/systemd/system/nfs-client.target'.
Created symlink '/etc/systemd/system/remote-fs.target.wants/nfs-client.target' → '/usr/lib/systemd/system/nfs-client.target'.
auth-rpcgss-module.service is a disabled or a static unit, not starting it.
nfs-idmapd.service is a disabled or a static unit, not starting it.
nfs-utils.service is a disabled or a static unit, not starting it.
proc-fs-nfsd.mount is a disabled or a static unit, not starting it.
rpc-gssd.service is a disabled or a static unit, not starting it.
rpc-statd-notify.service is a disabled or a static unit, not starting it.
rpc-statd.service is a disabled or a static unit, not starting it.
rpc-svcgssd.service is a disabled or a static unit, not starting it.
[ 6973.381274] RPC: Registered named UNIX socket transport module.
[ 6973.381642] RPC: Registered udp transport module.
[ 6973.381938] RPC: Registered tcp transport module.
[ 6973.382215] RPC: Registered tcp-with-tls transport module.
[ 6973.382514] RPC: Registered tcp NFSv4.1 backchannel transport module.
Paramétrage de nfs-kernel-server (1:2.6.4-6) ...
Created symlink '/etc/systemd/system/nfs-mountd.service.requires/fsidd.service' → '/usr/lib/systemd/system/fsidd.service'.
Created symlink '/etc/systemd/system/nfs-server.service.requires/fsidd.service' → '/usr/lib/systemd/system/fsidd.service'.
Created symlink '/etc/systemd/system/nfs-client.target.wants/nfs-blkmap.service' → '/usr/lib/systemd/system/nfs-blkmap.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/nfs-server.service' → '/usr/lib/systemd/system/nfs-server.service'.
nfs-mountd.service is a disabled or a static unit, not starting it.
nfsdcld.service is a disabled or a static unit, not starting it.
[ 6974.734348] NFSD: Using nfsdcld client tracking operations.
[ 6974.735739] NFSD: no clients to reclaim, skipping NFSv4 grace period (net f0000000)

Creating config file /etc/exports with new version

Creating config file /etc/default/nfs-kernel-server with new version
Traitement des actions différées (« triggers ») pour man-db (2.12.1-3) ...
Traitement des actions différées (« triggers ») pour libc-bin (2.39-7) ...
Scanning processes...                                                                          
Scanning linux images...                                                                       

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
etu@localhost:~$ systemctl status nfs-kernel-server
● nfs-server.service - NFS server and services
     Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; preset: enabled)
     Active: active (exited) since Thu 2024-09-05 18:19:16 CEST; 10s ago
 Invocation: abae2c4b21ec431c9064035c38aa7621
   Main PID: 1733 (code=exited, status=0/SUCCESS)
   Mem peak: 1.6M
        CPU: 27ms

sept. 05 18:19:15 localhost systemd[1]: Starting nfs-server.service - NFS server and services.>
sept. 05 18:19:15 localhost exportfs[1732]: exportfs: can't open /etc/exports for reading
sept. 05 18:19:16 localhost systemd[1]: Finished nfs-server.service - NFS server and services.

etu@localhost:~$ sudo mkdir -p /home/exports/home
etu@localhost:~$ cat << EOF | sudo tee -a /etc/exports
/home/exports           192.168.237.120/27(rw,sync,fsid=0,crossmnt,no_subtree_check)
/home/exports/home      192.168.237.120/27(rw,sync,no_subtree_check)
EOF
etu@localhost:~$ cat /etc/exports 

/home/exports           192.168.237.120/27(rw,sync,fsid=0,crossmnt,no_subtree_check)
/home/exports/home      192.168.237.120/27(rw,sync,no_subtree_check)

etu@localhost:~$ systemctl restart  nfs-kernel-server
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
Une authentification est requise pour redémarrer 'nfs-server.service'.
Authenticating as: ,,, (etu)
Password: 
==== AUTHENTICATION COMPLETE ====
[ 8339.452971] NFSD: Using nfsdcld client tracking operations.
[ 8339.454371] NFSD: no clients to reclaim, skipping NFSv4 grace period (net f0000000)
etu@localhost:~$ sudo exportfs 
/home/exports 	192.168.237.120/27
/home/exports/home 192.168.237.120/27
```
* Config de /ahome sur le serveur
```
etu@localhost:~$ echo "/home/exports/home /ahome none defaults, bind 0 0" | \
> sudo tee -a /etc/fstab
/home/exports/home /ahome none defaults, bind 0 0
etu@localhost:~$ grep -v ^# /etc/fstab
PARTUUID=1b6f0363-a0f2-43b0-8533-f1b352d16e64 / ext4 rw,discard,errors=remount-ro,x-systemd.growfs 0 1
PARTUUID=0e01dba2-4162-44f5-a8aa-bb1c3b475c87 /boot/efi vfat defaults 0 0
/home/exports/home /ahome none defaults, bind 0 0
etu@localhost:~$ 
```
# Création d'un compte utilisateur local baptisé etu-nfs avec un répertoire utilisateur situé sous la racine /ahome
```
etu@localhost:~$ sudo adduser --home /ahome/etu-nfs etu-nfs
info: Adding user `etu-nfs' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `etu-nfs' (1001) ...
info: Adding new user `etu-nfs' (1001) with group `etu-nfs (1001)' ...
info: Creating home directory `/ahome/etu-nfs' ...
info: Copying files from `/etc/skel' ...
Nouveau mot de passe : 
Retapez le nouveau mot de passe : 
Aucun mot de passe n’a été fourni.
Nouveau mot de passe : 
Retapez le nouveau mot de passe : 
Aucun mot de passe n’a été fourni.
Nouveau mot de passe : 
Retapez le nouveau mot de passe : 
passwd : mot de passe mis à jour avec succès
Modifier les informations associées à un utilisateur pour etu-nfs
Entrer la nouvelle valeur, ou appuyer sur ENTER pour la valeur par défaut
	NOM []: 
	Numéro de chambre []: 
	Téléphone professionnel []: 
	Téléphone personnel []: 
	Autre []: 
Is the information correct? [Y/n] 
info: Adding new user `etu-nfs' to supplemental / extra groups `users' ...
info: Adding user `etu-nfs' to group `users' ...
etu@localhost:~$ id etu-nfs
uid=1001(etu-nfs) gid=1001(etu-nfs) groupes=1001(etu-nfs),100(users)
etu@localhost:~$ 

```

## Création d'un fichier côté Serveur (avec le compte etu-nfs crée):
```
etu-nfs@localhost:~$ echo "Voici mon fichier" > file.txt
etu-nfs@localhost:~$ exit
déconnexion
```
# Config du client NFS

* Nous voyons que le RFC a évolué
```
etu@localhost:~$ rpcinfo -s 192.168.237.124
   program version(s) netid(s)                         service     owner
    100000  2,3,4     local,udp,tcp,udp6,tcp6          portmapper  superuser
    100024  1         tcp6,udp6,tcp,udp                status      105
    100005  3,2,1     tcp6,udp6,tcp,udp                mountd      superuser
    100003  4,3       tcp6,tcp                         nfs         superuser
    100227  3         tcp6,tcp                         nfs_acl     superuser
    100021  4,3,1     tcp6,udp6,tcp,udp                nlockmgr    superuser
```
* Visualisons les systèmes de fichiers NFS exportés par un serveur (showmount)
```
etu@localhost:~$ dpkg -L nfs-common | grep showmount
/usr/sbin/showmount
/usr/share/man/man8/showmount.8.gz

etu@localhost:~$v sudo mkdir /ahome

etu@localhost:~$ sudo showmount -e 192.168.237.124
Export list for 192.168.237.124:
/home/exports/home 192.168.237.120/27
/home/exports      192.168.237.120/27

etu@localhost:~$ sudo mount [192.168.237.124]:/home /ahome
[21140.748897] netfs: FS-Cache loaded
[21140.879660] Key type dns_resolver registered
[21141.077830] NFS: Registering the id_resolver key type
[21141.078231] Key type id_resolver registered
[21141.078542] Key type id_legacy registered

etu@localhost:~$ ls /ahome/
etu-nfs
etu@localhost:~$ 

sudo cat /etc/fstab 
PARTUUID=1b6f0363-a0f2-43b0-8533-f1b352d16e64 / ext4 rw,discard,errors=remount-ro,x-systemd.growfs 0 1
PARTUUID=0e01dba2-4162-44f5-a8aa-bb1c3b475c87 /boot/efi vfat defaults 0 0
192.168.237.124:/home   /ahome   nfs4    0   0
```

# Montage automatique 
```
etu@localhost:~$ sudo umount /ahome
etu@localhost:~$ sudo apt install autofs
Installing:                                     
  autofs

Summary:
  Upgrading: 0, Installing: 1, Removing: 0, Not Upgrading: 0
  Download size: 288 kB
  Space needed: 944 kB / 70,6 GB available

Réception de :1 file:/etc/apt/mirrors/debian.list Mirrorlist [30 B]
Réception de :2 https://deb.debian.org/debian trixie/main amd64 autofs amd64 5.1.9-1.1+b1 [288 kB]
288 ko réceptionnés en 3s (82,9 ko/s)   
Sélection du paquet autofs précédemment désélectionné.
(Lecture de la base de données... 27752 fichiers et répertoires déjà installés.)
Préparation du dépaquetage de .../autofs_5.1.9-1.1+b1_amd64.deb ...
Dépaquetage de autofs (5.1.9-1.1+b1) ...
Paramétrage de autofs (5.1.9-1.1+b1) ...

Creating config file /etc/auto.master with new version

Creating config file /etc/auto.net with new version

Creating config file /etc/auto.misc with new version

Creating config file /etc/auto.smb with new version

Creating config file /etc/autofs.conf with new version

Creating config file /etc/default/autofs with new version
update-rc.d: warning: start and stop actions are no longer supported; falling back to defaults
Created symlink '/etc/systemd/system/multi-user.target.wants/autofs.service' → '/usr/lib/systemd/system/autofs.service'.
Traitement des actions différées (« triggers ») pour man-db (2.13.0-1) ...
Scanning processes...                                                                                              
Scanning linux images...                                                                                           

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
```
* Manip fichier d'autoconfig
```
etu@localhost:~$ sudo cat /etc/auto.master.d/ahome.autofs
/ahome  /etc/auto.home
etu@localhost:~$ sudo cat /etc/auto.home
*    -fstype=nfs4    [192.168.237.124]:/home/&
etu@localhost:~$ 
etu@localhost:~$ sudo systemctl restart autofs
etu@localhost:~$ 

```
