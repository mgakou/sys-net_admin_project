# Infrastructure, Cloud & Cybersecurity Labs

This repository documents my hands-on work in **systems administration, networking, cloud infrastructure and cybersecurity**.

It brings together practical labs, technical implementations, security experiments and troubleshooting work carried out in controlled environments.

The objective is not only to document configuration procedures, but also to understand the underlying technologies, test their behaviour, identify failures and document the results.

---

## Areas Covered

- ☁️ **Cloud & AWS**
- 🛡️ **SIEM & Security Monitoring**
- 🌐 **Network Administration & Security**
- 🪟 **Windows Server & Active Directory**
- 🐧 **Linux System Administration**
- 🔐 **Cryptography & Security**
- 🔎 **Security Auditing & Hardening**

---

## ☁️ AWS Cloud Labs

Practical AWS labs focused on understanding cloud infrastructure through hands-on experimentation.

### EC2, ENI & Security Groups

Hands-on lab covering the relationship between EC2 instances, network interfaces and AWS network security.

Topics include:

- EC2 instance networking
- AWS Regions and Availability Zones
- Elastic Network Interfaces (ENI)
- Multiple ENIs attached to a single EC2 instance
- Private and public IPv4 addressing
- Elastic IP association
- Security Groups attached to ENIs
- Multiple Security Groups per interface
- Security Group references
- Connectivity testing and troubleshooting
- EC2 Placement Groups
- EC2 Stop vs Hibernate behaviour

The lab also includes screenshots and tests showing how AWS networking concepts appear both in the AWS console and directly inside the Linux operating system.

📁 `AWS/EC2-ENI-Security-Groups/`

More AWS labs will progressively cover IAM, VPC networking, load balancing and other cloud infrastructure concepts.

---

## ⭐ Featured Project — Multi-Client SOC with Wazuh

📁 `Wazuh/soc-multi-clients/`

Design and implementation of a **multi-client SOC architecture using Wazuh**, based on an MSSP-style use case.

The objective is to monitor several independent clients from a single Wazuh platform while ensuring that each client can access **only its own security data**, without deploying a separate SIEM stack for every customer.

### Key features

- Automatic creation of per-client indices using a modified ingest pipeline
- Least-privilege RBAC
- Client data isolation
- Isolation validation tests
- Unauthorized cross-client access returns HTTP `403`
- Segmented laboratory environment using pfSense
- WireGuard access for analysts
- Client onboarding automation
- Pipeline patching scripts
- Routing and isolation auditing
- Technical documentation in French

This project focuses particularly on **multi-tenancy, data isolation and access-control design in a SOC environment**.

---

# Repository Structure

## 🛡️ Wazuh

Practical work around the Wazuh SIEM/XDR platform.

Topics include:

- Wazuh server, indexer and dashboard deployment
- Agent installation and configuration
- Multi-client SOC architecture
- Agent hardening
- Vulnerability detection and analysis
- CVE investigation
- False-positive validation
- Kerberos and PAM security analysis
- Security monitoring and remediation

Main documents and projects include:

- `soc-multi-clients/`
- `installation-and-config.md`
- `Hardening Agent.md`
- `agent-vuln-analysis.md`

Future work may include:

- Security Configuration Assessment (SCA)
- Compliance auditing
- MITRE ATT&CK mapping
- Threat intelligence integrations

---

## 🪟 Windows

Labs focused on Windows Server administration and Active Directory security.

### Topics

- Active Directory authentication
- Kerberos and NTLM
- Windows Server Update Services (WSUS)
- Active Directory security assessment
- Domain hardening
- PingCastle auditing

Main labs:

- `TP1-Authentification.md`
- `TP2-WSUS_Management.md`
- `TP3-Securisation.md`

---

## 🌐 Network Administration System

Linux network and infrastructure administration labs.

Topics include:

- LDAP deployment and administration
- Centralized authentication
- NFS configuration
- Network file sharing
- Linux service administration
- Access-control configuration

Main labs include:

- `LDAP Administration.md`
- `Setting up and managing NFS.md`

---

## 🔎 Lynis

Security auditing and hardening experiments using **Lynis**.

The objective is to evaluate Linux system configurations, identify weaknesses and understand practical hardening recommendations.

---

## 📊 Graylog

Experiments around centralized log management and analysis using **Graylog**.

The labs explore log collection, centralization and analysis in security and system administration environments.

---

## 🔐 Cryptography

Practical work and experiments related to cryptographic concepts and security mechanisms.

---

# Lab Philosophy

The projects in this repository follow a practical approach:

**Understand → Deploy → Test → Break → Troubleshoot → Document**

The goal is not simply to reproduce commands from documentation.

For each technology, I try to understand:

- what problem it solves;
- how the components interact;
- what happens when the configuration is incorrect;
- how to troubleshoot failures;
- what security implications exist;
- how the behaviour can be verified experimentally.

Screenshots, command outputs and configuration examples are therefore used as **technical evidence of the experiments**, rather than simply for illustration.

---

# Technical Environment

Depending on the lab, the environments and technologies used include:

### Cloud

- Amazon Web Services (AWS)
- EC2
- ENI
- Security Groups
- Elastic IP
- IAM
- VPC

### Virtualization

- VMware / ESXi
- VirtualBox
- UTM

### Systems

- Amazon Linux
- Ubuntu
- Kali Linux
- Windows Server

### Networking & Security

- pfSense
- WireGuard
- Netfilter / nftables
- LDAP
- NFS

### Security Monitoring

- Wazuh
- Graylog
- Lynis
- PingCastle

### Administration & Automation

- Bash
- PowerShell
- Python

---

# Repository Objectives

This repository serves several purposes:

- document my practical learning in infrastructure and cybersecurity;
- demonstrate hands-on system and network administration skills;
- experiment with cloud infrastructure and security concepts;
- document troubleshooting processes and lessons learned;
- build reproducible technical labs;
- maintain a technical knowledge base that evolves with my experience.

The repository is continuously updated as new labs and projects are completed.

---

# Getting Started

Clone the repository:

```bash
git clone https://github.com/mgakou/sys-net_admin_project.git
```

Enter the repository:

```bash
cd sys-net_admin_project
```

Then browse the relevant directory depending on the technology or lab you want to explore.

Each major project contains its own documentation, configuration examples and, where relevant, screenshots of the experiments.

---

# Disclaimer

All security experiments documented in this repository are performed in **controlled laboratory environments** for educational and research purposes.

Configurations should be reviewed and adapted before being used in production environments.

---

# Contact

For technical discussions, questions or suggestions:

**Email:** mhmdgakou@gmail.com
