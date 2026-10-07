<#
    Helpdesk tasks - PowerShell equivalents
    Project 01 · IT Support Home Lab

    In the lab I did these tasks in the GUI (Active Directory Users and Computers
    and Group Policy Management). This file shows how the same work is done in
    PowerShell. It is a reference and a preview of Project 05 (automation).

    Run on DC01 as a domain admin. Passwords are never written in the script:
    Read-Host -AsSecureString asks for them at runtime.
#>

$Base = "OU=Firma,DC=lab,DC=local"

# ============================================================
# Company structure: OUs
# ============================================================
New-ADOrganizationalUnit -Name "Firma" -Path "DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
foreach ($ou in "Contabilitate", "IT", "Vanzari", "Plecati") {
    New-ADOrganizationalUnit -Name $ou -Path $Base -ProtectedFromAccidentalDeletion $true
}

# ============================================================
# REQ-0001 · Onboarding: new user + group membership
# ============================================================
New-ADUser -Name "Ana Pop" -GivenName "Ana" -Surname "Pop" `
    -SamAccountName "ana.pop" -UserPrincipalName "ana.pop@lab.local" `
    -Path "OU=Contabilitate,$Base" `
    -AccountPassword (Read-Host -AsSecureString "Temporary password") `
    -ChangePasswordAtLogon $true -Enabled $true

New-ADGroup -Name "GRP_Contabilitate" -GroupScope Global -GroupCategory Security `
    -Path "OU=Contabilitate,$Base"
Add-ADGroupMember -Identity "GRP_Contabilitate" -Members "ana.pop", "ion.ionescu"

# ============================================================
# REQ-0002 · Password reset (after verifying the caller's identity!)
# ============================================================
Set-ADAccountPassword -Identity "maria.georgescu" -Reset `
    -NewPassword (Read-Host -AsSecureString "Temporary password")
Set-ADUser -Identity "maria.georgescu" -ChangePasswordAtLogon $true

# ============================================================
# INC-0003 · Account lockout
# ============================================================
# Policy: lock after 5 bad attempts, for 30 minutes
Set-ADDefaultDomainPasswordPolicy -Identity "lab.local" `
    -LockoutThreshold 5 -LockoutDuration "00:30:00" -LockoutObservationWindow "00:30:00"

# Who is locked out right now?
Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, LastLogonDate

# Unlock
Unlock-ADAccount -Identity "ion.ionescu"

# ============================================================
# REQ-0004 · Offboarding: disable, document, remove groups, move
# ============================================================
$Leaver = "andrei.popa"

Disable-ADAccount -Identity $Leaver
Set-ADUser -Identity $Leaver -Description "Left company $(Get-Date -Format yyyy-MM-dd) - HR request"

Get-ADPrincipalGroupMembership -Identity $Leaver |
    Where-Object Name -ne "Domain Users" |
    ForEach-Object { Remove-ADGroupMember -Identity $_ -Members $Leaver -Confirm:$false }

Get-ADUser -Identity $Leaver | Move-ADObject -TargetPath "OU=Plecati,$Base"

# ============================================================
# Report: everyone in the company, where they are, who is disabled
# ============================================================
Get-ADUser -Filter * -SearchBase $Base -Properties Description |
    Select-Object Name, Enabled, Description, DistinguishedName |
    Format-Table -AutoSize
