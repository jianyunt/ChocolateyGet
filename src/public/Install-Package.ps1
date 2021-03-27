# It is required to implement this function for the providers that support install-package.
function Install-Package {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FastPackageReference
	)

	Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Install-Package'))
	Write-Debug -Message ($LocalizedData.FastPackageReference -f $FastPackageReference)

	# If the fast package preference doesnt match the pattern we expect, throw an exception
	if ((-not ($FastPackageReference -match $script:FastReferenceRegex)) -or (-not ($Matches.name -and $Matches.version))) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.FailToInstall -f $FastPackageReference) `
			-ErrorId 'FailToInstall' `
			-ErrorCategory InvalidArgument
	}

	$shouldContinueQueryMessage = ($LocalizedData.InstallPackageQuery -f "Installing", $Matches.name)
	$shouldContinueCaption = $LocalizedData.InstallPackageCaption

	# If the user opts not to install the package, exit from the script
	if (-not (((Get-ForceProperty) -or (Get-AcceptLicenseProperty)) -or $request.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption))) {
		Write-Warning ($LocalizedData.NotInstalled -f $FastPackageReference)
		return
	}

	$chocoParams = @{
		PackageName = $Matches.name
		Version = $Matches.version
		SourceName = $Matches.source
		Force = Get-ForceProperty
	}

	$swid = $(
		if ($script:NativeAPI) {
			# Return SWID from API call to variable
			Invoke-ChocoAPI -Install @chocoParams
		} else {
			$result = Install-ChocoPackage @chocoParams
			if (-not $result) {
				ThrowError -ExceptionName 'System.OperationCanceledException' `
				-ExceptionMessage "The operation failed. Check the Chocolatey logs for more information." `
				-ErrorID 'JobFailure' `
				-ErrorCategory InvalidOperation `
			}
			ConvertTo-SoftwareIdentity -ChocoOutput $result -PackageName $Matches.name -SourceName $Matches.source
		}
	) | Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $Matches.version -ErrorAction SilentlyContinue}

	if (-not $swid) {
		# Choco didn't throw an exception but we also couldn't pull a Software Identity from the output.
		# The output format Choco.exe may have changed from what our regex pattern was expecting.
		Write-Warning ($LocalizedData.UnexpectedChocoResponse -f $FastPackageReference)
	}

	$swid
}
