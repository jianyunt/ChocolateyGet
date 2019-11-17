# Builds a command optimized for a package provider and sends to choco.exe
function Invoke-Choco {
	[CmdletBinding()]
	param (
		[string]
		$ChocoExePath = (Get-ChocoPath),

		[Parameter(Mandatory=$true, ParameterSetName='Search')]
		[switch]
		$Search,

		[Parameter(Mandatory=$true, ParameterSetName='Install')]
		[switch]
		$Install,

		[Parameter(Mandatory=$true, ParameterSetName='Uninstall')]
		[switch]
		$Uninstall,

		[Parameter(Mandatory=$true, ParameterSetName='Upgrade')]
		[switch]
		$Upgrade,

		[Parameter(Mandatory=$true, ParameterSetName='SourceList')]
		[switch]
		$SourceList,

		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[switch]
		$SourceAdd,

		[Parameter(Mandatory=$true, ParameterSetName='SourceRemove')]
		[switch]
		$SourceRemove,

		[Parameter(ParameterSetName='Search')]
		[Parameter(Mandatory=$true, ParameterSetName='Install')]
		[Parameter(Mandatory=$true, ParameterSetName='Uninstall')]
		[Parameter(Mandatory=$true, ParameterSetName='Upgrade')]
		[string]
		$Package,

		[Parameter(ParameterSetName='Search')]
		[Parameter(ParameterSetName='Install')]
		[Parameter(ParameterSetName='Uninstall')]
		[Parameter(ParameterSetName='Upgrade')]
		[string]
		$Version,

		[Parameter(ParameterSetName='Search')]
		[Parameter(ParameterSetName='Uninstall')]
		[switch]
		$AllVersions,

		[Parameter(ParameterSetName='Search')]
		[switch]
		$LocalOnly,

		[Parameter(ParameterSetName='Search')]
		[Parameter(ParameterSetName='Install')]
		[Parameter(ParameterSetName='Upgrade')]
		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[Parameter(Mandatory=$true, ParameterSetName='SourceRemove')]
		[string]
		$SourceName,

		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[string]
		$SourceLocation,

		[string]
		$AdditionalArgs = (Get-AdditionalArguments)
	)

	if ($ChocoExePath) {
		Write-Debug ("Choco already installed in $ChocoExePath")
	} else {
		$ChocoExePath = Install-ChocoBinaries
	}

	# Split on the first hyphen of each option/switch
	$argSplitRegex = '(?:^|\s)-'
	# Installation parameters/arguments can interfere with non-installation commands (ex: search) and should be filtered out
	$argFilterRegex = '\w*(?:param|arg)\w*'

	# Source Management
	if ($SourceList -or $SourceAdd -or $SourceRemove) {
		# We're not interested in additional args for source management
		Clear-Variable 'AdditionalArgs'

		$cmdString = 'source '
		if ($SourceAdd) {
			$cmdString += "add --name='$SourceName' --source='$SourceLocation' "
		} elseif ($SourceRemove) {
			$cmdString += "remove --name='$SourceName' "
		}

		# If neither add or remote actions specified, list sources

		$cmdString += '--limit-output '
	} else {
		# Package Management
		if ($Install) {
			$cmdString = 'install '
			# Accept all prompts and dont show installation progress percentage - the excess output from choco.exe will slow down PowerShell
			$AdditionalArgs += ' --yes --no-progress '
		} else {
			# Any additional args passed to other commands should be stripped of install-related arguments because Choco gets confused if they're passed
			$AdditionalArgs = $([regex]::Split($AdditionalArgs,$argSplitRegex) | Where-Object -FilterScript {$_ -notmatch $argFilterRegex}) -join ' -'

			if ($Search) {
				$cmdString = 'search '
				$AdditionalArgs += ' --limit-output '
			} elseif ($Uninstall) {
				$cmdString = 'uninstall '
			} elseif ($Upgrade) {
				$cmdString = 'upgrade '
			}
		}

		# Finish constructing package management command string

		if ($Package) {
			$cmdString += "$Package "
		}

		if ($Version) {
			$cmdString += "--version $version "
		}

		if ($SourceName) {
			$cmdString += "--source $SourceName "
		}

		if ($AllVersions) {
			$cmdString += "--all-versions "
		}

		if ($LocalOnly) {
			$cmdString += "--local-only "
		}
	}

	if (Get-ForceProperty)
	{
		$cmdString += '--force '
	}

	# Joins the constructed and user-provided arguments together to be soon split as a single array of options passed to choco.exe
	$cmdString += $AdditionalArgs
	Write-Debug ("Calling $ChocoExePath $cmdString")
	$cmdString = $cmdString.Split(' ')

	# Save the output to a variable so we can inspect the exit code before submitting the output to the pipeline
	$output = & $ChocoExePath $cmdString

	if ($LASTEXITCODE -ne 0) {
		ThrowError -ExceptionName 'System.OperationCanceledException' `
					-ExceptionMessage $($output | Out-String) `
					-ErrorID 'JobFailure' `
					-ErrorCategory InvalidOperation `
					-ExceptionObject $job
	} else {
		$output
	}
}
