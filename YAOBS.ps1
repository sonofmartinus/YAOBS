<#
.SYNOPSIS
	Yet Another On Board Script

.DESCRIPTION
	This is a on-prem AD onboarding script. That creates user account and adds to necessary groups and then emails their manager.

.EXAMPLE


.EXAMPLE


.NOTES
	Version:        0.0.3
	Author:         Richard Martinez
	Blog:			https://sonofmartinus.com
	Creation Date:  1/1/24

.LINK

#>
Import-Module "$PSScriptRoot\Send-MailToManager\Send-MailToManager.ps1"
Import-Module "$PSScriptRoot\Get-RandomPassword\Get-RandomPassword.ps1"

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$ADUsers,
	[Parameter()]
	[string]$adminUPN
)

#Get MOERA from Environment
if ($PSBoundParameters.ContainsKey('adminUPN')){
	Connect-ExchangeOnline -UserPrincipalName $adminUPN
}
else {
	Connect-ExchangeOnline
}
$moera = Get-AcceptedDomain | Select-Object Name,DomainType

#Mail parameters to pass to Send-MailMessage function
$htmlTemplatePath = "$PSScriptRoot\template.html"
$mailParams = @{
    SmtpServer                 =  $moera
    Port                       = '25'
    UseSSL                     =  $true
    From                       =  $from
    To                         =  $manager
	CC                         =  $cc
    Subject                    = "New User Onboarded: $DisplayName"
    Body                       =  Get-Content -Path $htmlTemplatePath | Out-String
    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
}

# Import active directory module for running AD cmdlets
Import-Module ActiveDirectory

Add-Type -TypeDefinition @"
using System;

public class PasswordGenerator
{
    private static string[] animals = new string[] { "lion", "tiger", "bear", "wolf", "fox", "eagle", "hawk", "shark", "whale", "dolphin", "elephant", "giraffe", "zebra", "hippo", "rhino", "penguin", "koala", "kangaroo", "panda", "monkey", "gorilla", "leopard", "cheetah", "crocodile", "platypus" };
    private static string[] places = new string[] { "river", "park", "forest", "desert", "mountain", "valley", "ocean", "beach", "city", "village", "island", "peninsula", "canyon", "lake", "pond", "swamp", "jungle", "savannah", "tundra", "hill", "plain", "cave", "cliff", "volcano", "waterfall" };
    private static Random random = new Random();

    public static string GeneratePassword()
    {
        string animal = animals[random.Next(animals.Length)];
        string place = places[random.Next(places.Length)];
        int number = random.Next(100);  // Generate a random number less than 100

        return animal + '.' + place + number.ToString();
    }
}
"@

# Define UPN
$domainName = (Get-ADDomain).Name

# Define the group(s) to add users to
$groups = "Users", "Employees"

#Define hash with department key which will make sure users are added to proper security/distribution groups based on their department
$DepartmentGroups = @{}
$DepartmentGroups["IT"] = @("IT Users", "IT Admins", "Another IT Group")
$DepartmentGroups["HR"] = @("HR Users", "Another HR Group")

#Define hash with OU's for each specific department
$DepartmentOUs = @{}
$DepartmentOUs["IT"] = @("OU=")
$DepartmentOUs["HR"] = @("OU=")
$DepartmentOUs["Finance"] = @("OU=")
$DepartmentOUs["Marketing"] = @("OU=")


# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {
    # Read user data from each field in each row and assign the data to a variable as below
    $username = $User.username
    $firstname = $User.legalfirstname
    $lastname = $User.legallastname
    $pfirstname = $User.prefferedfirstname
    $plastname = $User.prefferedlastname
    $email = $User.email
    $jobtitle = $User.primarytitle
    $company = $User.company
    $department = $User.department
    $description = $User.description
    $manager = $User.manager

    # Generate a password for the user
    #$password = [PasswordGenerator]::GeneratePassword()
	$password = Get-RandomPassword

	# Set user OU based on user department
	if ($DepartmentOUs.ContainsKey($department)){
		$departmentOU = $departmentOUs[$department]
	}

    # Check to see if the user already exists in AD
    if (Get-ADUser -Filter "SamAccountName -eq '$username'") {
        # If user does exist, give a warning
        Write-Warning "A user account with username $username already exists in Active Directory."
    }
    else {
        # User does not exist then proceed to create the new user account
        # Account will be created in the OU provided by the $OU variable read from the CSV file
        New-ADUser `
            -SamAccountName $username `
            -UserPrincipalName "$username@$domainName" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Enabled $True `
            -DisplayName "$pfirstname $plastname" `
            -Path $departmentOU `
            -Company $company `
            -EmailAddress $email `
            -Title $jobtitle `
            -Department $department `
            -Manager $manager `
            -Description $description `
            -AccountPassword (ConvertTo-SecureString -AsPlainText $password -Force) `
            -ChangePasswordAtLogon $False

        # If user is created, show message.
        Write-Host "The user account $username is created." -ForegroundColor Cyan

        # Add the user to the specified groups
        foreach ($group in $groups) {
            Add-ADGroupMember -Identity $group -Members $username
        }

        # Add user to additional groups based on department
        if ($DepartmentGroups.ContainsKey($department)) {
            $departmentGroup = $DepartmentGroups[$department]
            Add-ADGroupMember -Identity $departmentGroup -Members $username
        }

        #Check if the user exists
        $userExists = Get-ADUser -Filter { SamAccountName -eq $username } -Properties DisplayName, Manager
        if ($userExists) {
            $DisplayName = $userExists.DisplayName
            $manager = (Get-ADUser $userExists.Manager -Properties EmailAddress).EmailAddress

            if ($DisplayName -and $manager) {
                Send-MailToManager $mailParams
            }
            else {
                Write-Output "Display Name or Manager's Email Address is not set for user $username."
            }
        }
        else {
            Write-Output "User $username does not exist."
        }
    }
}

Read-Host -Prompt "Press Enter to exit"
