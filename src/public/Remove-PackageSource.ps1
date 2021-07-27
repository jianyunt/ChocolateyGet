function Remove-PackageSource {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='ShouldProcess support not required by PackageManagement API spec')]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name
	)

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Remove-PackageSource'))

	[array]$RegisteredPackageSources = Foil\Get-ChocoSource

	# Choco.exe will not error if the specified source name isn't already registered, so we will do it here instead.
	if (-Not ($RegisteredPackageSources.Name -eq $Name)) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.PackageSourceNotFound -f $Name) `
			-ErrorId 'PackageSourceNotFound' `
			-ErrorCategory InvalidArgument
	}

	# Foil will throw an exception if unregistration fails
	Foil\Unregister-ChocoSource -Name $Name
}
