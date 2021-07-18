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

	# If a user wants to check whether the latest version is installed, first check the repo for what the latest version is
	if ($RequiredVersion -eq 'latest') {
		$swid = Find-ChocoPackage -Name $Name
		$RequiredVersion = $swid.Version
	}

	$chocoParams = @{
		LocalOnly = $true
		AllVersions = $true
	}

	# If a user provides a name without a wildcard, include it in the search
	# This provides wildcard search behavior for locally installed packages, which Chocolatey lacks
	if ($Name -and -not ([WildcardPattern]::ContainsWildcardCharacters($Name))) {
		$chocoParams.Add('Name',$Name)
	}

	# Return the result without additional evaluation, even if empty, to let PackageManagement handle error management
	# Will only terminate if Choco fails to call choco.exe
	# Would prefer to express this with ternary operators, but that's not supported with PowerShell 5.1
	Foil\Get-ChocoPackage @chocoParams | ConvertTo-SoftwareIdentity |
		Where-Object {-Not $Name -or ($_.Name -Like $Name)} |
			Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}
}
