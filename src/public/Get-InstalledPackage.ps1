# Returns the packages that are installed.
function Get-InstalledPackage {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification='Version may not always be used, but are still required')]
	[CmdletBinding()]
	param (
		[Parameter()]
		[string]
		$Name,

		[Parameter()]
		[string]
		$RequiredVersion,

		[Parameter()]
		[string]
		$MinimumVersion,

		[Parameter()]
		[string]
		$MaximumVersion
	)

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Get-InstalledPackage'))

	# If a user wants to check whether the latest version is installed, first check the repo for what the latest version is
	if ($RequiredVersion -eq 'latest') {
		$RequiredVersion = $(Find-ChocoPackage -Name $Name).Version
	}

	$chocoParams = @{
		# Remove this flag after the release of Chocolatey v2
		LocalOnly = $true
		AllVersions = $true
	}

	# If a user provides a name without a wildcard, include it in the search
	# This provides wildcard search behavior for locally installed packages, which Chocolatey lacks
	if ($Name -And -Not ([WildcardPattern]::ContainsWildcardCharacters($Name))) {
		$chocoParams.Add('Name',$Name)
	}

	# Convert the PSCustomObject output from Foil into PackageManagement SWIDs, then filter results by any name and version requirements
	# We apply additional package name filtering when using wildcards to make Chocolatey's wildcard behavior more PowerShell-esque
	Foil\Get-ChocoPackage @chocoParams | ConvertTo-SoftwareIdentity |
		Where-Object {-Not $Name -Or ($_.Name -Like $Name)} |
			Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}
}
