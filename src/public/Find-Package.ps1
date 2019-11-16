# Finds packages by given name and version information.
function Find-Package {
	param (
		[string] $Name,
		[string] $RequiredVersion,
		[string] $MinimumVersion,
		[string] $MaximumVersion
	)

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Find-Package'))

	if ($RequiredVersion -eq 'latest') {
		Clear-Variable 'RequiredVersion'
	}

	Find-ChocoPackage -Name $Name -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion
}
