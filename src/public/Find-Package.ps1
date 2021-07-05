# Finds packages by given name and version information.
function Find-Package {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification='Required by PackageManagement')]
	param (
		[string] $Name
		[string] $RequiredVersion,
		[string] $MinimumVersion,
		[string] $MaximumVersion
	)

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Find-Package'))

	# If the user wants the 'latest' version, don't pass RequiredVersion - it will return the latest available on its own in the range specified
	if ($RequiredVersion -eq 'latest') {
		Clear-Variable 'RequiredVersion'
	}

	Find-ChocoPackage -Name $Name -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion
}
