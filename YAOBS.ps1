<#
.SYNOPSIS
	Yet Another On Board Script

.DESCRIPTION
	This script will make an API request to https://makemeapassword.ligos.net/api and acquire a passphrase using their API. Passphrase
	parameters are preset for this URI.

.EXAMPLE
	.\Get-RandomPassword.ps1 in console
	Then call function Get-RandomPassword

.EXAMPLE


.NOTES
	Version:        0.0.1
	Author:         Richard Martinez
	Blog:			https://sonofmartinus.com
	Creation Date:  1/1/24

.LINK

#>
param(
    [Parameter(Mandatory=$true)]
    [hashtable]$ADUsers
)

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
$UPN = "UPN"

# Define the group(s) to add users to
$groups = "Users", "Employees"

# Define the group(s) to add users to based on department
# Changed to dynamic hastable
$DepartmentGroups = @{}
$DepartmentGroups["IT"] = @("IT Users", "IT Admins", "Another IT Group")
$DepartmentGroups["HR"] = @("HR Users", "Another HR Group")
# Add more departments and associated groups as needed

# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {
    # Read user data from each field in each row and assign the data to a variable as below
    $username = $User.username
    $firstname = $User.legalfirstname
    $lastname = $User.legallastname
    $pfirstname = $User.prefferedfirstname
    $plastname = $User.prefferedlastname
    $OU = $User.ou #This field refers to the OU the user account is to be created in
    $email = $User.email
    $jobtitle = $User.primarytitle
    $company = $User.company
    $department = $User.department
    $description = $User.description
    $manager = $User.manager
    $homepath = ""
    $mslicense = $User.licensegroup

    # Generate a password for the user
    $password = [PasswordGenerator]::GeneratePassword()

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
            -UserPrincipalName "$username@$UPN" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Enabled $True `
            -DisplayName "$pfirstname $plastname" `
            -Path $OU `
            -Company $company `
            -EmailAddress $email `
            -Title $jobtitle `
            -Department $department `
            -Manager $manager `
            -Description $description `
            -homeDrive "H:" `
            -homeDirectory "$homepath$username" `
            -AccountPassword (ConvertTo-SecureString -AsPlainText $password -Force) `
            -ChangePasswordAtLogon $False

        # If user is created, show message.
        Write-Host "The user account $username is created." -ForegroundColor Cyan

        # Add the user to the specified groups
        foreach ($group in $groups) {
            Add-ADGroupMember -Identity $group -Members $username
        }

        # Add the user to the group specified by the $mslicense variable
        Add-ADGroupMember -Identity $mslicense -Members $username

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
                $subject = "New User Onboarded: $DisplayName"
                $body =
@"
<html>
<body>
<p>A new user <b>$DisplayName</b> has been onboarded, their username is: <b>$username</b>.</p>
<p>Their temporary network password is: <b>$password</b></p>
<p style='color:red; font-style:italic;'>#Do not reply to this email message as it is only informational, we are not requesting any further action or information from you at this time.</p>
</body>
</html>
"@

                $cc = "email"
                Send-MailMessage -To $manager -From "email" -CC $cc -Subject $subject -Body $body -BodyAsHTML -SmtpServer "Server"
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
