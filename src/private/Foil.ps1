# Module created by Microsoft.PowerShell.Crescendo
Function Get-ChocoSource
{
[CmdletBinding()]

param(
[Parameter()]
[string]$AdditionalArguments
    )

BEGIN {
    $__PARAMETERMAP = @{
        AdditionalArguments = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ($output)
                        if ($output) {
                            $output | ForEach-Object {
                                $sourceData = $_ -split '\|'
                                [pscustomobject]@{
                                    Name = $sourceData[0]
                                    Location = $sourceData[1]
                                    Disabled = $sourceData[2]
                                    UserName = $sourceData[3]
                                    Certificate = $sourceData[4]
                                    Priority = $sourceData[5]
                                    'Bypass Proxy' = $sourceData[6]
                                    'Allow Self Service' = $sourceData[7]
                                    'Visibile to Admins Only' = $sourceData[8]
                                }
                            }
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "source"
        "--limit-output"
        "--yes"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message choco
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("choco")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "choco" $__commandArgs | & $__handler
        }
        else {
            $result = & "choco" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
PowerShell Crescendo wrapper for Chocolatey

.PARAMETER AdditionalArguments




#>
}

Function Add-ChocoSource
{
[CmdletBinding()]

param(
[Parameter()]
[string]$Name,
[Parameter()]
[string]$Source,
[Parameter()]
[string]$AdditionalArguments
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = '--name='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        AdditionalArguments = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
        param ( $output )
     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "source"
        "add"
        "--limit-output"
        "--yes"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message choco
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("choco")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "choco" $__commandArgs | & $__handler
        }
        else {
            $result = & "choco" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
PowerShell Crescendo wrapper for Chocolatey

.PARAMETER Name
Source Name


.PARAMETER Source
Source Location


.PARAMETER AdditionalArguments




#>
}

Function Remove-ChocoSource
{
[CmdletBinding()]

param(
[Parameter()]
[string]$Name,
[Parameter()]
[string]$AdditionalArguments
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = '--name='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        AdditionalArguments = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
        param ( $output )
     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "source"
        "remove"
        "--limit-output"
        "--yes"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message choco
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("choco")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "choco" $__commandArgs | & $__handler
        }
        else {
            $result = & "choco" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
PowerShell Crescendo wrapper for Chocolatey

.PARAMETER Name
Source Name


.PARAMETER AdditionalArguments




#>
}

Function Install-ChocoPackage
{
[CmdletBinding()]

param(
[Parameter()]
[string]$Name,
[Parameter()]
[string]$Version,
[Parameter()]
[string]$Source,
[Parameter()]
[switch]$AllVersions,
[Parameter()]
[switch]$LocalOnly,
[Parameter()]
[switch]$Exact,
[Parameter()]
[switch]$Force,
[Parameter()]
[string]$AdditionalArguments
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Version = @{ OriginalName = '--version='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        AllVersions = @{ OriginalName = '--all-versions'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        LocalOnly = @{ OriginalName = '--local-only'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Force = @{ OriginalName = '--force'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        AdditionalArguments = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                param ($output)
                if ($output) {
                    $failures = ($output -match 'fail')
                    if ($failures) {
                        Write-Error ($output -join "`r`n")
                    } else {
                        $packageRegex = "^(?<name>[\S]+)[\|\s]v(?<version>[\S]+)"
                        $packageReportRegex="^[0-9]*(\s*)(packages installed)"
                        $output | ForEach-Object {
                            if (($_ -match $packageRegex) -and ($_ -notmatch $packageReportRegex) -and ($_ -notmatch 'already installed') -and $Matches.name -and $Matches.version) {
                                [pscustomobject]@{
                                    Name = $Matches.name
                                    Version = $Matches.version
                                }
                            }
                        }
                    }
                }
             } }
    }
}
PROCESS {
    $__commandArgs = @(
        "install"
        "--no-progress"
        "--limit-output"
        "--yes"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message choco
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("choco")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "choco" $__commandArgs | & $__handler
        }
        else {
            $result = & "choco" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
PowerShell Crescendo wrapper for Chocolatey

.PARAMETER Name
Package Name


.PARAMETER Version
Package version


.PARAMETER Source
Package Source


.PARAMETER AllVersions
All Versions


.PARAMETER LocalOnly
Local Packages Only


.PARAMETER Exact
Search by exact package name


.PARAMETER Force
Force the operation


.PARAMETER AdditionalArguments




#>
}

Function Get-ChocoPackage
{
[CmdletBinding()]

param(
[Parameter()]
[string]$Name,
[Parameter()]
[string]$Version,
[Parameter()]
[string]$Source,
[Parameter()]
[switch]$AllVersions,
[Parameter()]
[switch]$LocalOnly,
[Parameter()]
[switch]$Exact,
[Parameter()]
[switch]$Force,
[Parameter()]
[string]$AdditionalArguments
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Version = @{ OriginalName = '--version='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        AllVersions = @{ OriginalName = '--all-versions'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        LocalOnly = @{ OriginalName = '--local-only'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Force = @{ OriginalName = '--force'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        AdditionalArguments = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ( $output )
                        $output | ForEach-Object {
                            $name,$version = $_ -split '\|'
                            [pscustomobject]@{
                                Name = $name
                                Version = $version
                            }
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "search"
        "--limit-output"
        "--yes"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message choco
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("choco")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "choco" $__commandArgs | & $__handler
        }
        else {
            $result = & "choco" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
PowerShell Crescendo wrapper for Chocolatey

.PARAMETER Name
Package Name


.PARAMETER Version
Package version


.PARAMETER Source
Package Source


.PARAMETER AllVersions
All Versions


.PARAMETER LocalOnly
Local Packages Only


.PARAMETER Exact
Search by exact package name


.PARAMETER Force
Force the operation


.PARAMETER AdditionalArguments




#>
}

Function Uninstall-ChocoPackage
{
[CmdletBinding()]

param(
[Parameter()]
[string]$Name,
[Parameter()]
[string]$Version,
[Parameter()]
[string]$Source,
[Parameter()]
[switch]$AllVersions,
[Parameter()]
[switch]$LocalOnly,
[Parameter()]
[switch]$Exact,
[Parameter()]
[switch]$Force,
[Parameter()]
[string]$AdditionalArguments
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Version = @{ OriginalName = '--version='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        AllVersions = @{ OriginalName = '--all-versions'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        LocalOnly = @{ OriginalName = '--local-only'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Force = @{ OriginalName = '--force'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        AdditionalArguments = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                param ($output)
                if ($output) {
                    $failures = ($output -match 'fail')
                    if ($failures) {
                        Write-Error ($output -join "`r`n")
                    } else {
                        $packageRegex = "^(?<name>[\S]+)[\|\s]v(?<version>[\S]+)"
                        $packageReportRegex="^[0-9]*(\s*)(packages installed)"
                        $output | ForEach-Object {
                            if (($_ -match $packageRegex) -and ($_ -notmatch $packageReportRegex) -and ($_ -notmatch 'already installed') -and $Matches.name -and $Matches.version) {
                                [pscustomobject]@{
                                    Name = $Matches.name
                                    Version = $Matches.version
                                }
                            }
                        }
                    }
                }
             } }
    }
}
PROCESS {
    $__commandArgs = @(
        "uninstall"
        "--remove-dependencies"
        "--limit-output"
        "--yes"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message choco
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("choco")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "choco" $__commandArgs | & $__handler
        }
        else {
            $result = & "choco" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
PowerShell Crescendo wrapper for Chocolatey

.PARAMETER Name
Package Name


.PARAMETER Version
Package version


.PARAMETER Source
Package Source


.PARAMETER AllVersions
All Versions


.PARAMETER LocalOnly
Local Packages Only


.PARAMETER Exact
Search by exact package name


.PARAMETER Force
Force the operation


.PARAMETER AdditionalArguments




#>
}

Export-ModuleMember -Function Get-ChocoSource, Add-ChocoSource, Remove-ChocoSource, Install-ChocoPackage, Get-ChocoPackage, Uninstall-ChocoPackage
