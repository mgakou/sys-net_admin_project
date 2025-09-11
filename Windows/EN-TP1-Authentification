# Objective: Understand the authentication systems offered by Active Directory.
## Skills:
* - Master authentication systems
* - Learn to manage Kerberos
* - Understand NTLM and LDAP
![](ressources/TP1/image10.jpg)

MOHAMED GAKOU

December 9, 2024  
## Table of Contents

## 0. Preliminary Step

## 1. Infrastructure Diagram Design

## 2. Wireshark Analysis

## 3. KRBTGT Account

## 4. Security Policy

## 5. Authentication Silo

## 6. Other Authentication Methods

## Conclusion

## 0. Preliminary Step

In this step, we configure the network addresses on the AD server and on the client joined to the domain:  

As shown in Image 1 (below), we set up AD on the machine and configured a static IPv4 address **192.168.9.2/24** with a default gateway **192.168.9.1.** As seen in Image 2, there is only one DNS server. Since we are setting up AD, the DNS points to the IP of the AD machine, because Active Directory relies on DNS to locate services and network resources. The DNS integrated with AD is essential for resolving machine names, discovering domain controllers, and enabling Kerberos authentication and other network services.

![Network and AD Config](ressources/TP1/image1.png)

![](ressources/TP1/image2.png)

We can clearly see that AD is properly installed on the machine (see Image 3).

![](ressources/TP1/image3.png)

Next, we configure a client machine to join the AD domain. We assign it IPv4 **192.168.9.3/24**, a default gateway, and set the DNS server to point to the AD domain controller IP (see Image 4). Ping works both ways between the machines, as shown in Images 5 and 6.

![](ressources/TP1/image4.png)

![](ressources/TP1/image5-6.png)

We then add the client machine to the AD domain using **Add-Computer** (Image 8). We can see that the client is now joined to the domain (see Image 8).

![](ressources/TP1/image7.png)

![](ressources/TP1/image8.png)

## **1. Infrastructure Diagram Design**  {#1.infrastructure-diagram-design}

![](ressources/TP1/image_kerberos.jpg)

Kerberos is a network authentication protocol designed to ensure secure exchanges between users and services within a network, especially in environments where communication security is critical. This protocol is particularly useful in enterprise networks where multiple users need access to different services or applications. It uses symmetric cryptography to encrypt communications, ensuring confidentiality and integrity of transmitted data. Once authenticated, a user can access services without re-entering credentials, making it a convenient solution for access management in large infrastructures.

Kerberos operates in four main steps, using encryption keys to secure communication at each stage:

1. **Authentication Request (AS-REQ)**: The client wants to access a service. Without ever sending its password in cleartext, it sends an authentication request to the **Authentication Server (AS)** containing only its identifier (**Client ID**).  
2. **Authentication Server Reply (AS-REP)**: The **AS** looks up the client ID in its database and verifies the password, encrypted with a key derived from the client’s password (**Kc**). If successful, the **AS** generates:  
   * A session key encrypted with the client’s secret key (**Kc**).  
   * A **Ticket Granting Ticket (TGT)** containing the session key and other information, encrypted with a secret key known only by the Ticket Granting Server (**Ktgs**). These are sent back to the client.  
3. **Ticket Granting Service Request (TGS-REQ)**: With the **TGT**, the client requests access to a specific service from the **Ticket Granting Server (TGS)**. The **TGS** decrypts the **TGT** with its secret key (**Ktgs**) and validates it. If valid, the **TGS** generates:  
   * A new session key (**Ks**) shared between the client and the target service server.  
   * A **Service Ticket (ST)**, containing the session key and other information, encrypted with the service server’s secret key (**Kserv**). These are sent back to the client.  
4. **Service Access**: The client uses the **Service Ticket (ST)** to access the target server. The server decrypts it with its secret key (**Kserv**) and retrieves the shared session key (**Ks**). If valid, access is granted. From then on, all communication between client and server is secured using **Ks**.

## 2. Wireshark Analysis

### KERBEROS – Domain-joined Client

First, check the Kerberos configuration in Server Manager: Tools > Group Policy Management > Group Policy Objects > Default Domain Controller Policy > Right-click, then Edit (see Image 9). Expand Policy > Windows Settings > Security Settings > Account Policies > Kerberos Policy. We can configure the desired settings on the right side (see Image 10).

![](ressources/TP1/image9-10.png)

**2.1 Directory Creation on AD**

We create a folder on AD (Image 11), share it on the network, and allow the client to access it. This lets us observe the exchange in Wireshark.

![](ressources/TP1/image11.png)

The next step is to access this folder from the client and capture the exchanges in Wireshark, as shown in Images 12 and 13 (installed on the domain controller).

![](ressources/TP1/image12.png)

![](ressources/TP1/image13.png)

### **Explanation of Exchanges (Images 12 and 13):**  {#explanation-of-exchanges-images-12-and-13}

1. **AS-REQ (Authentication Service Request)**  
   • **Source**: Client machine 192.168.9.3  
   • **Destination**: Domain Controller (Key Distribution Center or KDC).  
   • **Description**: The client requests a **Ticket Granting Ticket (TGT)** from the Authentication Service (AS). This request contains credentials such as the username.  

2. **AS-REP (Authentication Service Reply)**  
   • **Source**: KDC 192.168.9.2  
   • **Destination**: Client.  
   • **Description**: The KDC replies with a **TGT** if the credentials are correct. This TGT is encrypted with a key derived from the user’s password.  

3. **TGS-REQ (Ticket Granting Service Request)**  
   • **Source**: Client machine.  
   • **Destination**: KDC.  
   • **Description**: With the TGT, the client requests a service ticket from the TGS, for example, to access a shared folder.  

4. **TGS-REP (Ticket Granting Service Reply)**  
   • **Source**: KDC.  
   • **Destination**: Client.  
   • **Description**: The KDC responds with a valid Service Ticket that the client can use to authenticate with the target server.  

**Interpretation of capture lines:**  
• **AS-REQ/AS-REP lines (e.g., 169, 182)**: Initial authentication phase where the client requests and receives the TGT.  
• **TGS-REQ/TGS-REP lines (e.g., 201, 203)**: Second phase where the client uses the TGT to obtain a Service Ticket.  
• **KRB5KDC_ERR_PREAUTH_REQUIRED (e.g., line 160)**: Error indicating the KDC requires additional information (e.g., cryptographic proof) to continue.

### NTLM – Non-domain Client

In this part, we create a directory named “iwanttoaccess” on AD (see Image 14). This folder will be accessible from a client machine not joined to the domain but on the same network, using the path: *\\\\AD1\\Users\\Administrator\\Downloads\\iwanttoaccess*   
By providing AD credentials from the client machine (see Image 15):  

![](ressources/TP1/image14.png)  
Image 14

![](ressources/TP1/image15.png)  
Image 15

After entering the credentials, we access the directory via the specified path and see our “iwanttoaccess” folder (see Image 16).  

![](ressources/TP1/image16.png)  
Image 16

Opening Wireshark on AD and filtering by ***ntlmssp***, we can see the NTLM exchanges between AD and the non-domain client (see Image 17).  

![](ressources/TP1/image17.png)  
Image 17

### Exchange Explanation

1. **NTLMSSP_NEGOTIATE** (Packets 248 and 289)  
   • First step of the NTLM authentication process.  
   • The client sends a **Session Setup Request** to start an SMB2 session with the server using NTLM.  
   • This message contains supported security capabilities and the requested authentication mechanism (NTLMSSP).  

2. **Session Setup Response (Error: STATUS_MORE_PROCESSING_REQUIRED)** (Packets 249 and 290)  
   • The server replies, asking for more information to complete authentication.  
   • In NTLM, this means sending an **NTLM challenge** (a random value used to verify client authenticity).  

3. **NTLMSSP_AUTH** (Packets 250 and 291)  
   • The client sends its authentication information in response to the NTLM challenge.  
   • This includes a password hash combined with the challenge, plus the **username**.  
   • Usernames are visible in the **Info** column:  
     - CLIENT\\vboxuser in packet 250: *vboxuser* is the username attempting authentication.  
     - dom1\\administrator in packet 291: **dom1** is the AD domain name. **administrator** is the account used.  

**General NTLM authentication process:**  
1. **Negotiate**: Client indicates supported authentication options.  
2. **Challenge**: Server sends a challenge to verify client identity.  
3. **Authenticate**: Client responds with a calculated hash, and the server validates it.

## 3. KRBTGT Account

Resetting the KRBTGT password forces regeneration of new Kerberos tickets for all users, invalidating any tickets obtained with previously compromised security information.  

Here is a script to reset the KRBTGT account password:  

![](ressources/TP1/image_script_reset_pwd.png)

Comment: We create a variable `krbtgt` using **Get-ADUser** to obtain the KRBTGT account in Active Directory. Then with **Set-ADAccountPassword**, we reset the account’s password.  

**Risk**: All tickets are invalidated before the password change, causing a service interruption where users must re-authenticate.  
**Impact**: All users must log in again and obtain a new TGT.  

On AD, we use `klist` to display and clear the Kerberos ticket cache (Image 14). On the client, we request a new TGT with `klist tgt` (Image 15), generating new TGTs.  
***Note**: Even though it issues tickets, the server does not display them in its own Kerberos cache. However, event logs can confirm Kerberos ticket activity.*  

![](ressources/TP1/image18.png)

![](ressources/TP1/image19.png)

Check in event logs that a TGT was generated using:  
`Get-WinEvent -FilterHashtable @{LogName="Security"; ID=4768,4769,4770} | Format-List`  
We can see the time the ticket was issued and the client address (see Images 20 and 21).  

![](ressources/TP1/image20.png)

![](ressources/TP1/image21.png)

## 4. Security Policy

The implemented security policy consists of automatically renewing the KERBEROS password every 180 days (via Task Scheduler).

### 1. Script

   Write the script in notepad and save it. The script must run twice in a row as recommended. Save the file as **“mdpevery180days.ps1”**.  

   ![](ressources/TP1/image22.png)

### 2. Task Scheduler

   Then schedule a task to run every 6 months:  

   ![](ressources/TP1/image_name_for_the_task.png)

   ![](ressources/TP1/image_schedule_six_month.png)

   ![](ressources/TP1/image_the_action.png)

   ![](ressources/TP1/image_select_the_script.png)

   ![](ressources/TP1/image23.png)   

### 3. Implications

1. If an attacker cracks the KRBTGT password, they can generate Golden Tickets to access any resource in the domain undetected, even after user password resets. This can cause a complete domain compromise.  
2. **Incorrect reset effects**:  
   If the KRBTGT password is reset incorrectly (e.g., without performing a double reset), all Kerberos tickets in the domain may be invalidated. Users would need to reconnect and regenerate their tickets, disrupting access to network resources.  

## 5. Authentication Silo

In our current infrastructure, we identified the need to further secure administrative access to servers. To achieve this, we propose:

1. **Authentication silos** to separate privileges by functional category.  
2. **A centralized bastion server** as the single entry point for server administration.  

This solution reduces unauthorized access risks, improves rights management, and facilitates traceability of administrative connections.

### **Solution Benefits**

1. **Enhanced security**:  
   * Limit access rights to only authorized administrators.  
   * Restrict admin connections through the bastion server.  
2. **Increased traceability**:  
   * Centralized logs for all connections and admin actions.  
3. **Simplified management**:  
   * Group admins by functional role (e.g., network, file).  
   * Less confusion and duplication in rights management.  

### **Potential Drawbacks**

1. **Initial complexity**:  
   * Implementing silos and configuring GPOs requires planning and execution effort.  
2. **Single point of failure**:  
   * The bastion server becomes critical. If it fails, server administration could be blocked.  

***Note: For this lab scenario, we use the same password for accounts (not recommended in real environments).***

**5.1 Implementation Steps**  
**Step 1**: Create functional groups  

![](ressources/TP1/image29.png)

**Step 2**: Create administration accounts  

![](ressources/TP1/image_admin_creation.png)


**Step 3**: Creating authentication silos  

![](ressources/TP1/image_silos_creation.png)

**Step 4**: Configure the bastion server  
Enable RDP on the bastion server  

![](ressources/TP1/image44.png)

Create a new GPO  

![](ressources/TP1/image_gpo_rdp_restrinction.png)

This creates a GPO called **Bastion RDP Restrictions**.

Define the administrator groups authorized to connect to the Bastion: Network-Admins, File-Admins, RDP-Admins  

![](ressources/TP1/image_refuse_rdp.png)

Then we block RDP access for other users  

![](ressources/TP1/image28.png)

We create the OU *ServeurBastion*, link the GPO to the bastion server, and apply it with **gpupdate /force**  

![](ressources/TP1/image41.png)

## 6. Other Authentication Methods

1. ### Create a GPO to deny NTLM authentication  {#create-a-gpo-to-deny-ntlm-authentication}

   ### Steps to create a GPO to disable NTLM: {#steps-to-create-a-gpo-to-disable-ntlm}

   Open the Group Policy Management Console (GPMC):  
   * Click Start, type **gpmc.msc**, and press Enter.  
   * In the console, expand your domain, right-click **"Group Policy Objects"**, then select **"New"** to create a new GPO.  

   ![](ressources/TP1/image48.png)

   * Name the GPO: **"Disable NTLM Auth"**  
   
   ![](ressources/TP1/image31.png)

   * Right-click the newly created GPO, then click **"Edit"**.  
   * Navigate to: Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → Security Options  
     Locate the following settings and configure them:  
     **"Network security: Restrict NTLM: Outgoing NTLM traffic to remote servers"** → Set to **"Deny all"** to block all outgoing NTLM connections.  

   ![](ressources/TP1/image25.png)

   ![](ressources/TP1/image_ntlm_refuse_all.png)

     **"Network security: Restrict NTLM: Incoming NTLM traffic"** → Set to **"Deny all"** to block all incoming NTLM connections.  

   ![]![](ressources/TP1/image30.png)  
   ![](ressources/TP1/image9.png)  

After configuring the GPO, we can link it to the entire domain.  
Right-click the domain and select **"Link an Existing GPO"**, then choose the GPO **"Disable NTLM Authentication"**.  

![](ressources/TP1/image40.png)  
![](ressources/TP1/image24.png)  

### 3. Testing with the ldp.exe tool

![](ressources/TP1/image26.png)

Enter the AD IP (or hostname) and port 389 (non-secure).  
![](ressources/TP1/image_ldp_ip_port.png)

After connecting, we see a confirmation of the connection (see image below).  
![](ressources/TP1/image_connect_conf.png)

Then we bind  
![](ressources/TP1/image_link_ldp.png)

We keep the default values (as in the image below).  
![](ressources/TP1/image45.png)  

We are now authenticated as **DOM1\\Administrator**.  
![](ressources/TP1/image27.png)

3. ### Details of the two steps in ldp.exe connection

   **Step one**: Connect to the LDAP server by creating a communication session using its hostname (or IP address) and port. The tool establishes a network link with an LDAP server or an Active Directory domain controller.  
     
   **Step two**: Authenticate the user to the LDAP server. Different methods are possible: simple authentication (username/password) or secure protocols such as Kerberos or NTLM via SASL (Simple Authentication and Security Layer).

4. ### Protocol used

   LDAP is the protocol used. It is used to perform searches, add, or remove objects in the hierarchical structure of the Active Directory directory.  

---

## Conclusion

Throughout this work, we went through several key steps to configure and manage our Active Directory environment on Windows Server virtual machines. Starting with network connectivity issues and static IP configuration, we adjusted firewall settings and considered solutions like DHCP to improve connectivity. Then we successfully joined our machines to the AD domain, fixing credential errors and ensuring the correct information was used.  

Managing accounts in Active Directory allowed us to better understand the creation of authentication silos for different servers and users, while overcoming issues related to specifying DNs. At the same time, we implemented strong security policies, such as regularly resetting the KRBTGT account, thus strengthening domain security. Our efforts with Kerberos diagnostic tools also helped us gain better mastery of authentication in the environment.  

Thanks to these experiences, we significantly improved our skills in managing a Windows Server domain, combining both security and connectivity.
