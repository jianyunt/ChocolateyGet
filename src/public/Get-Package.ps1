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

	# Throw an error if provided version arguments don't make sense
	Confirm-VersionParameters -Name $Name -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion

	# If a user wants to check whether the latest version is installed, first check the repo for what the latest version is
	if ($RequiredVersion -eq 'latest') {
		$sid = Find-ChocoPackage -Name $Name
		$RequiredVersion = $sid.Version
	}

	$chocoParams = @{
		LocalOnly = $true
		AllVersions = $true
	}

	# If a user provides a name without a wildcard, include it in the search
	if ($Name -and -not (Test-WildcardPattern -Name $Name)) {
		$chocoParams.Add('Name',$Name)
	}

	# Return the result without additional evaluation, even if empty, to let PackageManagement handle error management
	# Will only terminate if Choco fails to call choco.exe
	$(if ($script:NativeAPI) {
		Invoke-ChocoAPI -Search @chocoParams
	} else {
		Get-ChocoPackage @chocoParams | ConvertTo-SoftwareIdentity -Name $Name
	}) | Where-Object {-not $Name -or (Test-PackageName -Name $_.Name -RequestedName $Name)} |
			Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}
}
