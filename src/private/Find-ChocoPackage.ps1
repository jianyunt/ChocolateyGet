function Find-ChocoPackage {
	param (
		[string] $Name,
		[string] $RequiredVersion,
		[string] $MinimumVersion,
		[string] $MaximumVersion
	)


	$ValidationResult = Confirm-VersionParameters -Name $Name `
							-MinimumVersion $MinimumVersion `
							-MaximumVersion $MaximumVersion `
							-RequiredVersion $RequiredVersion `
							-AllVersions:$request.Options.ContainsKey($script:AllVersions)

	if (-not $ValidationResult)
	{
		# Return now as the version validation failed already
		return
	}

	$options = $request.Options
	foreach( $o in $options.Keys ) {
		Write-Debug ( "OPTION: {0} => {1}" -f ($o, $options[$o]) )
	}

	if (-not $name) {
		# No name provided, which is not allowed
		Write-Error ( $LocalizedData.SearchingEntireRepo)
		return
	}

	[array]$RegisteredPackageSources = Get-PackageSources

	if ($options -and $options.ContainsKey('Source')) {
		# Finding the matched package sources from the registered ones
		$sourceName = $options['Source']
		Write-Verbose ($LocalizedData.SpecifiedSourceName -f ($sourceName))

		if ($RegisteredPackageSources.Name -eq $sourceName) {
			# Found the matched registered source
			$selectedSource = $sourceName
		} else {
			$message = $LocalizedData.PackageSourceNotFound -f ($sourceName)
			ThrowError -ExceptionName "System.ArgumentException" `
				-ExceptionMessage $message `
				-ErrorId "PackageSourceNotFound" `
				-ErrorCategory InvalidArgument `
				-ExceptionObject $sourceName
		}
	} else {
		# User did not specify a source. Now what?
		if ($RegisteredPackageSources.Count -eq 1) {
			# If no source name is specified and only one source is available, use it
			$selectedSource = $RegisteredPackageSources[0].Name
		} elseif ($RegisteredPackageSources.Name -eq $script:PackageSourceName) {
			# If multiple sources are avaiable but none specified, default to using Chocolatey.org - if present
			$selectedSource = $script:PackageSourceName
		} else {
			# If Chocoately.org is not present and no source specified, throw an exception
			ThrowError -ExceptionName "System.ArgumentException" `
				-ExceptionMessage $LocalizedData.UnspecifiedSource `
				-ErrorId 'UnspecifiedSource' `
				-ErrorCategory InvalidArgument
		}
	}

	Write-Verbose "Source selected: $selectedSource"

	$chocoParams = @{
		Search = $true
		Package = $name
		SourceName = $selectedSource
	}

	if ($requiredVersion) {
		$chocoParams.Add('Version',$requiredVersion)
	} elseif ($minimumVersion -or $maximumVersion -or $options.ContainsKey($script:AllVersions)) {
		# Choco does not support searching by min or max version, so if a user is picky we'll need to pull back all versions and filter ourselves
		$chocoParams.Add('AllVersions',$true)
	}

	Invoke-Choco @chocoParams | 
		ConvertTo-SoftwareIdentity -RequestedName $Name -Source $selectedSource -Verbose | 
			Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}

}