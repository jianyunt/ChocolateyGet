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

	$version = $Package.Version.TrimStart('v')

	if (-not ($RequiredVersion -or $MinimumVersion -or $MaximumVersion)) {
		return $true
	}

	if ($RequiredVersion) {
		return  ($Version -eq $RequiredVersion)
	}

	$isMatch = $false

	if($MinimumVersion)
	{
		$isMatch = $version -ge $MinimumVersion
	}

	if($MaximumVersion)
	{
		if($MinimumVersion)
		{
			$isMatch = $isMatch -and ($version -le $MaximumVersion)
		}
		else
		{
			$isMatch = $version -le $MaximumVersion
		}
	}

	return $isMatch
}

# Validate versions
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
		$Message = $LocalizedData.MinimumVersionIsGreaterThanMaximumVersion -f ($MinimumVersion, $MaximumVersion)
		ThrowError -ExceptionName "System.ArgumentException" `
					-ExceptionMessage $Message `
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

function Get-VersionPSObject {
	param (
		[Parameter(Mandatory=$true)]
		[string]
		$Version
	)

	#region Semversion variables
	$AllowFourPartsVersion = "(?<Version>\d+(\s*\.\s*\d+){0,3})"
	
	# the pre-release regex is of the form -<pre-release version> where <pre-release> version is set of identifier
	# delimited by ".". Each identifer can be any characters in [A-z0-9a-z-]
	$ReleasePattern = "(?<Release>-[A-Z0-9a-z]+(\.[A-Z0-9a-z]+)*)?"
	
	# The build regex is of the same form except with a + instead of -
	$BuildPattern = "(?<Build>\-[A-Z0-9a-z\-]+(\.[A-Z0-9a-z\-]+)*)?"
	
	# Purposely this should be the regex
	$SemanticVersionPattern = "^" + $AllowFourPartsVersion + $ReleasePattern +$BuildPattern + "$"
	#endregion

	$isMatch = $Version.Trim() -match $SemanticVersionPattern
	if ($isMatch) {
		if ($Matches.Version) {$v = $Matches.Version.Trim()} else {$v = $Matches.Version}
		if ($Matches.Release) {$r = $Matches.Release.Trim("-, +")} else {$r = $Matches.Release}
		if ($Matches.Build) {$b = $Matches.Build.Trim("-, +")} else {$b = $Matches.Build}

		New-Object PSObject -Property @{
			Version = $v
			Release = $r
			Build = $b
		}
	}
	else
	{
		ThrowError -ExceptionName "System.InvalidOperationException" `
					-ExceptionMessage ($LocalizedData.InvalidVersionFormat -f $Version, $SemanticVersionPattern) `
					-ErrorId "InvalidVersionFormat" `
					-ErrorCategory InvalidOperation
	}
}

 function Compare-ReleaseMetadata {
	[CmdletBinding()]
	[OutputType([int])]

	param (
		[string]
		$Version1Metadata,
		
		[string]
		$Version2Metadata
	)

	if ((-not $Version1Metadata) -and (-not $Version2Metadata)) {
		return 0
	}

	# For release part, 1.0.0 is newer/greater then 1.0.0-alpha. So return 1 here.
	if ((-not $Version1Metadata) -and $Version2Metadata) {
		return 1
	}

	if (($Version1Metadata) -and (-not $Version2Metadata)) {
		return -1
	}

	$version1Parts=$Version1Metadata.Trim('-').Split('.')
	$version2Parts=$Version2Metadata.Trim('-').Split('.')

	$length = [System.Math]::Min($version1Parts.Length, $version2Parts.Length)

	for ($i = 0; ($i -lt $length); $i++) {
		$result = Compare-MetadataPart -Version1Part $version1Parts[$i] -Version2Part $version2Parts[$i]

		if ($result -ne 0)
		{
			return $result
		}
	}

	# so far we found two versions are the same. If length is the same, we think two version are indeed the same
	if ($version1Parts.Length -eq $version1Parts.Length) {
		return 0
	}

	# 1.0.0-alpha < 1.0.0-alpha.1
	if ($version1Parts.Length -lt $length) {
		return -1
	} else {
		return 1
	}
}

function Compare-MetadataPart {
	[CmdletBinding()]
	[OutputType([int])]

	param (
		[string]
		$Version1Part,

		[string]
		$Version2Part
	)

	if ((-not $Version1Part) -and (-not $Version2Part)) {
		return 0
	}

	# For release part, 1.0.0 is newer/greater then 1.0.0-alpha. So return 1 here.
	if ((-not $Version1Part) -and $Version2Part) {
		return 1
	}

	if (($Version1Part) -and (-not $Version2Part)) {
		return -1
	}

	$version1Num = 0
	$version2Num = 0

	$v1IsNumeric = [System.Int32]::TryParse($Version1Part, [ref] $version1Num);
	$v2IsNumeric = [System.Int32]::TryParse($Version2Part, [ref] $version2Num);

	$result = 0
	# if both are numeric compare them as numbers
	if ($v1IsNumeric -and $v2IsNumeric) {
		$result = $version1Num.CompareTo($version2Num);
	} elseif ($v1IsNumeric -or $v2IsNumeric) {
		# numeric numbers come before alpha chars
		if ($v1IsNumeric) { return -1 }
		else { return 1 }
	} else {
		$result = [string]::Compare($Version1Part, $Version2Part)
	}

	return $result
}
