function Install-ChocoBinaries {
	[CmdletBinding()]
	[OutputType([bool])]

	param (
	)

	if ($PSEdition -Match 'Core') {
		ThrowError -ExceptionName 'System.NotSupportedException' `
			-ExceptionMessage ($LocalizedData.ChocoUnSupportedOnCoreCLR -f $script:ProviderName) `
			-ErrorId 'ChocoUnSupportedOnCoreCLR' `
			-ErrorCategory NotImplemented `
			-ExceptionObject $PSEdition
	}

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
