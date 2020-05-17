# It is required to implement this function for the providers that support UnInstall-Package.
function Uninstall-Package {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FastPackageReference
	)

	Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Uninstall-Package'))
	Write-Debug -Message ($LocalizedData.FastPackageReference -f $FastPackageReference)

	# If the fast package preference doesnt match the pattern we expect, throw an exception
	if ((-not ($FastPackageReference -match $script:FastReferenceRegex)) -or (-not ($Matches.name -and $Matches.version))) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.FailToUninstall -f $FastPackageReference) `
			-ErrorId 'FailToUninstall' `
			-ErrorCategory InvalidArgument
	}

	$chocoParams = @{
		Uninstall = $true
		Package = $Matches.name
		Version = $Matches.version
	}

	$swid = Invoke-Choco @chocoParams

	if (-not $swid) {
		# Invoke-Choco didn't throw an exception but we couldn't pull a Software Identity from the output.
		# The output format Choco.exe may have changed from what our regex pattern was expecting.
		Write-Warning ($LocalizedData.UnexpectedChocoResponse -f $FastPackageReference)
	}

	$swid
}
