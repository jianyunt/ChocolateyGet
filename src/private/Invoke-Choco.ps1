# Builds a command optimized for a package provider and sends to choco.exe
function Invoke-Choco {
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
		$Package,

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
		[Parameter(ParameterSetName='Install')]
		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[Parameter(Mandatory=$true, ParameterSetName='SourceRemove')]
		[string]
		$SourceName = $script:PackageSourceName,

		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[string]
		$SourceLocation,

		[string]
		$AdditionalArgs = (Get-AdditionalArguments)
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

	if ($script:NativeAPI) {
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

			if (Get-ForceProperty) {
				$config.Force = $true
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
				if ($Package) {
					$config.Input = $Package
					if (($Version -or $AllVersions) -and -not $env:CHOCO_NONEXACT_SEARCH) {
						# Limit NuGet API result set to just the specific package name if version is specified
						# Have to keep choco pinned to 0.10.13 due to https://github.com/chocolatey/choco/issues/1843 - should be fixed in 0.10.16, which is still in beta
						$config.ListCommand.Exact = $true
					}
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
					if ($Package) {
						$config.PackageNames = $Package
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
					FastPackageReference = $Package+"#"+$Version+"#"+$SourceName
					Name = $Package
					Version = $Version
					versionScheme = "MultiPartNumeric"
					FromTrustedSource = $true
					Source = $SourceName
				}

				New-SoftwareIdentity @swid
			}
		}
	} else {
		$ChocoExePath = Get-ChocoPath

		if ($ChocoExePath) {
			Write-Debug ("Choco already installed")
		} else {
			$ChocoExePath = Install-ChocoBinaries
		}

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
				$AdditionalArgs = $([regex]::Split($AdditionalArgs,$argSplitRegex) | Where-Object -FilterScript {$_ -notmatch $argParamFilterRegex}) -join ' -'

				if ($Search) {
					$cmdString = 'search '
					$AdditionalArgs += ' --limit-output '
				} elseif ($Uninstall) {
					$cmdString = 'uninstall '
					# Accept all prompts
					$AdditionalArgs += ' --yes --remove-dependencies '
				}
			}

			# Finish constructing package management command string

			if ($Package) {
				$cmdString += "$Package "
					if (($Version -or $AllVersions) -and -not $env:CHOCO_NONEXACT_SEARCH) {
					# Limit NuGet API result set to just the specific package name if version is specified
					# Have to keep choco pinned to 0.10.13 due to https://github.com/chocolatey/choco/issues/1843 - should be fixed in 0.10.16, which is still in beta
					$cmdString += "--exact "
				}
			}

			if ($Version) {
				$cmdString += "--version $Version "
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

		# Add support for Error Code 2 (no results) for basic enhanced error code support
		if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 2) {
			ThrowError -ExceptionName 'System.OperationCanceledException' `
				-ExceptionMessage "The following command $ChocoExePath $cmdString failed with error code $LASTEXITCODE" `
				-ErrorID 'JobFailure' `
				-ErrorCategory InvalidOperation `
		} else {
			if ($Install -or ($Search -and $SourceName)) {
				$output | ConvertTo-SoftwareIdentity -RequestedName $Package -Source $SourceName
			} elseif ($Uninstall) {
				$output | ConvertTo-SoftwareIdentity -RequestedName $Package -Source $script:PackageSourceName
			} elseif ($Search) {
				$output | ConvertTo-SoftwareIdentity -RequestedName $Package
			} elseif ($SourceList) {
				$output | ConvertFrom-String -Delimiter "\|" -PropertyNames $script:ChocoSourcePropertyNames | Where-Object {$_.Disabled -eq 'False'}
			} else {
				$output
			}
		}
	}
}
