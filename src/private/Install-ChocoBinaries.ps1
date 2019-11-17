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

	if (-not $request.ShouldContinue($LocalizedData.InstallChocoExeShouldContinueQuery, $LocalizedData.InstallChocoExeShouldContinueCaption)) {
		ThrowError -ExceptionName 'System.OperationCanceledException' `
			-ExceptionMessage ($LocalizedData.UserDeclined -f "install") `
			-ErrorId 'UserDeclined' `
			-ErrorCategory InvalidOperationException `
			-ExceptionObject $PSEdition
	}

	# install choco based on https://chocolatey.org/install#before-you-install
	try {
		Write-Verbose 'Installing Chocolatey'
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
