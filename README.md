# VAPT Assignment Report

| | |
|---|---|
| **Student Name** | SURENDRA S |
| **USN** | 1DS23CY059 |
| **Section** | A |
| **Assigned VAPT Question** | Perform security configuration assessment of an authorized Windows system and prepare a vulnerability report. |

---

## 1. Objective and Scope

**Objective:** To assess the security configuration of an authorized Windows 10 system, identify exposed services and weaknesses, and recommend remediation.

**Authorized lab target:** Windows 10 virtual machine running on QEMU/KVM, IP address 192.168.100.20. The system is owned by the student and runs on an isolated private network (192.168.100.0/24) with no external access. No other systems were tested.

**Attacker machine:** Kali Linux virtual machine, IP address 192.168.100.10, connected to the same isolated network.

**Tools used:** Nmap 7.99 (with Nmap Scripting Engine), Kali Linux, QEMU/KVM, Windows Command Prompt (`ipconfig`, `netsh`).

---

## 2. VAPT Methodology

- **Reconnaissance:** Confirmed the target was reachable on the lab network and identified its operating system.
- **Scanning:** Scanned the top 1000 TCP ports and detected running services and versions.
- **Vulnerability identification:** Ran the Nmap `vuln` script category against the discovered services.
- **Analysis/validation:** Reviewed the scan output and cross-checked the operating system version on the target itself.
- **Remediation:** Prepared fixes for each issue found.

---

## 3. Practical Execution

### Step 1: Network setup

A private bridge (`br0`, 192.168.100.1/24) was created on the host. Kali was given 192.168.100.10 and the Windows 10 VM was given the static IP 192.168.100.20.

```
netsh interface ip set address "Ethernet" static 192.168.100.20 255.255.255.0
```

![Windows IP configuration and OS version](fig1_windows_ipconfig.png)

*Figure 1: Static IP configured on the Windows 10 target. The Command Prompt banner shows the OS version, 10.0.19045.2965.*

### Step 2: Scan 1, default configuration

```
sudo nmap -Pn -sV -O --top-ports 1000 -T4 --script vuln -oN nmap_report.txt 192.168.100.20
```

![Scan of default configuration](fig2_scan_default.png)

*Figure 2: The host is up, but all 1000 scanned ports are filtered.*

**Result:** With the default Windows Firewall, no service was reachable. This is the secure baseline.

### Step 3: Scan 2, after enabling File and Printer Sharing

To create services to assess, the File and Printer Sharing firewall rules were enabled on the lab VM:

```
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
```

The same scan was repeated:

```
sudo nmap -Pn -sV -O --top-ports 1000 -T4 --script vuln -oN nmap_report2.txt 192.168.100.20
```

![Scan after enabling file sharing](fig3_scan_after_sharing.png)

*Figure 3: Open ports, OS detection and vulnerability script results.*

**Important scan results:**

| Port | State | Service | Version |
|---|---|---|---|
| 135/tcp | open | msrpc | Microsoft Windows RPC |
| 139/tcp | open | netbios-ssn | Microsoft Windows netbios-ssn |
| 445/tcp | open | microsoft-ds | Windows file sharing (SMB) |

**OS detection:** Nmap identified the host as Microsoft Windows 10 (97% confidence). It is a guess, so the exact build was confirmed on the target itself: Windows 10, version 10.0.19045.2965 (Figure 1).

**Script results:**

| Script | Result |
|---|---|
| smb-vuln-ms10-054 | false (not vulnerable) |
| smb-vuln-ms10-061 | Error, could not negotiate an SMB connection |
| samba-vuln-cve-2012-1182 | Error, could not negotiate an SMB connection |

The two scripts that returned errors did not complete, so they neither confirm nor rule out those vulnerabilities.

---

## 4. Vulnerability Analysis

| No. | Vulnerability Name | Affected Component | Severity | Impact | Evidence |
|---|---|---|---|---|---|
| 1 | Outdated, end-of-support operating system | Windows 10 build 19045.2965 | High | The system is no longer receiving security updates and is missing patches released after this build. Known vulnerabilities can remain exploitable. | Figure 1 |
| 2 | SMB service exposed (port 445) | SMB / Microsoft-DS | Medium | Exposes the file-sharing service to the network. SMB is a common target for enumeration, credential attacks and exploits. | Figure 3 |
| 3 | NetBIOS session service exposed (port 139) | NetBIOS-SSN | Medium | Allows enumeration of host and share information and increases the attack surface. | Figure 3 |
| 4 | RPC endpoint mapper exposed (port 135) | Microsoft Windows RPC | Low | Allows remote enumeration of RPC services running on the host. | Figure 3 |

**Observation:** In the default configuration (Figure 2), none of these services were reachable. Findings 2 to 4 appeared after file sharing was enabled, which shows how a single configuration change widens the attack surface.

**Limitations:** SMB signing and SMBv1 status were not verified in this scan. Two SMB vulnerability scripts failed to complete, so those checks are inconclusive.

---

## 5. Remediation

| Vulnerability | Recommended Security Measure | Configuration Fix |
|---|---|---|
| Outdated, end-of-support OS | Install all available updates, or upgrade to a supported Windows version (or enroll in Extended Security Updates) | Settings > Update & Security > Windows Update > Check for updates |
| SMB exposed (445) | Disable File and Printer Sharing when not needed, and restrict SMB to trusted IP addresses | `netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=No` |
| SMB hardening | Disable SMBv1 and require SMB signing | `Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force` and `Set-SmbServerConfiguration -RequireSecuritySignature $true -Force` |
| NetBIOS exposed (139) | Disable NetBIOS over TCP/IP if it is not required | Network adapter > Properties > IPv4 > Advanced > WINS > Disable NetBIOS over TCP/IP |
| RPC exposed (135) | Keep the firewall enabled and block port 135 from untrusted networks | `netsh advfirewall firewall add rule name="Block RPC 135" dir=in action=block protocol=TCP localport=135` |

---

## 6. Conclusion

The Windows 10 system was assessed using Nmap in an isolated lab. In its default configuration, the Windows Firewall blocked all scanned ports. After File and Printer Sharing was enabled, ports 135, 139 and 445 became reachable, and the operating system was found to be an outdated Windows 10 build that is past end of support. Four issues were identified: one High, two Medium and one Low. Keeping the firewall enabled, disabling unneeded sharing services, hardening SMB and keeping the system updated or upgraded will significantly reduce the risk.
