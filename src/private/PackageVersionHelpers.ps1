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

	[System.Version]$version = $Package.Version.TrimStart('v')

	if (-not ($RequiredVersion -or $MinimumVersion -or $MaximumVersion)) {
		return $true
	}

	if ($RequiredVersion) {
		return  ($Version -eq [System.Version]$RequiredVersion)
	}

	$isMatch = $false

	if($MinimumVersion)
	{
		$isMatch = $version -ge [System.Version]$MinimumVersion
	}

	if($MaximumVersion)
	{
		if($MinimumVersion)
		{
			$isMatch = $isMatch -and ($version -le [System.Version]$MaximumVersion)
		}
		else
		{
			$isMatch = $version -le [System.Version]$MaximumVersion
		}
	}

	return $isMatch
}

# Sanity checks on the various version options specified by the user
function Confirm-VersionParameters
{
	Param (

		[Parameter()]
		[String[]]
		$Name,

		[Parameter()]
		[String]
		$MinimumVersion,

		[Parameter()]
		[String]
		$RequiredVersion,

		[Parameter()]
		[String]
		$MaximumVersion,

		[Parameter()]
		[Switch]
		$AllVersions = ($request.Options.ContainsKey($script:AllVersions))
	)

	if ($AllVersions -and ($RequiredVersion -or $MinimumVersion -or $MaximumVersion)) {
		ThrowError -ExceptionName "System.ArgumentException" `
					-ExceptionMessage $LocalizedData.AllVersionsCannotBeUsedWithOtherVersionParameters `
					-ErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters' `
					-ErrorCategory InvalidArgument
	} elseif ($RequiredVersion -and ($MinimumVersion -or $MaximumVersion)) {
		ThrowError -ExceptionName "System.ArgumentException" `
					-ExceptionMessage $LocalizedData.VersionRangeAndRequiredVersionCannotBeSpecifiedTogether `
					-ErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether" `
					-ErrorCategory InvalidArgument
	} elseif ($MinimumVersion -and $MaximumVersion -and ($MinimumVersion -gt $MaximumVersion)) {
		ThrowError -ExceptionName "System.ArgumentException" `
					-ExceptionMessage ($LocalizedData.MinimumVersionIsGreaterThanMaximumVersion -f ($MinimumVersion, $MaximumVersion)) `
					-ErrorId "MinimumVersionIsGreaterThanMaximumVersion" `
					-ErrorCategory InvalidArgument
	} elseif ($AllVersions -or $RequiredVersion -or $MinimumVersion -or $MaximumVersion) {
		if (-not $Name -or $Name.Count -ne 1 -or (Test-WildcardPattern -Name $Name[0])) {
			ThrowError -ExceptionName "System.ArgumentException" `
					-ExceptionMessage $LocalizedData.VersionParametersAreAllowedOnlyWithSingleName `
					-ErrorId "VersionParametersAreAllowedOnlyWithSingleName" `
					-ErrorCategory InvalidArgument
		}
	}

	$true
}
