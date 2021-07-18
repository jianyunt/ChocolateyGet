# Mandatory function for the PackageManagement providers. It returns the name of your provider.
function Get-PackageProviderName {
	return 'ChocolateyGet'
}

# Mandatory function for the PackageManagement providers. It initializes your provider before performing any actions.
function Initialize-Provider {
	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Initialize-Provider'))
}

# Defines PowerShell dynamic parameters so that a user can pass in parameters via OneGet to the provider
function Get-DynamicOptions {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='Required by PackageManagement')]
	param (
		[Microsoft.PackageManagement.MetaProvider.PowerShell.OptionCategory]
		$category
	)

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Get-DynamicOptions'))

	switch ($category) {
		Package {
			Write-Output -InputObject (New-DynamicOption -Category $category -Name $script:AdditionalArguments -ExpectedType String -IsRequired $false)
			Write-Output -InputObject (New-DynamicOption -Category $category -Name $script:AcceptLicense -ExpectedType Switch -IsRequired $false)
		}
		Install {
			Write-Output -InputObject (New-DynamicOption -Category $category -Name $script:AdditionalArguments -ExpectedType String -IsRequired $false)
			Write-Output -InputObject (New-DynamicOption -Category $category -Name $script:AcceptLicense -ExpectedType Switch -IsRequired $false)
		}
	}
}
