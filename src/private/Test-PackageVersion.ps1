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
	if (-not ($RequiredVersion -or $MinimumVersion -or $MaximumVersion)) {
		return $true
	}

	[System.Version]$version = $Package.Version.TrimStart('v')

	# User specified a specific version - it either matches or it doesn't
	if ($RequiredVersion) {
		return $Version -eq [System.Version]$RequiredVersion
	}

	# Conditional filtering of the version based on optional minimum and maximum version requirements
	# Would prefer to express this with ternary operators, but that's not supported with PowerShell 5.1
	$null -ne (
		$version | Where-Object {-Not $MinimumVersion -or ($_ -ge [System.Version]$MinimumVersion)} |
			Where-Object {-Not $MaximumVersion -or ($_ -le [System.Version]$MaximumVersion)}
	)
}
