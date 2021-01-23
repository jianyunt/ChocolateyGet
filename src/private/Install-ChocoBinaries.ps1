function Install-ChocoBinaries {
	[CmdletBinding()]
	[OutputType([bool])]

	param (
	)

	# If the user opts not to install Chocolatey, throw an exception
	if (-not (((Get-ForceProperty) -or (Get-AcceptLicenseProperty)) -or $request.ShouldContinue($LocalizedData.InstallChocoExeShouldContinueQuery, $LocalizedData.InstallChocoExeShouldContinueCaption))) {
		ThrowError -ExceptionName 'System.OperationCanceledException' `
			-ExceptionMessage ($LocalizedData.UserDeclined -f "install") `
			-ErrorId 'UserDeclined' `
			-ErrorCategory InvalidOperationException `
			-ExceptionObject $PSEdition
	}

	# install choco based on https://chocolatey.org/install#before-you-install
	try {
		Write-Verbose 'Installing Chocolatey'

		# chocolatey.org requires TLS 1.2 (or newer) ciphers to establish a connection.
		# Older versions of PowerShell / .NET are opinionated about which ciphers to support, while newer versions default to whatever ciphers the OS supports.
		# If .NET isn't falling back on the OS defaults, explicitly add TLS 1.2 as a supported cipher for this session, otherwise let the OS take care of it.
		# https://docs.microsoft.com/en-us/security/solving-tls1-problem#update-windows-powershell-scripts-or-related-registry-settings
		if (-not ([Net.ServicePointManager]::SecurityProtocol -eq [Net.SecurityProtocolType]::SystemDefault)) {
			[Net.ServicePointManager]::SecurityProtocol = ([Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12)
		}
		# Have to keep choco pinned to 0.10.13 due to https://github.com/chocolatey/choco/issues/1843 - should be fixed in 0.10.16, which is still in beta
		# https://docs.chocolatey.org/en-us/choco/setup#installing-a-particular-version-of-chocolatey
		$env:chocolateyVersion = '0.10.13'
		Invoke-WebRequest 'https://chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression > $null
	} catch {
		ThrowError -ExceptionName 'System.OperationCanceledException' `
			-ExceptionMessage $LocalizedData.FailToInstallChoco `
			-ErrorID 'FailToInstallChoco' `
			-ErrorCategory InvalidOperation `
			-ExceptionObject $job
	}
	Get-ChocoPath
}
