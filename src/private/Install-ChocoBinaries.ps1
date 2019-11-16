function Install-ChocoBinaries {
	[CmdletBinding()]
	[OutputType([bool])]

	param (
	)

	if ($PSEdition -Match 'Core') {
		Write-Error ($LocalizedData.ChocoUnSupportedOnCoreCLR -f $script:ProviderName)
		return $false
	}

	if (-not $request.ShouldContinue($LocalizedData.InstallChocoExeShouldContinueQuery, $LocalizedData.InstallChocoExeShouldContinueCaption)) {
		Write-Error ($LocalizedData.UserDeclined -f "install")
		return $false
	}

	# install choco based on https://chocolatey.org/install#before-you-install
	try {
		Write-Verbose 'Installing Chocolatey'
		Invoke-WebRequest 'https://chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression  > $null
	} catch {
		Throw $error[0]
	}

	Get-ChocoPath
}
