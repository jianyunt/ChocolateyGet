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

	if ((-not ($FastPackageReference -match $script:FastReferenceRegex)) -or (-not ($Matches.name -and $Matches.version))) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.FailToUninstall -f $FastPackageReference) `
			-ErrorId 'FailToUninstall' `
			-ErrorCategory InvalidArgument
	}

	$chocoParams = @{
		Uninstall = $true
		Package = $Matches.name
	}

	if ($request.Options.ContainsKey($script:AllVersions)) {
		$chocoParams.Add('AllVersions',$true)
	} else {
		$chocoParams.Add('Version',$Matches.version)
	}

	Invoke-Choco @chocoParams | ConvertTo-SoftwareIdentity -RequestedName $Matches.name -Source $Matches.source -Verbose
}
