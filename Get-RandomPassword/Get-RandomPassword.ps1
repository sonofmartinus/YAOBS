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
	Version:        0.0.1
	Author:         Richard Martinez
	Blog:			https://sonofmartinus.com
	Creation Date:  1/27/24

.LINK

#>

#Configure API options for passphrase
#baseURI will fetch a passphrase with defaults, to see applicable setings go to: https://makemeapassword.ligos.net/Api
$baseURI = "https://makemeapassword.ligos.net/api/v1/passphrase/plain"
#Configure URI flags
#Array, first value is boleaan to trigger if, second value is flag for passphrase configuration, thrid value is for integer value
$uriFlags = @{}
$uriFlags["wc"] = @($true, "wc", "2")
$uriFlags["pc"] = @($true, "pc", "1")
$uriFlags["sp"] = @($true, "sp", "t")
$uriFlags["minCh"] = @($true, "minCh", "20")
$uriFlags["whenNum"] = @($true, "whenNum", "Anywhere")
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
	$modifiedUri = $baseUri
	if ($queryParams.Length -gt 0) {
    $queryString = $queryParams -join "&"
    $modifiedUri += "?$queryString"
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
