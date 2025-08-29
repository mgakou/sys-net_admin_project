# Cybersecurity and Network Administration Labs

Welcome to my GitHub repository documenting my practical work (labs) and projects in cybersecurity and network administration. This repository serves as a comprehensive resource for showcasing my hands-on experiments and configurations carried out as part of my studies and personal projects.

## Repository Structure

### 1. Folder: Windows
This folder contains labs focused on system administration in Windows environments.\
	•	TP1-Authentification.md:\
Configuration and management of authentication mechanisms in an Active Directory environment.\
	•	TP2-WSUS_Management.md:\
Implementation and management of WSUS (Windows Server Update Services) for centralized Windows updates.\
	•	TP3-Securisation.md:\
Securing an Active Directory domain using PingCastle, managing Kerberos and NTLM policies.

### 2. Folder: network administration system

This folder covers configurations and management of network services in Linux environments.
	•	LDAP Administration.md:
Setting up and configuring an LDAP server for centralized user authentication.
	•	Setting up and managing NFS.md:
Configuring NFS services for secure file sharing between network nodes.

### 3. Folder: Wazuh

This folder contains practical labs focused on host-based security monitoring using the **Wazuh SIEM platform**.

- `installation-and-config.md`: Explain the installation and configuration process of Wazuh server, indexer, dashboard and 2 ubuntu agents
- `agent-vuln-analysis.md`: Detection and analysis of critical vulnerabilities on Wazuh agents (`c1`, `c2`). Manual verification of exploitability, documentation of false positives and remediation guidance.  
  *Covers: CVE analysis, pam_krb5 audit, Kerberos service evaluation, OS package exposure.*

Future work may include:
- Software Composition Analysis (SCA)
- Compliance policy auditing
- Integration with VirusTotal / MITRE ATT&CK

---

## Objectives of the Repository
	•	Documenting my practical skills in cybersecurity and network administration.
	•	Providing concrete examples for setting up network services and security solutions.
	•	Sharing reproducible configurations for professionals and students interested in these fields.

## Prerequisites
	•	Virtualized environments (e.g., VirtualBox, VMware, or other hypervisors).
	•	Operating Systems: Windows Server, Ubuntu.
	•	Tools used: PowerShell, PingCastle, pfSense, Netfilter/nftables, LDAP, and NFS.

## How to Use This Repository
	1.	Clone this repository to your local machine:
 ```
  git clone https://github.com/mgakou/sys-net_admin_project.git
```
	2.	Browse the Markdown files in each folder to follow the step-by-step configuration guides.
	3.	Test the configurations in your own virtual or physical environment.

## Contact

If you have any questions or suggestions, feel free to contact me:
Email: mhmdgakou@gmail.com
