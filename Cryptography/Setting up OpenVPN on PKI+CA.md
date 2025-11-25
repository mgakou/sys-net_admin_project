#   
  
**Introduction to the Problem and Architecture Overview**  
  
The objective of this project is to deploy a functional OpenVPN infrastructure in a virtualized environment, simulating a realistic network scenario with separation between LAN and WAN zones. The main challenge is to allow a client located **outside the local network** (WAN 192.168.64.0/24) to securely access the OpenVPN server located **inside an internal network** (LAN 192.168.10.0/24), while ensuring routing, Network Address Translation (NAT), and secure traffic forwarding through the router.  
The central issue lies in correctly configuring inter-network routing, NAT, and setting up a VPN tunnel that enables the remote client to reach internal resources as if it were part of the local network.  
1. **A Linux router** providing the connection between the WAN network (enp0s1 – 192.168.64.0/24) and the LAN network (enp0s2 – 192.168.10.0/24). It implements routing rules, iptables, and NAT to allow traffic forwarding.  
2. **A Linux router** providing the connection between the WAN network (enp0s1 – 192.168.64.0/24) and the LAN network (enp0s2 – 192.168.10.0/24). It implements routing rules, iptables, and NAT to allow traffic forwarding.  
3. **A Linux router** providing the connection between the WAN network (enp0s1 – 192.168.64.0/24) and the LAN network (enp0s2 – 192.168.10.0/24). It implements routing rules, iptables, and NAT to allow traffic forwarding.  
![2.168.10.19](Attachments/714E4B1D-262F-4D19-984F-FA9C5FAB9EDE.png)  
  
**Setting UP**  
  
The make-cadir /etc/openvpn/easy-rsa command creates the Easy-RSA directory structure used to generate and manage certificates. The directory is accessed with cd /etc/openvpn/.  
![vm1@vm1 - [127]> sudo make-cadir /etc/openvpn/easy-rsa](Attachments/E89F9AF0-A392-4156-828F-8B3E0883B033.png)  
The make-cadir /etc/openvpn/easy-rsa command creates the Easy-RSA directory structure used to generate and manage certificates. The directory is accessed with cd /etc/openvpn/.  
![root@vm1:/etc/openvpn/easy-rsa# •/easyrsa init-pki](Attachments/859950F0-B501-43E5-8A01-7F5B237FBB68.png)  
Setting up the Certificate Authority:  
![• /etc/openvpn/easy-rsa/vars](Attachments/56371162-00B1-4881-B6FC-DB28A23A9284.png)  
  
Next, we generate a key pair for the server:  
![If you enter ".". the fleld will be left blank.](Attachments/48A8F404-0356-4FB4-BA8E-D26F1964EFF2.png)  
  
  
Diffie–Hellman parameters must be generated for the OpenVPN server. The following command places them in **pki/dh.pem**:  
![rootfvnt:/etc/openvpn/easy-rsa#./easyrsa gen-dh](Attachments/6489757C-C703-4400-8144-CBC20A167B5A.png)  
  
  
Finally, a server certificate is created:  
  
![•](Attachments/F6BCA759-C80C-4ADC-847E-F08C222A38E3.png)  
  
All certificates and keys are generated in subdirectories. Standard practice is to copy them into /etc/openvpn/:  
![root@vnl:/etc/openvpn/easy-rsa# cp pki/dh.pen pkt/ca.crt pkt/tssued/server.crt pkt/priv](Attachments/AE39B3EF-960B-4BF1-BA41-397BE3B0739E.png)  
  
**Client Certificate Creation**  
Certificate generation and signing:  
  
![re a car te bete e te enter Lafernetlen thet wift be Incorporated](Attachments/23310A57-161B-49FB-93AA-069F1FBD7EDB.png)  
  
  
![•](Attachments/B7479EE6-F120-4117-A34D-5679CCBC02D6.png)  
  
Moving the configuration file:  
![root@vn:/etc/opewpn/easy-rsarls](Attachments/836DC19C-99B8-4642-8D16-D96CCE512124.png)  
  
Here we see essential files such as *openssl-easyrsa.cnf*, *vars*, the *pki/* directory, and Easy-RSA scripts.  
The /etc/openvpn/ directory shows *ca.crt*, *dh.pem*, *server.key*, *server.crt*.  
  
Importing the default server configuration:  
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server.conf  
  
Then we modify /etc/openvpn/server.conf to ensure the following lines point to the generated certificates and keys:  
  

| ca ca.crt cert myservername.crt key myservername.key dh dh.pem tls-auth ta.key 0 |
| -------------------------------------------------------------------------------- |
  
  
  
Generation of a TLS authentication key (TA):  
![root@vn1:/etc/openvpn/easy-rsa#l sudo openvpn -genkey secret to.key](Attachments/D6EC43CC-A0FE-45CD-9B7D-AB4A9E79D7F9.png)  
Below, the openvpn@server service starts correctly. The logs confirm the creation of tun0, the assignment of 10.8.0.1/24, and the opening of UDP port 1194.  
“Initialization Sequence Completed” confirms the server is ready.  
![(Group](Attachments/8A2F04E1-F8A9-4CB0-9447-7FEB6791A9BA.png)  
![41 tune «POENTOPOINT, MULTICAST, NOMP, UP, LONER_UP» Atu 1500 alise fa codel state Noot gresp default glen see](Attachments/9FFE150F-31C4-4CF8-8A6C-6985D7592374.png)  
  
**On the Client Side**  
  
Install OpenVPN and transfer the server-generated files:  
  
![ftp_server@ftpserver →> sudo apt install openvpn - y](Attachments/65B339B4-ED92-4F2A-A2A1-D928AF68FCAD.png)  
  
Move files into the correct directory:  
![ftp_server@ftpserver /e/openvpn [1]> sudo mv =/Documents/ca.cct =/Documents/s](Attachments/60B70E19-3E08-4FD2-ADF4-0D382D679358.png)  
![ftp_server@ftpserver /e/openvpn> ls](Attachments/E78C0455-828F-4D33-9BED-066B8632BB76.png)  
  
  
When the client connects to the OpenVPN server, it must reach **the interface the server is actually listening on**.  
The server is in the LAN **192.168.10.0/24** but behind a router.  
The client is in **192.168.64.0/24** and **cannot directly reach a LAN IP**.  
  
The only reachable address is the router’s WAN: **192.168.64.39**.  
  
The router receives the VPN traffic and forwards it to the LAN server (192.168.10.10) using routing + NAT.  
This is exactly like accessing a server behind a home Internet box.  
  
In server.conf, we modify this line:  
  
![# The hostname/IP and port of the server.](Attachments/ED58D854-A44D-4181-9AE3-32C0D905452E.png)  
Add a DNAT rule on the router:  
![c1c1:-/Documents$ sudo iptables - t nat -A PREROUTING -4 enpest -p udp •-dpor](Attachments/4D138DF4-8BD2-47FC-9B5A-4F8A9FC682BA.png)  
OpenVPN now works correctly:  
![mer 10 (e: 1.0)](Attachments/1ABD93EF-3279-4122-8000-DECBCC0BEF57.png)  
  
The tun0 tunnel is created on the client:  
![_server@ftpserver](Attachments/0DDADFF4-8411-4F0D-A7F7-80BCC374A983.png)  
The client can ping through the tunnel, and vice versa:  
![page13_img2.png](Attachments/ECC77DFC-1B80-4167-8286-CA5C339A0608.png)  
![root@1:/etc/openvp/easy-rsat ping -c2 10.8.0.2](Attachments/A077A798-7609-44F1-AED0-DE8CC581BBFE.png)  
Once connected to the VPN, the client receives an IP address from the VPN network (10.8.0.x), but it does not automatically know how to reach the LAN behind the server. The server therefore has to send it a static route (push) saying: “if you want to reach 192.168.10.0/24, go through the VPN tunnel.” This allows the client to access the LAN as if it were part of it. Without this route, the client would only see the VPN server (10.8.0.1) and never the LAN machines, because it would send the packets to its local gateway instead of sending them into the tunnel.  
  
So that the client can reach the 192.168.10.0 network behind the gateway.  
![# Push routes to the client to allow it](Attachments/D0A9C870-3A86-4C95-8535-D9188FB4AB67.png)  
These rules below are added on the router and allow traffic coming from VPN clients (network 10.8.0.0/24) to access the LAN and the Internet. The first rule allows VPN traffic to leave the router towards the LAN (enp0s2), the second allows responses from the LAN back to the VPN clients, and the third applies NAT (MASQUERADE) so that VPN clients can access the Internet using the router’s WAN address.  
![c1ęc1:-/Docunents$ sudo iptables -t nat](Attachments/19D4675D-C223-4EAB-826C-674C6D3E3188.png)  
After this modification, we restart the OpenVPN service on the server and test the ping from the client to the 192.168.10.0/24 network (here we are pinging the OpenVPN server at 192.168.10.10).  
![ftp_server@ftpserver /e/openvpn [1]> ping -c3 192.168.10.10](Attachments/34242D3B-036A-4EAB-8D1A-851D2926F5E3.png)  
**Conclusion**  
The implementation of this OpenVPN infrastructure made it possible to successfully establish a secure tunnel between the client and the server, while correctly integrating routing to the LAN network. The deployed architecture — consisting of a router with dual interfaces (WAN 192.168.64.0/24 and LAN 192.168.10.0/24), an OpenVPN server located on the LAN, and a remote client — now operates coherently thanks to rigorous configuration of encryption, Easy-RSA certificates, and iptables rules enabling forwarding and NAT. After several adjustments to resolve firewall, NAT, and certificate path issues, the VPN environment provides stable connectivity: the client reaches the server via its WAN interface, receives an IP address in 10.8.0.0/24, and can access the server’s private network. This work demonstrates mastery of PKI concepts, routing, firewalling, and the secure deployment of a VPN solution in a virtualized environment.  
