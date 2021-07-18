function Find-ChocoPackage {
	param (
		[Parameter(Mandatory=$true)]
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

	$options = $request.Options
	foreach( $o in $options.Keys ) {
		Write-Debug ( "OPTION: {0} => {1}" -f ($o, $options[$o]) )
	}

	[array]$RegisteredPackageSources = Foil\Get-ChocoSource

	if ($options -and $options.ContainsKey('Source')) {
		# Finding the matched package sources from the registered ones
		Write-Verbose ($LocalizedData.SpecifiedSource -f ($options['Source']))
		if ($RegisteredPackageSources.Name -eq $options['Source']) {
			# Found the matched registered source
			$selectedSource = $options['Source']
		} else {
			ThrowError -ExceptionName 'System.ArgumentException' `
				-ExceptionMessage ($LocalizedData.PackageSourceNotFound -f ($options['Source'])) `
				-ErrorId 'PackageSourceNotFound' `
				-ErrorCategory InvalidArgument `
				-ExceptionObject $options['Source']
		}
	} else {
		# User did not specify a source. Now what?
		if ($RegisteredPackageSources.Count -eq 1) {
			# If no source name is specified and only one source is available, use it
			$selectedSource = $RegisteredPackageSources[0].Name
		} elseif ($RegisteredPackageSources.Name -eq $script:PackageSource) {
			# If multiple sources are avaiable but none specified, default to using Chocolatey.org - if present
			$selectedSource = $script:PackageSource
		} else {
			# If Chocoately.org is not present and no source specified, throw an exception
			ThrowError -ExceptionName 'System.ArgumentException' `
				-ExceptionMessage $LocalizedData.UnspecifiedSource `
				-ErrorId 'UnspecifiedSource' `
				-ErrorCategory InvalidArgument
		}
	}

	Write-Verbose "Source selected: $selectedSource"

	$chocoParams = @{
		Name = $Name
		Source = $selectedSource
	}

	if ($requiredVersion) {
		$chocoParams.Add('Version',$requiredVersion)
	}

	if ($minimumVersion -or $maximumVersion -or $options.ContainsKey($script:AllVersions)) {
		# Choco does not support searching by min or max version, so if a user is picky we'll need to pull back all versions and filter ourselves
		$chocoParams.Add('AllVersions',$true)
	}

	if (-not ($env:CHOCO_NONEXACT_SEARCH -or [WildcardPattern]::ContainsWildcardCharacters($Name))) {
		# Limit NuGet result set to just the specific package name if version is specified
		# Have to keep choco pinned to 0.10.13 due to https://github.com/chocolatey/choco/issues/1843 - should be fixed in 0.10.16, which is still in beta
		$chocoParams.Add('Exact',$true)
	}

	# Return the result without additional evaluation, even if empty, to let PackageManagement handle error management
	# Will only terminate if Choco fails to call choco.exe
	Foil\Get-ChocoPackage @chocoParams | ConvertTo-SoftwareIdentity -Source $selectedSource |
		Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}
}
