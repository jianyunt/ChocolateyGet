# Returns the packages that are installed.
function Get-InstalledPackage {
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

	$ValidationResult = Confirm-VersionParameters -Name $Name -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion

	if (-not $ValidationResult) {
		# Return now as the version validation failed already
		return
	}

	# If a user wants to check whether the latest version is installed, first check the repo for what the latest version is
	if ($RequiredVersion -eq 'latest') {
		$sid = Find-ChocoPackage -Name $Name
		$RequiredVersion = $sid.Version
	}

	$chocoParams = @{
		Search = $true
		LocalOnly = $true
		AllVersions = $true
	}

	# If a user provides a name without a wildcard, include it in the search
	if ($Name -and -not (Test-WildcardPattern -Name $Name)) {
		$chocoParams.Add('Package',$Name)
	}

	Invoke-Choco @chocoParams |
		ConvertTo-SoftwareIdentity -RequestedName $Name -Verbose |
			Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}
}
