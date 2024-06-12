<#
.SYNOPSIS
	Get-RandomPassword function

.DESCRIPTION
	This script will make an API request to https://makemeapassword.ligos.net/api and acquire a passphrase using their API. Passphrase
	parameters are preset for this URI.

.EXAMPLE
	.\Get-RandomPassword.ps1 in console
	Then call function Get-RandomPassword

.EXAMPLE


.NOTES
	Version:        0.0.2
	Author:         Richard Martinez
	Blog:			https://sonofmartinus.com
	Creation Date:  1/27/24

.LINK

#>

[CmdletBinding()]
param (
	[Parameter()]
	[switch[]]$wc = @("wc", "2"),
	[Parameter()]
	[switch]$pc
)
#Configure API options for passphrase
#baseURI will fetch a passphrase with defaults, to see applicable setings go to: https://makemeapassword.ligos.net/Api
$baseURI = "https://makemeapassword.ligos.net/api/v1/passphrase/plain"
#Configure URI flags
#Array, first value is boleaan to trigger if, second value is flag for passphrase configuration, thrid value is for integer value
$uriFlags = @{}
$uriFlags["wc"] = $wc # wc - Word Count | range 1-16
$uriFlags["pc"] = @($true, "pc", "1") # pc - Count of passphrases | range 1-50
$uriFlags["sp"] = @($true, "sp", "t") # sp - Include space between words | boolean
$uriFlags["minCh"] = @($true, "minCh", "20") # minCH - Minimum Character length | 1-9999
$uriFlags["whenNum"] = @($true, "whenNum", "Anywhere") # whenNum - Where to add number - Never | StartOfWord | EndOfWord | StartOrEndOfWord | EndOfPhrase | Anywhere
$uriFlags["nums"] = @($true, "nums", "1")
$uriFlags["whenUp"] = @($true, "whenUp", "Anywhere")
$uriFlags["ups"] = @($true, "ups", "1")

$queryParams = @()

foreach ($key in $uriFlags.Keys) {

	if ($uriFlags[$key][0]) {
		$queryParams += "$($uriFlags[$key][1])=$($uriFlags[$key][2])"
	}
}

	#Construct URI
	$modifiedURI = $baseURI
	if ($queryParams.Length -gt 0) {
    $queryString = $queryParams -join "&"
    $modifiedURI += "?$queryString"
	}

	elseif ($null -eq $modifiedURI) {
		$modifiedURI = $baseURI
	}


function Get-RandomPassword {
	try {
		$invoke= Invoke-RestMethod -Uri $modifiedURI
		$passphrase= $invoke -replace ' ', '.'
		Write-Host $passphrase
	}
	catch {
		<#Do this if a terminating exception happens#>
		Write-Error "Error Calling API: $_"
	}

}
