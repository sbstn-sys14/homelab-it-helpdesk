<#
    PC01 - Windows 11 Enterprise -> member of lab.local
    Project 01 · IT Support Home Lab

    Commands I ran on PC01 (logged in with a LOCAL admin account),
    cleaned up and commented. Run in Terminal / PowerShell as Administrator.
    DC01 must be running for steps 3 and 4.
#>

# --- Step 1: rename the PC ---
Get-NetAdapter                                  # note the adapter name, usually "Ethernet"
Rename-Computer -NewName PC01 -Restart

# --- Step 2: static IP + DNS pointing at the domain controller ---
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.10.20 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.10.10

# --- Step 3: verify BEFORE joining ---
ipconfig                                        # expect 192.168.10.20 / 255.255.255.0
nslookup lab.local                              # expect an answer with 192.168.10.10
Test-NetConnection 192.168.10.10 -Port 53       # optional: TcpTestSucceeded : True

# --- Step 4: join the domain (asks for LAB\Administrator's password) ---
Add-Computer -DomainName lab.local -Credential LAB\Administrator -Restart

# After the restart: sign in via "Other user" as LAB\Administrator or LAB\<user>
