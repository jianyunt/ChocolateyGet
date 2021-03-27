# Builds a command optimized for a package provider and sends to choco.exe
function Invoke-ChocoAPI {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, ParameterSetName='Search')]
		[switch]
		$Search,

		[Parameter(Mandatory=$true, ParameterSetName='Install')]
		[switch]
		$Install,

		[Parameter(Mandatory=$true, ParameterSetName='Uninstall')]
		[switch]
		$Uninstall,

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
		[string]
		$PackageName,

		[Parameter(ParameterSetName='Search')]
		[Parameter(Mandatory=$true, ParameterSetName='Install')]
		[Parameter(Mandatory=$true, ParameterSetName='Uninstall')]
		[string]
		$Version,

		[Parameter(ParameterSetName='Search')]
		[switch]
		$AllVersions,

		[Parameter(ParameterSetName='Search')]
		[switch]
		$LocalOnly,

		[Parameter(ParameterSetName='Search')]
		[switch]
		$Exact,

		[Parameter(ParameterSetName='Search')]
		[Parameter(ParameterSetName='Install')]
		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[Parameter(Mandatory=$true, ParameterSetName='SourceRemove')]
		[string]
		$SourceName = $script:PackageSourceName,

		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[string]
		$SourceLocation,

		[string]
		$AdditionalArgs = (Get-AdditionalArguments),

		[switch]
		$Force = (Get-ForceProperty)
	)

	$sourceCommandName = 'source'
	# Split on the first hyphen of each option/switch
	$argSplitRegex = '(?:^|\s)-'
	# Installation parameters/arguments can interfere with non-installation commands (ex: search) and should be filtered out
	$argParamFilterRegex = '\w*(?:param|arg)\w*'
	# ParamGlobal Flag
	$paramGlobalRegex = '\w*-(?:p.+global)\w*'
	# ArgGlobal Flag
	$argGlobalRegex = '\w*-(?:(a|i).+global)\w*'
	# Just parameters
	$paramFilterRegex = '\w*(?:param)\w*'
	# Just parameters
	$argFilterRegex = '\w*(?:arg)\w*'

	$ChocoAPI = [chocolatey.Lets]::GetChocolatey().SetCustomLogging([chocolatey.infrastructure.logging.NullLog]::new())

	# Series of generic paramters that can be used across both 'get' and 'set' operations, which are called differently
	$genericParams = {
		# Entering scriptblock

		$config.QuietOutput = $True
		$config.RegularOutput = $False

		if ($Version) {
			$config.Version = $Version
		}

		if ($AllVersions) {
			$config.AllVersions = $true
		}

		if ($LocalOnly) {
			$config.ListCommand.LocalOnly = $true
		}

		if ($Force) {
			$config.Force = $true
		}

		if ($Exact) {
			$config.Exact = $true
		}
	}

	if ($SourceList) {
		# We can get the source info right from the MachineSources property without any special calls
		# Just need to alias each source's 'Key' property to 'Location' so that it lines up the CLI terminology
		$ChocoAPI.GetConfiguration().MachineSources | Add-Member -MemberType AliasProperty -Name Location -Value Key -PassThru
	} elseif ($Search) {
		# Configuring 'get' operations - additional arguments are ignored
		# Using Out-Null to 'eat' the output from the Set operation so it doesn't contaminate the pipeline
		$ChocoAPI.Set({
			# Entering scriptblock
			param($config)
			Invoke-Command $genericParams
			if ($PackageName) {
				$config.Input = $PackageName
			}
			$config.CommandName = [chocolatey.infrastructure.app.domain.CommandNameType]::list
		}) | Out-Null

		Write-Debug ("Invoking the Choco API with the following configuration: $($ChocoAPI.GetConfiguration() | Out-String)")
		# This invocation looks gross, but PowerShell currently lacks a clean way to call the parameter-less .NET generic method that Chocolatey uses for returning data
		$ChocoAPI.GetType().GetMethod('List').MakeGenericMethod([chocolatey.infrastructure.results.PackageResult]).Invoke($ChocoAPI,$null) | ForEach-Object {
			# If searching local packages, we need to spoof the source name returned by the API with a generic default
			if ($LocalOnly) {
				$_.Source = $script:PackageSourceName
			} else {
				# Otherwise, convert the source URI returned by Choco to a source name
				$_.Source = $ChocoAPI.GetConfiguration().MachineSources | Where-Object Key -eq $_.Source | Select-Object -ExpandProperty Name
			}

			$swid = @{
				FastPackageReference = $_.Name+"#"+$_.Version+"#"+$_.Source
				Name = $_.Name
				Version = $_.Version
				versionScheme = "MultiPartNumeric"
				FromTrustedSource = $true
				Source = $_.Source
			}
			New-SoftwareIdentity @swid
		}
	} else {
		# Using Out-Null to 'eat' the output from the Set operation so it doesn't contaminate the pipeline
		$ChocoAPI.Set({
			# Entering scriptblock
			param($config)
			Invoke-Command $genericParams

			# Configuring 'set' operations
			if ($SourceAdd -or $SourceRemove) {
				$config.CommandName = $sourceCommandName
				$config.SourceCommand.Name = $SourceName

				if ($SourceAdd) {
					$config.SourceCommand.Command = [chocolatey.infrastructure.app.domain.SourceCommandType]::add
					$config.Sources = $SourceLocation
				} elseif ($SourceRemove) {
					$config.SourceCommand.Command = [chocolatey.infrastructure.app.domain.SourceCommandType]::remove
				}
			} else {
				# In this area, we're only leveraging (not managing) sources, hence why we're treating the source name parameter differently
				if ($PackageName) {
					$config.PackageNames = $PackageName
				}

				if ($SourceName) {
					$config.Sources = $config.MachineSources | Where-Object Name -eq $SourceName | Select-Object -ExpandProperty Key
				}

				if ($Install) {
					$config.CommandName = [chocolatey.infrastructure.app.domain.CommandNameType]::install
					$config.PromptForConfirmation = $False

					[regex]::Split($AdditionalArgs,$argSplitRegex) | ForEach-Object {
						if ($_ -match $paramGlobalRegex) {
							$config.ApplyPackageParametersToDependencies = $True
						} elseif ($_ -match $paramFilterRegex) {
							# Just get the parameters and trim quotes on either end
							$config.PackageParameters = $_.Split(' ',2)[1].Trim('"','''')
						} elseif ($_ -match $argGlobalRegex) {
							$config.ApplyInstallArgumentsToDependencies = $True
						} elseif ($_ -match $argFilterRegex) {
							$config.InstallArguments = $_.Split(' ',2)[1].Trim('"','''')
						}
					}
				} elseif ($Uninstall) {
					$config.CommandName = [chocolatey.infrastructure.app.domain.CommandNameType]::uninstall
					$config.ForceDependencies = $true
				}
			}
		}) | Out-Null

		Write-Debug ("Invoking the Choco API with the following configuration: $($ChocoAPI.GetConfiguration() | Out-String)")
		# Using Out-Null to 'eat' the output from the Run operation so it doesn't contaminate the pipeline
		$ChocoAPI.Run() | Out-Null

		if ($Install -or $Uninstall) {
			# Since the API wont return anything (ex: dependencies installed), we can only return the package asked for
			# This is a regression of the API vs CLI, as we can capture dependencies returned by the CLI

			$swid = @{
				FastPackageReference = $PackageName+"#"+$Version+"#"+$SourceName
				Name = $PackageName
				Version = $Version
				versionScheme = "MultiPartNumeric"
				FromTrustedSource = $true
				Source = $SourceName
			}

			New-SoftwareIdentity @swid
		}
	}
}
