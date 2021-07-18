# Make sure the SWID passed to us has a valid version in the range requested by the user
function Test-PackageVersion {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory=$true)]
		[Microsoft.PackageManagement.MetaProvider.PowerShell.SoftwareIdentity]
		$Package,

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

	# User didn't have any version requirements
	if (-Not ($RequiredVersion -Or $MinimumVersion -Or $MaximumVersion)) {
		return $true
	}

	[System.Version]$version = $Package.Version.TrimStart('v')

	# User specified a specific version - it either matches or it doesn't
	if ($RequiredVersion) {
		return $Version -eq [System.Version]$RequiredVersion
	}

	# Conditional filtering of the version based on optional minimum and maximum version requirements
	(-Not $MinimumVersion -Or (
		$version -ge [System.Version]$MinimumVersion
	)) -And (-Not $MaximumVersion -Or (
		$version -le [System.Version]$MaximumVersion
	))
}
