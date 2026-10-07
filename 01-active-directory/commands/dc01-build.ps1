<#
    DC01 build - Windows Server 2022 -> domain controller for lab.local
    Project 01 · IT Support Home Lab

    These are the commands I ran on DC01, in order, recovered from the
    PowerShell history and cleaned up (typos removed, comments added).
    Run in PowerShell as Administrator. The server restarts twice.
#>

# --- Step 1: rename the server (do this BEFORE promoting it to DC) ---
Rename-Computer -NewName DC01 -Restart

# --- Step 2: static IP address ---
Get-NetAdapter                                  # note the adapter name, usually "Ethernet"
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.10.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1   # the DC is its own DNS server
ipconfig                                        # verify: 192.168.10.10 / 255.255.255.0

# --- Step 3: install the Active Directory Domain Services role ---
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Get-WindowsFeature AD-Domain-Services           # verify: [X] = installed
hostname                                        # verify: DC01

# --- Step 4: create the forest and domain lab.local ---
# Prompts for a DSRM (Safe Mode) password, then restarts automatically.
# Do NOT power off the VM during the restart - it can take 10-15 minutes.
Install-ADDSForest -DomainName "lab.local"

# --- Step 5: verify after the restart (log in as LAB\Administrator) ---
Get-ADDomain | Select-Object Name, DNSRoot, PDCEmulator, RIDMaster

# --- Later: re-apply Group Policy after editing the Default Domain Policy ---
gpupdate /force
