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

	[array]$RegisteredPackageSources = Foil\Get-ChocoSource

	$selectedSource = $(
		if ($options -And $options.ContainsKey('Source')) {
			# Finding the matched package sources from the registered ones
			if ($RegisteredPackageSources.Name -eq $options['Source']) {
				# Found the matched registered source
				$options['Source']
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
				$RegisteredPackageSources[0].Name
			} elseif ($RegisteredPackageSources.Name -eq $script:PackageSource) {
				# If multiple sources are avaiable but none specified, default to using Chocolatey.org - if present
				$script:PackageSource
			} else {
				# If Chocoately.org is not present and no source specified, throw an exception
				ThrowError -ExceptionName 'System.ArgumentException' `
				-ExceptionMessage $LocalizedData.UnspecifiedSource `
				-ErrorId 'UnspecifiedSource' `
				-ErrorCategory InvalidArgument
			}
		}
	)

	Write-Verbose "Source selected: $selectedSource"

	$chocoParams = @{
		Name = $Name
		Source = $selectedSource
	}

	if ($requiredVersion) {
		$chocoParams.Add('Version',$requiredVersion)
	}

	if ($minimumVersion -Or $maximumVersion -Or $options.ContainsKey($script:AllVersions)) {
		# Choco does not support searching by min or max version, so if a user is picky we'll need to pull back all versions and filter ourselves
		$chocoParams.Add('AllVersions',$true)
	}

	if (-Not [WildcardPattern]::ContainsWildcardCharacters($Name)) {
		# Limit NuGet result set to just the specific package name unless it contains a wildcard
		$chocoParams.Add('Exact',$true)
	}

	# Return the result without additional evaluation, even if empty, to let PackageManagement handle error management
	# Will only terminate if Foil fails to call choco.exe
	Foil\Get-ChocoPackage @chocoParams | ConvertTo-SoftwareIdentity -Source $selectedSource |
		Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $RequiredVersion -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion}
}
