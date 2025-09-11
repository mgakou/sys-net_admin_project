# Step 1 – Identify and Analyze Critical Vulnerabilities on Wazuh Agents

## Objective

Our goal is to interactively explore how **Wazuh** detects and responds to vulnerabilities on connected agents. We begin by inspecting **critical vulnerabilities** found on two Ubuntu agents (`c1` and `c2`), reviewing them, and documenting their exploitability.

---

## Agents Connected and Reporting

We successfully connected two agents to our Wazuh server:

- `c1` (ID: 002)
- `c2`

All inventory and vulnerability data is being correctly reported to the server. We are ready to analyze detected issues.

![Wazuh Dashboard with Critical CVEs](image/image13.png) 

---

## Dashboard Overview

By accessing the **Vulnerability Detection > c1 > Dashboard** tab, we can see the Wazuh server has detected **19 vulnerabilities** marked as **Critical** for the agent `c1`.

![Inventory tab showing critical pam_krb5 CVEs](image/image14.png) image 14

---

## Vulnerability Inventory

When switching to the **Inventory tab**, we see detailed information about each vulnerability:

- **Agent Name**: `c1`
- **Packages** affected: `sssd`, `sssd-ipa`, `pam_krb5`, `libpam-sss`, etc.
- **Severity**: All marked **Critical**
- **Top CVEs**:
  - [CVE-2023-3326](https://nvd.nist.gov/vuln/detail/CVE-2023-3326) — related to **pam_krb5**
  - CVE-2024-56431 — related to `libtheora0`
  - CVE-2021-3773 — related to `netfilter`

![Inventory tab showing critical pam_krb5 CVEs](image/image15.png) image 15

---

## Case Analysis: `CVE-2023-3326`

This vulnerability concerns the `pam_krb5` module, which can be abused to **authenticate a user by exploiting Kerberos configuration flaws**.

### Evaluation

We performed a manual inspection on agent `c2` to verify if Kerberos was configured and exploitable.

```bash
ls -l /etc/k*
```
![Comman result](image/image16.png) image 16

## CVE-2023-3326 — pam_krb5 vulnerability

- **Affected Package**: pam_krb5
- **Severity**: Critical
- **Description**: The pam_krb5 module may allow attackers to authenticate using crafted Kerberos inputs.
- **Exploitability**: Not exploitable in current configuration
- **Why**:
  - `/etc/krb5.conf` is missing
  - `pam_krb5` is not used in any active PAM service
- **Remediation**: None required at this time
- **Reference**: https://nvd.nist.gov/vuln/detail/CVE-2023-3326
## General Observation on Critical Vulnerabilities

Upon reviewing all critical CVEs flagged by Wazuh on agent `c2`, we observed that:

- **The majority of critical vulnerabilities** relate to `pam_krb5`, `sssd`, or associated packages.
- These packages rely on Kerberos being actively configured on the system.
- However, **no `/etc/krb5.conf` file is present**, and `pam_krb5` is not used in any active PAM service.

### Implication

This means that **most of the reported critical vulnerabilities are not currently exploitable** in the system’s default state.

We retain this conclusion unless:
- A Kerberos configuration is manually introduced,
- Or PAM services are modified to actively use `pam_krb5`.
---


# In progress
