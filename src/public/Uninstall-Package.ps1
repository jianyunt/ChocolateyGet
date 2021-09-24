# It is required to implement this function for the providers that support Uninstall-Package.
function Uninstall-Package {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification='Required by PackageManagement')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FastPackageReference
	)

	Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Uninstall-Package'))
	Write-Debug -Message ($LocalizedData.FastPackageReference -f $FastPackageReference)

	# If the fast package reference doesnt match the pattern we expect, throw an exception
	if ((-Not ($FastPackageReference -Match $script:FastReferenceRegex)) -Or (-Not ($Matches.name -And $Matches.version))) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.FailToUninstall -f $FastPackageReference) `
			-ErrorId 'FailToUninstall' `
			-ErrorCategory InvalidArgument
	}

	$chocoParams = @{
		Name = $Matches.name
		Version = $Matches.version
		Force = $request.Options.ContainsKey($script:Force)
		RemoveDependencies = $request.Options.ContainsKey($script:RemoveDependencies)
	}

	# Convert the PSCustomObject output from Foil into PackageManagement SWIDs, then validate what Chocolatey installed matched what we requested
	$swid = $(
		$result = Foil\Uninstall-ChocoPackage @chocoParams
		# If Foil didn't return anything, something went wrong and we need to throw our own exception
		if (-Not $result) {
			ThrowError -ExceptionName 'System.OperationCanceledException' `
			-ExceptionMessage $LocalizedData.ChocoFailure`
			-ErrorID 'JobFailure' `
			-ErrorCategory InvalidOperation `
		}
		ConvertTo-SoftwareIdentity -InputObject $result -Source $Matches.source
	)

	if (-Not $swid) {
		# Foil returned something, but not in the format we expected. Something is amiss.
		Write-Warning ($LocalizedData.UnexpectedChocoResponse -f $FastPackageReference)
	}

	$swid
}
