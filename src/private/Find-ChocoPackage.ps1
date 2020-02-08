function Find-ChocoPackage {
	param (
		[Parameter(Mandatory=$true)]
		[string]
		$Name,

		[string]
		$RequiredVersion,

		[string]
		$MinimumVersion,

		[string]
		$MaximumVersion
	)

	# Throw an error if provided version arguments don't make sense
	Confirm-VersionParameters -Name $Name -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion

	$options = $request.Options
	foreach( $o in $options.Keys ) {
		Write-Debug ( "OPTION: {0} => {1}" -f ($o, $options[$o]) )
	}

	[array]$RegisteredPackageSources = Get-PackageSources

	if ($options -and $options.ContainsKey('Source')) {
		# Finding the matched package sources from the registered ones
		Write-Verbose ($LocalizedData.SpecifiedSourceName -f ($options['Source']))
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
		} elseif ($RegisteredPackageSources.Name -eq $script:PackageSourceName) {
			# If multiple sources are avaiable but none specified, default to using Chocolatey.org - if present
			$selectedSource = $script:PackageSourceName
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

	# Return the result without additional evaluation, even if empty, to let PackageManagement handle error management
	# Will only terminate if Invoke-Choco fails to call choco.exe
	Invoke-Choco @chocoParams |
		ConvertTo-SoftwareIdentity -RequestedName $Name -Source $selectedSource |
			Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}
}
