# Compare two sematic verions
# -1 if $Version1 < $Version2
# 0  if $Version1 = $Version2
# 1  if $Version1 > $Version2
function Compare-SemVer {
	[CmdletBinding()]
	[OutputType([int])]

	param (
		[string]
		$Version1,

		[string]
		$Version2
	)

	$versionObject1 = Get-VersionPSObject $Version1
	$versionObject2 = Get-VersionPSObject $Version2

	if((-not $versionObject1) -and (-not $versionObject2)) {
		return 0
	}

	if((-not $versionObject1) -and ($versionObject2)) {
		return -1
	}

	if(($versionObject1) -and (-not $versionObject2)) {
		return 1
	}

	$VersionResult = ([Version]$versionObject1.Version).CompareTo([Version]$versionObject2.Version)

	if($VersionResult -ne 0) {
		return $VersionResult
	}

	if($versionObject1.Release -and (-not $versionObject2.Release)) {
		return -1
	}

	if(-not $versionObject1.Release -and $versionObject2.Release) {
		return 1
	}

	Compare-ReleaseMetadata -Version1Metadata $versionObject1.Release -Version2Metadata $versionObject2.Release

	# Based on http://semver.org/, Build metadata SHOULD be ignored when determining version precedence
 }
