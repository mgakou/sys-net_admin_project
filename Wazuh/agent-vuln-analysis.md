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
image 13
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
- **Reference**: <https://nvd.nist.gov/vuln/detail/CVE-2023-3326>

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

# SCA - CIS Benchmark

Let's now have a look at the SCA module. The Security Configuration Assessment is a module in Wazuh that compare the security configuration of the endpoints to the security standards. Here the security standards use is the CIS for Center for Internet Security that is a non lucratif organization that developp security standards (CIS Benchmark)
![Comman result](image/image17.png)

We will resolve some of the failed scan with focus on **c1 agent**. Keep in mind that we can have **false positive**

## Issue 1: AppArmor Installation Issue (Wazuh Control 35536)

Wazuh reported that AppArmor was not properly installed, failing compliance check **ID 35536**.

### Problem

Wazuh required both:

- `apparmor` (already installed)
- `apparmor-utils` (missing)

📷 Screenshot of alert:  
![Wazuh Alert](image/image18.png)

---

### Solution Steps

1. **Checked installed packages**  

   ```bash
   dpkg -l | grep apparmor
   ```

   ![Wazuh Alert](image/image19.png)

2. **Installed apparmor-utils**

    ```bash
    sudo apt install apparmor-utils
    ```

    ![Wazuh Alert](image/image20.png)
3. **Verified instimagellation**

    ```bash
    dpkg-query -s apparmor-utils
    ```

    ![Wazuh Alert](image/image21.png)

4. **Confirmation**
  ![Wazuh Alert](image/image22.png)

## Issue 2: GRUB Boot Timeout Not Working

### Problem

The system was booting too quickly, and GRUB was not showing up. Upon inspection, the `GRUB_TIMEOUT` and related parameters were either misconfigured or hidden by default.

### Solution Steps

1. **Edited GRUB Configuration**
   Opened the GRUB file:

   ```bash
   sudo nano /etc/default/grub
   ```

   **Changes made:**
   - Added:
     ```bash
     GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"
     ```

   ![GRUB Config Edit](image/image23.png)

2. **Updated GRUB**
   Applied the changes using:

   ```bash
   sudo update-grub
   ```

   Output confirmed GRUB was successfully regenerated:

   ![GRUB Updated](image/image24.png)

---

You can now reboot and test the GRUB menu during boot:

```bash
sudo reboot
```

## Issue 3: AppArmor Profiles Not Enforced

We enforced all available AppArmor profiles using the `aa-enforce` command:

```bash
sudo aa-enforce /etc/apparmor.d/*
```

![AppArmor Enforce Output](image/image25.png)

We then confirmed that all profiles were active and in **enforce mode** using:

```bash
sudo aa-status
```

![AppArmor Status](image/image26.png)

**Summary**:  
AppArmor is now fully active with all 156 profiles enforced on agent `c1`.
