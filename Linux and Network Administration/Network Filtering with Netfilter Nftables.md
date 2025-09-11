# Context 
* We use the HUB and Spoke Technologies 
### HUB 
* It consolidates all network traffic from routers functioning as Spokes. Communication between two Spoke routers must pass through the Hub router. Additionally, it serves as a Broadband Remote Access Server (BRAS). In our context, this role is characterized by the router managing the addressing plan. It is responsible for assigning IP addresses during the initiation of PPP sessions.
### Spoke
* The Spoke role corresponds to an edge network beyond which no further interconnection exists. A Spoke router must communicate with the Hub router whenever it needs to route network traffic. It is essentially an edge router with no alternative path to access the Internet.

In home networks, the “box” (home gateway) typically fulfills the Spoke role, as it is assigned public IPv4 and IPv6 addresses by the Internet Service Provider (ISP). The only information it retains are the customer’s credentials provided by the ISP.

To begin, we focus on installing the necessary tools and reviewing the existing filtering rules configured on the Hub router.
# Hub 210 | Spoke 211

# Config Machines
## switch.yaml file
* We config with Vlan mode on trunks and we use the VLAN 506,507,43,60
```
ovs:
  switches:
    - name: dsw-host
      ports:
        - name: tap530
          type: OVSPort
          vlan_mode: trunk
          trunks: [586,587,43,60]
```

## lab.yaml file 
* File config for spoke211 machine using the tap 530
```
kvm:
  vms:
    - vm_name: spoke211
      master_image: debian-testing-amd64.qcow2 # master image to be used
      force_copy: false # force copy the master image to the VM image
      memory: 1094
      tapnum: 530
```

```
etu@spoke211:~$ sudo nft list table inet raw
table inet raw {
        chain rpfilter {
                type filter hook prerouting priority raw; policy accept;
                iifname "ppp0" fib saddr . iif oif 0 counter packets 10 bytes 280 drop
        }
}

etu@spoke211:~$ sudo nft list table inet raw
[sudo] Mot de passe de etu : 
table inet raw {
        chain rpfilter {
                type filter hook prerouting priority raw; policy accept;
                iifname "ppp0" fib saddr . iif oif 0 counter packets 20 bytes 1320 drop
        }
}

etu@spoke211:~$ sudo sysctl -w net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.rp_filter = 1


etu@spoke211:~$ journalctl -n 500 -f --grep martian
nov. 04 18:33:18 spoke211 kernel: IPv4: martian source 100.64.43.10 from 227.68.102.255, on dev ppp0
nov. 04 18:33:18 spoke211 kernel: IPv4: martian source 100.64.43.10 from 236.78.72.232, on dev ppp0
nov. 04 18:33:19 spoke211 kernel: IPv4: martian source 100.64.43.10 from 239.139.77.8, on dev ppp0
nov. 04 18:33:21 spoke211 kernel: IPv4: martian source 100.64.43.10 from 231.217.22.1, on dev ppp0
nov. 04 18:33:21 spoke211 kernel: IPv4: martian source 100.64.43.10 from 236.159.78.54, on dev ppp0
nov. 04 18:33:22 spoke211 kernel: IPv4: martian source 100.64.43.10 from 227.210.117.169, on dev ppp0
nov. 04 18:33:22 spoke211 kernel: IPv4: martian source 100.64.43.10 from 226.186.72.54, on dev ppp0
nov. 04 18:33:23 spoke211 kernel: IPv4: martian source 100.64.43.10 from 230.78.227.234, on dev ppp0
nov. 04 18:33:23 spoke211 kernel: IPv4: martian source 100.64.43.10 from 234.186.162.57, on dev ppp0
nov. 04 18:33:24 spoke211 kernel: IPv4: martian source 100.64.43.10 from 227.90.49.22, on dev ppp0
nov. 04 18:33:24 spoke211 kernel: IPv4: martian source 100.64.43.10 from 235.191.47.149, on dev ppp0
nov. 04 18:33:26 spoke211 kernel: IPv4: martian source 100.64.43.10 from 226.234.221.235, on dev ppp0
nov. 04 18:33:27 spoke211 kernel: IPv4: martian source 100.64.43.10 from 232.43.54.185, on dev ppp0
nov. 04 18:33:27 spoke211 kernel: IPv4: martian source 100.64.43.10 from 224.76.196.40, on dev ppp0


etu@hub210:~$ sudo hping3 -1 --flood -c 10 10.211.21.2
HPING 10.211.21.2 (ppp0 10.211.21.2): icmp mode set, 28 headers + 0 data bytes
hping in flood mode, no replies will be shown


--- 10.211.21.2 hping statistic ---
25818962 packets transmitted, 0 packets received, 100% packet loss
round-trip min/avg/max = 0.0/0.0/0.0 ms
etu@hub210:~$ ping -qc 10 10.211.21.2
PING 10.211.21.2 (10.211.21.2) 56(84) bytes of data.

--- 10.211.21.2 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9078ms
rtt min/avg/max/mdev = 0.767/0.966/1.219/0.132 ms

etu@spoke211:~$ sudo nft list table inet raw
table inet raw {
        chain rpfilter {
                type filter hook prerouting priority raw; policy accept;
                iifname "ppp0" fib saddr . iif oif 0 counter packets 0 bytes 0 drop
        }

        chain icmpfilter {
                type filter hook prerouting priority raw; policy accept;
                icmp type echo-request limit rate 10/second burst 5 packets counter packets 10 bytes 840 accept
                icmp type echo-request counter packets 0 bytes 0 drop
        }
}
etu@hub210:~$ ssh -p 2222 etu@10.211.21.2
etu@10.211.21.2's password: 
Permission denied, please try again.
etu@10.211.21.2's password: 
Permission denied, please try again.
etu@10.211.21.2's password: 
etu@10.211.21.2: Permission denied (publickey,password).
etu@hub210:~$ ssh -p 2222 etu@10.211.21.2
ssh: connect to host 10.211.21.2 port 2222: Connection refused

etu@spoke211:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   10.211.21.1
etu@spoke211:~$ sudo nft list table inet f2b-table
table inet f2b-table {
        set addr-set-sshd {
                type ipv4_addr
                elements = { 10.211.21.1 }
        }

        chain f2b-chain {
                type filter hook input priority filter - 1; policy accept;
                tcp dport 2222 ip saddr @addr-set-sshd reject with icmp port-unreachable
        }
}


etu@hub210:~$ ssh -p 2222 etu@fe80::9164:6e90:99e4:b729%ppp0
The authenticity of host '[fe80::9164:6e90:99e4:b729%ppp0]:2222 ([fe80::9164:6e90:99e4:b729%ppp0]:2222)' can't be established.
ED25519 key fingerprint is SHA256:jxdxFO/jYTC/7x8vMF3f9cmC5abEarQMDB2dc2MHJ/Q.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:1: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[fe80::9164:6e90:99e4:b729%ppp0]:2222' (ED25519) to the list of known hosts.
etu@fe80::9164:6e90:99e4:b729%ppp0's password: 
Permission denied, please try again.
etu@fe80::9164:6e90:99e4:b729%ppp0's password: 
Permission denied, please try again.
etu@fe80::9164:6e90:99e4:b729%ppp0's password: 
etu@fe80::9164:6e90:99e4:b729%ppp0: Permission denied (publickey,password).
etu@hub210:~$ ssh -p 2222 etu@fe80::9164:6e90:99e4:b729%ppp0
ssh: connect to host fe80::9164:6e90:99e4:b729%ppp0 port 2222: Connection refused

etu@spoke211:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     6
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 2
   |- Total banned:     2
   `- Banned IP list:   10.211.21.1 fe80::c9ac:8a2a:6635:7eb9
etu@spoke211:~$ 
etu@spoke211:~$ sudo nft list table inet f2b-table
table inet f2b-table {
        set addr-set-sshd {
                type ipv4_addr
                elements = { 10.211.21.1 }
        }

        set addr6-set-sshd {
                type ipv6_addr
                elements = { fe80::c9ac:8a2a:6635:7eb9 }
        }

        chain f2b-chain {
                type filter hook input priority filter - 1; policy accept;
                tcp dport 2222 ip saddr @addr-set-sshd reject with icmp port-unreachable
                tcp dport 2222 ip6 saddr @addr6-set-sshd reject with icmpv6 port-unreachable
        }
}
    etu@spoke211:~$ for i in {0..2}
do
    echo ">>>>>>>>>>>>>>>>> c$i"
    incus exec c$i -- apt update
done
>>>>>>>>>>>>>>>>> c0
Get:1 http://deb.debian.org/debian trixie InRelease [172 kB]
Get:2 http://deb.debian.org/debian trixie-updates InRelease [49.6 kB]
Get:3 http://deb.debian.org/debian-security trixie-security InRelease [43.5 kB]
Get:4 http://deb.debian.org/debian trixie/main amd64 Packages.diff/Index [27.9 kB]
Ign:4 http://deb.debian.org/debian trixie/main amd64 Packages.diff/Index
Get:5 http://deb.debian.org/debian trixie/main Translation-en.diff/Index [27.9 kB]
Ign:5 http://deb.debian.org/debian trixie/main Translation-en.diff/Index
Get:6 http://deb.debian.org/debian trixie/main amd64 Packages [9345 kB]
Get:7 http://deb.debian.org/debian trixie/main Translation-en [6244 kB]
Fetched 15.9 MB in 2s (7036 kB/s)                           
126 packages can be upgraded. Run 'apt list --upgradable' to see them.
>>>>>>>>>>>>>>>>> c1
Get:1 http://deb.debian.org/debian trixie InRelease [172 kB]
Get:2 http://deb.debian.org/debian trixie-updates InRelease [49.6 kB]
Get:3 http://deb.debian.org/debian-security trixie-security InRelease [43.5 kB]
Get:4 http://deb.debian.org/debian trixie/main amd64 Packages.diff/Index [27.9 kB]
Ign:4 http://deb.debian.org/debian trixie/main amd64 Packages.diff/Index
Get:5 http://deb.debian.org/debian trixie/main Translation-en.diff/Index [27.9 kB]
Ign:5 http://deb.debian.org/debian trixie/main Translation-en.diff/Index
Get:6 http://deb.debian.org/debian trixie/main amd64 Packages [9345 kB]
Get:7 http://deb.debian.org/debian trixie/main Translation-en [6244 kB]
Fetched 15.9 MB in 2s (6671 kB/s)                              
126 packages can be upgraded. Run 'apt list --upgradable' to see them.
>>>>>>>>>>>>>>>>> c2
Get:1 http://deb.debian.org/debian trixie InRelease [172 kB]
Get:2 http://deb.debian.org/debian trixie-updates InRelease [49.6 kB]
Get:3 http://deb.debian.org/debian-security trixie-security InRelease [43.5 kB]
Get:4 http://deb.debian.org/debian trixie/main amd64 Packages.diff/Index [27.9 kB]
Ign:4 http://deb.debian.org/debian trixie/main amd64 Packages.diff/Index
Get:5 http://deb.debian.org/debian trixie/main Translation-en.diff/Index [27.9 kB]
Ign:5 http://deb.debian.org/debian trixie/main Translation-en.diff/Index
Get:6 http://deb.debian.org/debian trixie/main amd64 Packages [9345 kB]
Get:7 http://deb.debian.org/debian trixie/main Translation-en [6244 kB]
Fetched 15.9 MB in 3s (4705 kB/s)                                
126 packages can be upgraded. Run 'apt list --upgradable' to see them.
etu@spoke211:~$ sudo nft list table inet filter
table inet filter {
        chain forward {
                type filter hook forward priority filter; policy drop;
                oifname "ppp0" ct state new counter packets 12 bytes 912 accept
                ct state established,related accept
                iifname "ppp0" meta l4proto { icmp, ipv6-icmp } ct state new counter packets 0 bytes 0 accept
                iifname "ppp0" tcp dport 2222 ct state new counter packets 0 bytes 0 accept
                iifname "ppp0" meta l4proto { tcp, udp } th dport { 80, 443 } ct state new counter packets 0 bytes 0 accept
                counter packets 0 bytes 0 comment "count dropped packets"
        }
}
etu@spoke211:~$ sudo nft list table inet filter
table inet filter {
        chain forward {
                type filter hook forward priority filter; policy drop;
                oifname "ppp0" ct state new counter packets 21 bytes 1656 accept
                ct state established,related accept
                iifname "ppp0" meta l4proto { icmp, ipv6-icmp } ct state new counter packets 0 bytes 0 accept
                iifname "ppp0" tcp dport 2222 ct state new counter packets 0 bytes 0 accept
                iifname "ppp0" meta l4proto { tcp, udp } th dport { 80, 443 } ct state new counter packets 0 bytes 0 accept
                counter packets 0 bytes 0 comment "count dropped packets"
                oifname "ppp0" ct state new counter packets 0 bytes 0 accept
                ct state established,related accept
                iifname "ppp0" meta l4proto { icmp, ipv6-icmp } ct state new counter packets 0 bytes 0 accept
                iifname "ppp0" tcp dport 2222 ct state new counter packets 0 bytes 0 accept
                iifname "ppp0" meta l4proto { tcp, udp } th dport { 80, 443 } ct state new counter packets 0 bytes 0 accept
                counter packets 0 bytes 0 comment "count dropped packets"
        }
}
etu@hub210:~$ for addr in {10..12}
do
 wget -O /dev/null http://100.64.43.$addr 2>&1 | grep "HTTP "
done
requête HTTP transmise, en attente de la réponse… 200 OK
requête HTTP transmise, en attente de la réponse… 200 OK
requête HTTP transmise, en attente de la réponse… 200 OK

etu@hub210:~$ for addr in {10..12}
do
 wget -O /dev/null http://[fda0:7a62:2b::$(printf "%x" $addr)] 2>&1 | grep "HTTP "
done
requête HTTP transmise, en attente de la réponse… 200 OK
requête HTTP transmise, en attente de la réponse… 200 OK
requête HTTP transmise, en attente de la réponse… 200 OK
```

## Filtering
* See filters
```
etu@localhost:~$ sudo nft list table inet raw
[sudo] Mot de passe de etu :
table inet raw {
        chain rpfilter {
                type filter hook prerouting priority raw; policy accept;
                iifname "ppp0" fib saddr . iif oif 0 counter packets 0 bytes 0 drop
        }

        chain icmpfilter {
                type filter hook prerouting priority raw; policy accept;
                icmp type echo-request limit rate 10/second burst 5 packets counter packets 0 bytes 0 accept
                icmp type echo-request counter packets 0 bytes 0 drop
        }
}
etu@localhost:~$
```

* Impersonification 
```
etu@HUB:~$ sudo hping3 -1 -a 100.64.44.12 --fast -c 100.64.44.10
[sudo] Mot de passe de etu :
HPING 100.64.44.10 (ppp0 100.64.44.10): icmp mode set, 28 headers + 0 data bytes

--- 100.64.44.10 hping statistic ---
10 packets transmitted, 0 packets received, 100% packet loss
round-trip min/avg/max = 0.0/0.0/0.0 ms
```

* Check blocking

```
etu@localhost:~$ sudo nft list table inet raw
table inet raw {
        chain rpfilter {
                type filter hook prerouting priority raw; policy accept;
                iifname "ppp0" fib saddr . iif oif 0 counter packets 20 bytes 560 drop
        }

        chain icmpfilter {
                type filter hook prerouting priority raw; policy accept;
                icmp type echo-request limit rate 10/second burst 5 packets counter packets 0 bytes 0 accept
                icmp type echo-request counter packets 0 bytes 0 drop
        }
}
```

* Checking list for IPV6
```
etu@localhost:~$ sudo nft list table inet raw
table inet raw {
        chain rpfilter {
                type filter hook prerouting priority raw; policy accept;
                iifname "ppp0" fib saddr . iif oif 0 counter packets 80 bytes 6420 drop
        }

        chain icmpfilter {
                type filter hook prerouting priority raw; policy accept;
                icmp type echo-request limit rate 10/second burst 5 packets counter packets 0 bytes 0 accept
                icmp type echo-request counter packets 0 bytes 0 drop
        }
}
```
## FLOOD ICMP 
```
etu@HUB:~$ sudo hping3 -1 --flood -c 10 100.64.44.10
HPING 100.64.44.10 (ppp0 100.64.44.10): icmp mode set, 28 headers + 0 data bytes
hping in flood mode, no replies will be shown

--- 100.64.44.10 hping statistic ---
61492309 packets transmitted, 0 packets received, 100% packet loss
round-trip min/avg/max = 0.0/0.0/0.0 ms
```

* Verification 
```
etu@localhost:~$ sudo nft list table inet raw
table inet raw {
    chain rpfilter {
        type filter hook prerouting priority raw; policy accept;
        iifname "ppp0" fib saddr . iif oif 0 counter packets 100 bytes 8140 drop
    }

    chain icmpfilter {
        type filter hook prerouting priority raw; policy accept;
        icmp type echo-request limit rate 10/second burst 5 packets counter packets 5378 bytes 150584 accept
        icmp type echo-request counter packets 90460174 bytes 2532884872 drop
    }
}
```

## Fail2BAN 
* Installation
```
etu@localhost:~$ sudo apt -y install fail2ban
```
* Verification of listen port
```
etu@localhost:~$ sudo lsof -i tcp:2222 -sTCP:listen
COMMAND PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
sshd    843 root    7u  IPv4   3016      0t0  TCP *:2222 (LISTEN)
sshd    843 root    8u  IPv6   3018      0t0  TCP *:2222 (LISTEN)
etu@localhost:~$ ss -tapl '( sport = :2222 )' | fmt -t -w80
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      128          0.0.0.0:2222      0.0.0.0:*
LISTEN 0      128             [::]:2222         [::]:*
```

## Config Exclusion
```
cat << EOF | sudo tee /etc/fail2ban/jail.d/custom-sshd.conf
[sshd]
enabled = true
port = 2222
filter = sshd
backend = systemd
banaction = nftables-multiport
maxretry = 3
bantime = 1h
findtime = 10m
EOF```

etu@localhost:~$ dpkg -L fail2ban | grep bin
/usr/bin
/usr/bin/fail2ban-client
/usr/bin/fail2ban-regex
/usr/bin/fail2ban-server
/usr/bin/fail2ban-testcases
/usr/bin/fail2ban-python`
```
* Fail2ban status
```
etu@localhost:~$ sudo fail2ban-client status
Status
|- Number of jail:      1
`- Jail list:   sshd
```

## Status 
```
etu@localhost:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

## Intrusion test 

* Now on the Hub machine we can try an intrusion to check the rules 
```
etu@HUB:~$ ssh -p 2222 etu@10.212.21.2
ssh: connect to host 10.212.21.2 port 2222: Connection refused
```
* And then check the fail2ban status 
```
etu@localhost:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   10.212.21.1
```

## Adding new rule
```
etu@localhost:~$ sudo nft list ruleset
```

```
etu@localhost:~$ sudo nft list table inet f2b-table
table inet f2b-table {
    set addr-set-sshd {
        type ipv4_addr
        elements = { 10.212.21.1 }
    }

    chain f2b-chain {
        type filter hook input priority filter - 1; policy accept;
        tcp dport 2222 ip saddr @addr-set-sshd reject with icmp port-unreachable
    }
} 
```

### Network Flow
```
table inet filter {
    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow outbound new connections
        oifname "ppp0" ct state new counter accept

        # Allow established and related connections
        ct state established,related accept

        # Allow specific inbound traffic
        # ICMP IPv4 + IPv6
        iifname "ppp0" meta l4proto {icmp, ipv6-icmp} ct state new counter accept
        # SSH
        iifname "ppp0" tcp dport 2222 ct state new counter accept
        # HTTP(S)
        iifname "ppp0" meta l4proto {tcp, udp} th dport {80, 443} ct state new counter accept

        # Count dropped packets
        counter comment "count dropped packets"
    }
}
```

* Accept entering flow 
```
oifname "ppp0" ct state new counter accept
```
* PORTS 80 and 443
```
iifname "ppp0" meta l4proto {tcp, udp} th dport {80, 443} ct state new counter accept
ct state established,related accept
```

* Apply rules

```
	
7:50 AM










CONFIG exclusion
cat << EOF | sudo tee /etc/fail2ban/jail.d/custom-sshd.conf
[sshd]
enabled = true
port = 2222
filter = sshd
backend = systemd
banaction = nftables-multiport
maxretry = 3
bantime = 1h
findtime = 10m
EOF```
etu@localhost:~$ dpkg -L fail2ban | grep bin
/usr/bin
/usr/bin/fail2ban-client
/usr/bin/fail2ban-regex
/usr/bin/fail2ban-server
/usr/bin/fail2ban-testcases
/usr/bin/fail2ban-python```
etu@localhost:~$ sudo fail2ban-client status
Status
|- Number of jail:      1
`- Jail list:   sshd
Status
etu@localhost:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
Test intrusion
etu@HUB:~$ ssh -p 2222 etu@10.212.21.2
etu@10.212.21.2's password:
Permission denied, please try again.
etu@10.212.21.2's password:
Permission denied, please try again.
etu@10.212.21.2's password:
etu@10.212.21.2: Permission denied (publickey,password)

etu@HUB:~$ ssh -p 2222 etu@10.212.21.2
ssh: connect to host 10.212.21.2 port 2222: Connection refused
etu@localhost:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   10.212.21.1
Ajout nouvelle règle
etu@localhost:~$ sudo nft list ruleset
etu@localhost:~$ sudo nft list table inet f2b-table
table inet f2b-table {
    set addr-set-sshd {
        type ipv4_addr
        elements = { 10.212.21.1 }
    }

    chain f2b-chain {
        type filter hook input priority filter - 1; policy accept;
        tcp dport 2222 ip saddr @addr-set-sshd reject with icmp port-unreachable
    }
} 
Flux Réseaux
Chaine
table inet filter {
    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow outbound new connections
        oifname "ppp0" ct state new counter accept

        # Allow established and related connections
        ct state established,related accept

        # Allow specific inbound traffic
        # ICMP IPv4 + IPv6
        iifname "ppp0" meta l4proto {icmp, ipv6-icmp} ct state new counter accept
        # SSH
        iifname "ppp0" tcp dport 2222 ct state new counter accept
        # HTTP(S)
        iifname "ppp0" meta l4proto {tcp, udp} th dport {80, 443} ct state new counter accept

        # Count dropped packets
        counter comment "count dropped packets"
    }
}
Accepter flux entrants
oifname "ppp0" ct state new counter accept
PORTS 80 & 443
iifname "ppp0" meta l4proto {tcp, udp} th dport {80, 443} ct state new counter accept

ct state established,related accept
Appliquer règles
cat << 'EOF' | sudo tee -a /etc/nftables.conf
table inet filter {
    chain forward {
        type filter hook forward priority 0; policy drop;
        # Allow outbound new connections
        oifname "ppp0" ct state new counter accept

        # Allow established and related connections
        ct state established,related accept

        # Allow specific inbound traffic
        # ICMP IPv4 + IPv6
        iifname "ppp0" meta l4proto {icmp, ipv6-icmp} ct state new counter accept
        # SSH
        iifname "ppp0" tcp dport 2222 ct state new counter accept
        # HTTP(S)
        iifname "ppp0" meta l4proto {tcp, udp} th dport {80, 443} ct state new counter accept

        # Count dropped packets
        counter comment "count dropped packets"
}
}
EOF
```
* Restart nftable service and list ruleset
```
sudo systemctl restart nftables.service

sudo nft list ruleset

```
