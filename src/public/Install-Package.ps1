# It is required to implement this function for the providers that support install-package.
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
		$AdditionalArgs = ($request.Options[$script:AdditionalArguments])
	)

	Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Install-Package'))
	Write-Debug -Message ($LocalizedData.FastPackageReference -f $FastPackageReference)

	# If the fast package preference doesnt match the pattern we expect, throw an exception
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
	}

	# Split on the first hyphen of each option/switch
	[regex]::Split($AdditionalArgs,'(?:^|\s)-') | ForEach-Object {
		Write-Debug "AdditionalArgs: $_"
		switch -Regex ($_) {
			'\w*-(?:p.+global)\w*' {
				Write-Debug "Found the ParamsGlobal flag"
				$chocoParams.ParamsGlobal = $True
			}
			'\w*(?:param)\w*' {
				Write-Debug "Found package parameters to split and trim"
				$chocoParams.Parameters = $_.Split(' ',2)[1].Trim('"','''')
			}
			'\w*-(?:(a|i).+global)\w*' {
				Write-Debug "Found the ArgsGlobal flag"
				$chocoParams.ArgsGlobal = $True
			}
			'\w*(?:arg)\w*' {
				Write-Debug "Found package arguments to split and trim"
				$chocoParams.InstallArguments = $_.Split(' ',2)[1].Trim('"','''')
			}
		}
	}

	$swid = $(
		$result = Foil\Install-ChocoPackage @chocoParams
		if (-Not $result) {
			ThrowError -ExceptionName 'System.OperationCanceledException' `
			-ExceptionMessage $LocalizedData.ChocoFailure `
			-ErrorID 'JobFailure' `
			-ErrorCategory InvalidOperation `
		}
		ConvertTo-SoftwareIdentity -ChocoOutput $result -Source $chocoParams.source
	) | Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $chocoParams.version -ErrorAction SilentlyContinue}

	if (-Not $swid) {
		# Foil didn't throw an exception but we also couldn't pull a Software Identity from the output.
		# The output format Choco.exe may have changed from what our regex pattern was expecting.
		Write-Warning ($LocalizedData.UnexpectedChocoResponse -f $FastPackageReference)
	}

	$swid
}
