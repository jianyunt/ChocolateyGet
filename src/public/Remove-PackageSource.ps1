function Remove-PackageSource {
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name
	)

	Write-Debug ('Remove-PackageSource')

	[array]$RegisteredPackageSources = Foil\Get-ChocoSource

	# Choco.exe will not error if the specified source name isn't already registered, so we will do it here instead.
	if (-not ($RegisteredPackageSources.Name -eq $Name)) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.PackageSourceNotFound -f $Name) `
			-ErrorId 'PackageSourceNotFound' `
			-ErrorCategory InvalidArgument
	}

	# Choco will throw an exception if unregistration fails
	Foil\Unregister-ChocoSource -Name $Name
}
