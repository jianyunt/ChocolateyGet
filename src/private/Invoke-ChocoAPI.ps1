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
		$Name,

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
		$Source = $script:PackageSource,

		[Parameter(Mandatory=$true, ParameterSetName='SourceAdd')]
		[string]
		$Location,

		[Parameter(ParameterSetName='Install')]
		[switch]
		$ParamsGlobal,

		[Parameter(ParameterSetName='Install')]
		[string]
		$Parameters,

		[Parameter(ParameterSetName='Install')]
		[switch]
		$ArgsGlobal,

		[Parameter(ParameterSetName='Install')]
		[string]
		$InstallArguments,

		[switch]
		$Force = (Get-ForceProperty)
	)

	$sourceCommandName = 'source'

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
			if ($Name) {
				$config.Input = $Name

				if ($Exact) {
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
				$_.Source = $script:PackageSource
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
				$config.SourceCommand.Name = $Source

				if ($SourceAdd) {
					$config.SourceCommand.Command = [chocolatey.infrastructure.app.domain.SourceCommandType]::add
					$config.Sources = $Location
				} elseif ($SourceRemove) {
					$config.SourceCommand.Command = [chocolatey.infrastructure.app.domain.SourceCommandType]::remove
				}
			} else {
				# In this area, we're only leveraging (not managing) sources, hence why we're treating the source name parameter differently
				if ($Name) {
					$config.PackageNames = $Name
				}

				if ($Source) {
					$config.Sources = $config.MachineSources | Where-Object Name -eq $Source | Select-Object -ExpandProperty Key
				}

				if ($Install) {
					$config.CommandName = [chocolatey.infrastructure.app.domain.CommandNameType]::install
					$config.PromptForConfirmation = $False

					if ($ParamsGlobal) {
						$config.ApplyPackageParametersToDependencies = $True
					}

					if ($Parameters) {
						$config.PackageParameters = $Parameters
					}

					if ($ArgsGlobal) {
						$config.ApplyInstallArgumentsToDependencies = $True
					}

					if ($InstallArguments) {
						$config.InstallArguments = $InstallArguments
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
				FastPackageReference = $Name+"#"+$Version+"#"+$Source
				Name = $Name
				Version = $Version
				versionScheme = "MultiPartNumeric"
				FromTrustedSource = $true
				Source = $Source
			}

			New-SoftwareIdentity @swid
		}
	}
}
