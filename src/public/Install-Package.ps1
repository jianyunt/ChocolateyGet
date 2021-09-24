# Installs packages based on the provided Fast Package Reference generated by Find-Package
function Install-Package {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification='Required by PackageManagement')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FastPackageReference,

		[Parameter()]
		[string]
		$AdditionalArgs = ($request.Options[$script:AdditionalArguments]),

		[Parameter()]
		[string]
		$InstallArguments = ($request.Options[$script:InstallArguments]),

		[Parameter()]
		[string]
		$PackageParameters = ($request.Options[$script:PackageParameters])
	)

	Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Install-Package'))
	Write-Debug -Message ($LocalizedData.FastPackageReference -f $FastPackageReference)

	# If the fast package reference doesnt match the pattern we expect, throw an exception
	if ((-Not ($FastPackageReference -Match $script:FastReferenceRegex)) -Or (-Not ($Matches.name -And $Matches.version))) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.FailToInstall -f $FastPackageReference) `
			-ErrorId 'FailToInstall' `
			-ErrorCategory InvalidArgument
	}

	$shouldContinueQueryMessage = ($LocalizedData.InstallPackageQuery -f "Installing", $Matches.name)
	$shouldContinueCaption = $LocalizedData.InstallPackageCaption

	# If the user opts not to install the package, exit from the script
	if (-Not ((Get-PromptBypass) -Or $request.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption))) {
		Write-Warning ($LocalizedData.NotInstalled -f $FastPackageReference)
		return
	}

	$chocoParams = @{
		Name = $Matches.name
		Version = $Matches.version
		Source = $Matches.source
		Force = $request.Options.ContainsKey($script:Force)
		Parameters = $PackageParameters
		InstallArguments = $InstallArguments
	}

	# Split on the first hyphen of each option/switch
	[regex]::Split($AdditionalArgs,'(?:^|\s)-') | ForEach-Object {
		Write-Debug "AdditionalArgs: $_"
		# Check each option/switch against known patterns that we can pass to Foil
		switch -Regex ($_) {
			'\w*-(?:p.+global)\w*' {
				Write-Debug "Found the ParamsGlobal flag"
				$chocoParams.ParamsGlobal = $True
				Break
			}
			'\w*(?:param)\w*' {
				Write-Debug "Found package parameters to split and trim"
				$chocoParams.Parameters = $_.Split(' ',2)[1].Trim('"','''')
				Break
			}
			'\w*-(?:(a|i).+global)\w*' {
				Write-Debug "Found the ArgsGlobal flag"
				$chocoParams.ArgsGlobal = $True
				Break
			}
			'\w*(?:arg)\w*' {
				Write-Debug "Found package arguments to split and trim"
				$chocoParams.InstallArguments = $_.Split(' ',2)[1].Trim('"','''')
				Break
			}
		}
	}

	# Convert the PSCustomObject output from Foil into PackageManagement SWIDs, then validate what Chocolatey installed matched what we requested
	$swid = $(
		$result = Foil\Install-ChocoPackage @chocoParams
		# If Foil didn't return anything, something went wrong and we need to throw our own exception
		if (-Not $result) {
			ThrowError -ExceptionName 'System.OperationCanceledException' `
			-ExceptionMessage $LocalizedData.ChocoFailure `
			-ErrorID 'JobFailure' `
			-ErrorCategory InvalidOperation `
		}
		ConvertTo-SoftwareIdentity -InputObject $result -Source $chocoParams.source
	) | Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $chocoParams.version -ErrorAction SilentlyContinue}

	if (-Not $swid) {
		# Foil returned something, but not in the format we expected. Something is amiss.
		Write-Warning ($LocalizedData.UnexpectedChocoResponse -f $FastPackageReference)
	}

	$swid
}
