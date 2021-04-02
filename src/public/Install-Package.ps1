# It is required to implement this function for the providers that support install-package.
function Install-Package {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FastPackageReference,

		[string]
		$AdditionalArgs = (Get-AdditionalArguments)
	)

	Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Install-Package'))
	Write-Debug -Message ($LocalizedData.FastPackageReference -f $FastPackageReference)

	# If the fast package preference doesnt match the pattern we expect, throw an exception
	if ((-not ($FastPackageReference -match $script:FastReferenceRegex)) -or (-not ($Matches.name -and $Matches.version))) {
		ThrowError -ExceptionName "System.ArgumentException" `
			-ExceptionMessage ($LocalizedData.FailToInstall -f $FastPackageReference) `
			-ErrorId 'FailToInstall' `
			-ErrorCategory InvalidArgument
	}

	$shouldContinueQueryMessage = ($LocalizedData.InstallPackageQuery -f "Installing", $Matches.name)
	$shouldContinueCaption = $LocalizedData.InstallPackageCaption

	# If the user opts not to install the package, exit from the script
	if (-not (((Get-ForceProperty) -or (Get-AcceptLicenseProperty)) -or $request.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption))) {
		Write-Warning ($LocalizedData.NotInstalled -f $FastPackageReference)
		return
	}

	$chocoParams = @{
		Name = $Matches.name
		Version = $Matches.version
		Source = $Matches.source
		Force = Get-ForceProperty
	}

	# Split on the first hyphen of each option/switch
	$argSplitRegex = '(?:^|\s)-'
	# ParamGlobal Flag
	$paramGlobalRegex = '\w*-(?:p.+global)\w*'
	# ArgGlobal Flag
	$argGlobalRegex = '\w*-(?:(a|i).+global)\w*'
	# Just parameters
	$paramFilterRegex = '\w*(?:param)\w*'
	# Just parameters
	$argFilterRegex = '\w*(?:arg)\w*'

	[regex]::Split($AdditionalArgs,$argSplitRegex) | ForEach-Object {
		if ($_ -match $paramGlobalRegex) {
			$chocoParams.ParamsGlobal = $True
		} elseif ($_ -match $paramFilterRegex) {
			# Just get the parameters and trim quotes on either end
			$chocoParams.Parameters = $_.Split(' ',2)[1].Trim('"','''')
		} elseif ($_ -match $argGlobalRegex) {
			$chocoParams.ArgsGlobal = $True
		} elseif ($_ -match $argFilterRegex) {
			$chocoParams.InstallArguments = $_.Split(' ',2)[1].Trim('"','''')
		}
	}

	$swid = $(
		$result = Install-ChocoPackage @chocoParams
		if (-not $result) {
			ThrowError -ExceptionName 'System.OperationCanceledException' `
			-ExceptionMessage "The operation failed. Check the Chocolatey logs for more information." `
			-ErrorID 'JobFailure' `
			-ErrorCategory InvalidOperation `
		}
		ConvertTo-SoftwareIdentity -ChocoOutput $result -Name $chocoParams.name -Source $chocoParams.source
	) | Where-Object {Test-PackageVersion -Package $_ -RequiredVersion $chocoParams.version -ErrorAction SilentlyContinue}

	if (-not $swid) {
		# Choco didn't throw an exception but we also couldn't pull a Software Identity from the output.
		# The output format Choco.exe may have changed from what our regex pattern was expecting.
		Write-Warning ($LocalizedData.UnexpectedChocoResponse -f $FastPackageReference)
	}

	$swid
}
