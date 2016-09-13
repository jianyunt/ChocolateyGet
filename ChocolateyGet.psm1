# ChocolateyGet is a PackageManagement provider. It does package management operations such as find, install, 
# uninstall packages from https://www.chocolatey.org. It essentially a wrapper around choco.exe.  

# Import the localized Data
Microsoft.PowerShell.Utility\Import-LocalizedData  LocalizedData -filename ChocolateyGet.Resource.psd1

#region Local variable definitions
# Define provider related variables
$script:ProviderName = "ChocolateyGet"
$script:PackageSourceName = "Chocolatey"
$script:PackageSource = "https://www.chocolatey.org"
$script:additionalArguments = "AdditionalArguments"
$script:AllVersions = "AllVersions"

# Define choco related variables
$script:ChocoExeName = 'choco.exe'
$script:ChocoExePath = $null

# Utility variables 
$script:PackageRegex = "(?<name>[^\s]*)(\s*)(?<version>[^\s]*)"
$script:PackageReportRegex="^[0-9]*(\s*)(packages installed)"
$script:FastReferenceRegex = "(?<name>[^#]*)#(?<version>[^\s]*)"

# Check if this is nano server. [System.Runtime.Loader.AssemblyLoadContext] is only available on NanoServer
try {
    [System.Runtime.Loader.AssemblyLoadContext]
    $script:isNanoServer = $true
}
catch
{
    $script:isNanoServer = $false
}

#endregion


#region Provider APIs Implementation

# Mandatory function for the PackageManagement providers. It returns the name of your provider.
function Get-PackageProviderName { 

    return $script:ProviderName
}

# Mandatory function for the PackageManagement providers. It initializes your provider before performing any actions.
function Initialize-Provider { 

    Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Initialize-Provider'))

}

# Defines PowerShell dynamic parameters so that a user can pass in parameters via OneGet to the provider
function Get-DynamicOptions
{
    param
    (
        [Microsoft.PackageManagement.MetaProvider.PowerShell.OptionCategory] 
        $category
    )

    Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Get-DynamicOptions'))

    switch($category)
    {
        Package {
                    Write-Output -InputObject (New-DynamicOption -Category $category -Name $script:additionalArguments -ExpectedType String -IsRequired $false)
                }
        Install 
                {
                    Write-Output -InputObject (New-DynamicOption -Category $category -Name $script:additionalArguments -ExpectedType String -IsRequired $false)
                }

    }
}



# This function gets called during find-package, install-package, get-packagesource etc.
# OneGet uses this method to identify which provider can handle the packages from a particular source location.
function Resolve-PackageSource { 

    Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Resolve-PackageSource')) 
    
    $isTrusted    = $false
    $isRegistered = $false
    $isValidated  = $true
    $location     = $script:PackageSource
    
 
    foreach($Name in @($request.PackageSources)) {

        if($Name -eq $script:PackageSourceName)
        {
    	    write-debug ($LocalizedData.ProviderDebugMessage -f ('Resolve-PackageSources to $location'))

            New-PackageSource $Name $location $isTrusted $isRegistered $isValidated
        }
    }        
}


# Finds packages by given name and version information. 
function Find-Package { 
    param(
        [string] $Name,
        [string] $RequiredVersion,
        [string] $MinimumVersion,
        [string] $MaximumVersion
    )

    Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Find-Package'))

    $ValidationResult = Validate-VersionParameters -Name $Name `
                                                    -MinimumVersion $MinimumVersion `
                                                    -MaximumVersion $MaximumVersion `
                                                    -RequiredVersion $RequiredVersion `
                                                    -AllVersions:$request.Options.ContainsKey($script:AllVersions)
    
    if(-not $ValidationResult)
    {
        # Return now as the version validation failed already
        return
    }    
    
    $force = Get-ForceProperty
    if(-not (Install-ChocoBinaries -Force $force)) { return }    
    
    # For some reason, we have to convert it to array to make the following choco.exe cmd to work
    $additionalArgs = Get-AdditionalArguments
    $args = if($additionalArgs) {$additionalArgs.Split(' ')}
    $nameContainWildCard = $false
    $FindPackageParentId = 10       
    $filterRequired = $false
    $options = $request.Options
    foreach( $o in $options.Keys )
    {
        Write-Debug ( "$script:PackageSourceName - OPTION: {0} => {1}" -f ($o, $options[$o]) )
    }

    if (-not $name)
    {
        # a user does not provide name, search the entire repo        
        Write-Error ( $LocalizedData.SearchingEntireRepo)
        return
    }
    
    
    # a user specifies -Name
    $progress = 5
    Write-Progress -Activity $LocalizedData.SearchingForPackage -PercentComplete $progress -Id $FindPackageParentId
                 
    if(Test-WildcardPattern -Name $Name)
    {
        # name contains wildcard
        $nameContainWildCard = $true
        Write-Debug ("$script:ChocoExePath search $name $additionalArgs")            
        $packages = & $script:ChocoExePath search $name $args
    }        
    elseif((-not $requiredVersion) -and (-not $minimumVersion) -and (-not $maximumVersion))
    {
        # a user does not provide version, return the latest version
            Write-Debug ("$script:ChocoExePath search $name $additionalArgs")
            $packages = & $script:ChocoExePath search $name $args  #--exact
            
    }
    elseif($options.ContainsKey($script:AllVersions))
    {
        # a user provides allversion
        Write-Debug ("$script:ChocoExePath search $name --allversions $additionalArgs")
        $packages = & $script:ChocoExePath search $name --allversions $args
    }
    else
    {
        # a user provides any of these: $requiredVersion, $minimumVersion, $maximumVersion.
        # as choco does not support version search, we will find all allversions first and 
        # will perform filter later
        Write-Debug ("$script:ChocoExePath search $name --allversions $additionalArgs")
        $packages = & $script:ChocoExePath search $name --allversions $args
        $filterRequired = $true
    }         
    

    foreach ($pkg in $packages)
    {
        $progress += 5
        $progress= [System.Math]::Min(100, $progress)

        Write-Progress -Activity $LocalizedData.ProcessingPackage -PercentComplete $progress -Id $FindPackageParentId
        
        if($request.IsCanceled) { return }     
        $Matches = $null             

        if (($pkg -like "*Approved*") -and ($pkg -match $script:PackageRegex))
        {
            Write-Debug ("Found a package '{0}'" -f $pkg)

            $pkgname = $Matches.name
            $pkgversion = $Matches.version


            if (-not (Test-Name -Name $name -PackageName $pkgname -NameContainsWildcard $nameContainWildCard))
            {
                continue
            }
           
            if ($pkgname -and $pkgversion)
            {
                 # filter on version
                 if(-not $filterRequired -or  (Test-Version `
                                                -Version $pkgversion `
                                                -RequiredVersion $requiredVersion `
                                                -MinimumVersion $minimumVersion `
                                                -MaximumVersion $maximumVersion ))
                 {                                  
                    $swidObject = @{
                        FastPackageReference = $pkgname+"#" + $pkgversion;
                        Name = $pkgname;
                        Version = $pkgversion;
                        versionScheme  = "MultiPartNumeric";
                        Source = $script:PackageSource;              
                        }

                    $sid = New-SoftwareIdentity @swidObject              
                    Write-Output -InputObject $sid   
                } 
            }
        }
    }
    
    Write-Progress -Activity $LocalizedData.Complete -PercentComplete 100 -Completed -Id $FindPackageParentId               
}                    
  

# This function is called by OneGet while a user types Save-Package.
function Download-Package
{ 
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FastPackageReference,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location
    )
   
    Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Download-Package'))
  
    Write-Warning $LocalizedData.SavePackageNotSupported -f $script:ProviderName        
}

# It is required to implement this function for the providers that support install-package. 
function Install-Package
{ 
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $fastPackageReference
    )

    Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Install-Package'))  
    Write-Debug -Message ($LocalizedData.FastPackageReference -f $fastPackageReference)

    $force = Get-ForceProperty
    $InstallPackageId = 11

    # Check the source location
    if(-Not $fastPackageReference)
    {
        ThrowError -ExceptionName "System.ArgumentException" `
            -ExceptionMessage ($LocalizedData.PathNotFound -f ($fastPackageReference)) `
            -ErrorId "PathNotFound" `
            -CallerPSCmdlet $PSCmdlet `
            -ErrorCategory InvalidArgument `
            -ExceptionObject $fastPackageReference
    }

    $additionalArgs = Get-AdditionalArguments
    $additionalArgs = if($additionalArgs) {$additionalArgs.Split(' ')}
    $Matches = $null
    $isMatch = $fastPackageReference  -match $script:FastReferenceRegex

    if (-not $isMatch)
    {
        write-error ($LocalizedData.FailToInstall -f $fastPackageReference)  
        return
    }

    $name =$matches.name
    $version = $Matches.version

    if (-not ($name -and $version))
    {
        write-error ($LocalizedData.FailToInstall -f $fastPackageReference)  
        return
    }
                 
    $shouldContinueQueryMessage = "Installing package '{0}'. By installing you accept licenses for the package(s). The package possibly needs to run 'chocolateyInstall.ps1'" -f $fastPackageReference  
    $shouldContinueCaption = "Are you sure you want to perform this action?"
    

    if(-not ($Force -or $request.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption)))
    {
        
        Write-Warning ($LocalizedData.NotInstalled -f $fastPackageReference)  
        return       
    }    
           
 
    if($force)
    {
        $installCmd=@("install", $name, "--version", $version,  "-y",  "-force")
    }
    else
    {
        $installCmd=@("install", $name, "--version", $version,  "-y")
    }

    Write-debug  ("Calling $installCmd $additionalArgs")
    $progress = 1         
    $job=Start-Job -ScriptBlock {
           & $args[0] $args[1] $args[2]
       } -ArgumentList @($script:ChocoExePath, $installCmd, $additionalArgs)

    Show-Progress -ProgressMessage $LocalizedData.InstallingPackage  -PercentComplete $progress -ProgressId $InstallPackageId 
    $packages= $job | Receive-Job -Wait   
    Process-Package -Name $name `
                     -RequiredVersion $version `
                     -OperationMessage $LocalizedData.InstallingPackage `
                     -ProgressId $InstallPackageId `
                     -PercentComplete $progress `
                     -Packages $packages  
 }

# It is required to implement this function for the providers that support UnInstall-Package. 
function UnInstall-Package
{ 
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FastPackageReference
    )

    Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Uninstall-Package'))
    Write-Debug -Message ($LocalizedData.FastPackageReference -f $FastPackageReference)
      
    $UnInstallPackageId = 12
    $force = Get-ForceProperty
    $Matches = $null
    $isMatch = $FastPackageReference -match $script:FastReferenceRegex

    if (-not $isMatch)
    {
        write-error ($LocalizedData.FailToInstall -f $fastPackageReference)  
        return
    }

    $name =$matches.name
    $version = $Matches.version

    if (-not ($name -and $version))
    {
        write-error ($LocalizedData.FailToInstall -f $fastPackageReference)  
        return
    } 

    # Choco will prompt to confirm whether it wants to uninstall dependencies
    # a user can pass in  -y --remove-dependencies  option to avoid hanging
    # only provides '--yes' does not suppress prompts
    $additionalArgs = Get-AdditionalArguments
    $args = $additionalArgs
    if($args) {$args = $additionalArgs.Split(' ')}
    
    if($request.Options.ContainsKey($script:AllVersions))
    {
        $unInstallCmd=@("uninstall", $name, $additionalArgs, "--all-versions")
    }
    else
    {
        $unInstallCmd=@("uninstall", $name, "--version", $version)        
    }  
   
    Write-debug  ("calling $script:ChocoExePath $unInstallCmd $additionalArgs")       
    $progress = 1         
    $job=Start-Job -ScriptBlock {
           & $args[0] $args[1] $args[2]
       } -ArgumentList @($script:ChocoExePath, $unInstallCmd, $args)

    Show-Progress -ProgressMessage $LocalizedData.UnInstallingPackage  -PercentComplete $progress -ProgressId $UnInstallPackageId 
    $packages= $job | Receive-Job -Wait   
    Write-debug  ("Completed calling $script:ChocoExePath $unInstallCmd")   
    
    Process-Package -Name $name `
                    -RequiredVersion $version `
                    -OperationMessage $LocalizedData.UnInstallingPackage `
                    -ProgressId $UnInstallPackageId `
                    -PercentComplete $progress -Packages $packages `
                    -NameContainsWildCard $true   # pass in $true so that we do not exact name match because choco returns different sometimes.
        
}


# Returns the packages that are installed.
function Get-InstalledPackage
{ 
    [CmdletBinding()]
    param
    (
        [Parameter()]
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

    Write-Debug -Message ($LocalizedData.ProviderDebugMessage -f ('Get-InstalledPackage'))

    $ValidationResult = Validate-VersionParameters  -Name $Name `
                                                    -MinimumVersion $MinimumVersion `
                                                    -MaximumVersion $MaximumVersion `
                                                    -RequiredVersion $RequiredVersion `
                                                    -AllVersions:$request.Options.ContainsKey($script:AllVersions)
    if(-not $ValidationResult)
    {
        # Return now as the version validation failed already
        return
    } 

    $installedPackageId = 15 
    $force = Get-ForceProperty
    if(-not (Install-ChocoBinaries -Force $force)) { return }    
    $nameContainsWildCard = $false
    $additionalArgs = Get-AdditionalArguments
    $args = if($additionalArgs) {$additionalArgs.Split(' ')}

    Write-Progress -Activity $LocalizedData.FindingLocalPackage -PercentComplete 30  -Id $installedPackageId 

    # If a user does not provide name or name contains wildcard, search all.
    # Choco does not support wildcard if searching local only 
    if (-not $Name -or (Test-WildcardPattern -Name $Name))
    {
        $nameContainsWildCard = $true
        Write-Debug "calling $script:ChocoExePath search --local-only --allversions $additionalArgs"    
        $packages = & $script:ChocoExePath search --local-only --allversions $args
    }
    else
    {
        Write-Debug "calling $script:ChocoExePath search $Name --local-only --allversions $additionalArgs"
        $packages = & $script:ChocoExePath search $Name --local-only --allversions $args
    }
   
    Process-Package -Name $Name -ProgressId $installedPackageId `
                    -RequiredVersion $RequiredVersion `
                    -MinimumVersion $MinimumVersion `
                    -MaximumVersion $MaximumVersion `
                    -PercentComplete 20 `
                    -Packages $packages `
                    -NameContainsWildCard $nameContainsWildCard
    Write-Progress -Activity $LocalizedData.Complete -PercentComplete 100 -Completed -Id $installedPackageId    
}

#endregion


#region Helper functions

# Display progress bar
function Show-Progress
{
    [CmdletBinding()]
    param
    (
        [parameter()]
        [string]
        $ProgressMessage,
        [parameter()]
        [int]
        $PercentComplete,
        [parameter()]
        [int]
        $ProgressId
    )

    $progress = $PercentComplete
    While(Get-Job -State 'Running')
    {
        Start-Sleep -Milliseconds 1000        
        Write-Progress -Activity $ProgressMessage -PercentComplete $progress -Id $ProgressId 
            
        if($progress -ge 100)
        { 
            $progress = 100
        }
        else {$progress = 0.5 + $progress}         
    }
        
}

# Processing the package
function Process-Package
{
    [CmdletBinding()]
    param
    (
        [parameter()]
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
        $MaximumVersion,
        [parameter()]
        [string]
        $OperationMessage,
        [parameter()]
        [int]
        $ProgressId,
        [parameter()]
        [int]
        $PercentComplete,
        [parameter()]
        [string[]]
        $Packages,
        [parameter()]
        [bool]
        $NameContainsWildCard = $false
    )
  

    $progress = $PercentComplete  
    $actionTaken = $false
             
    foreach ($pkg in $packages)
    {
        if($request.IsCanceled) { return } 
        $progress += 5
        $progress = [System.Math]::Min(100, $progress)
        Write-Progress -Activity $LocalizedData.ProcessingPackage -PercentComplete $progress -Id $ProgressId 
                
        $Matches = $null
        if (($pkg -match $script:PackageRegex) -and ($pkg -notmatch $script:PackageReportRegex))
        {           
            $pkgname = $Matches.name
            $pkgversion = $Matches.version

            Write-Debug ("Choco message: '{0}'" -f $pkg)

            # check name match
            if(-not (Test-Name -Name $name -PackageName $pkgname -NameContainsWildcard $NameContainsWildCard))
            {
                Write-Debug ("Skipping processing: '{0}'" -f $pkg)
                continue
            }
             
            if ($pkgname -and $pkgversion)
            {
                    # filter on version
                    if((Test-Version -Version $pkgversion.TrimStart('v') `
                                     -RequiredVersion $requiredVersion `
                                     -MinimumVersion $minimumVersion `
                                     -MaximumVersion $maximumVersion ))
                    {                                  
                        $swidObject = @{
                            FastPackageReference = $pkgname+"#" + $pkgversion;
                            Name = $pkgname;
                            Version = $pkgversion;
                            versionScheme  = "MultiPartNumeric";
                            Source = $script:PackageSource;              
                            }

                        $sid = New-SoftwareIdentity @swidObject              
                        Write-Output -InputObject $sid   
                        if(-Not $actionTaken) {$actionTaken = $true}
                    } 
            }
        }

    }
    
    if ($OperationMessage)
    {
        if($actionTaken)
        {
            Write-Verbose ($LocalizedData.OperationSucceed -f $OperationMessage, $FastPackageReference) 
        }
        else
        {
            Write-Error ($LocalizedData.OperationFailed -f $OperationMessage, $FastPackageReference)             
        }
    }   
    
    Write-Progress -Activity $LocalizedData.Complete -PercentComplete 100 -Completed -Id $ProgressId                                                                       
}

# Get AdditionalArguments property from the input cmdline
function Get-AdditionalArguments
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
    )

    $additionalArgs = $null
    $options = $request.Options

    if($options.ContainsKey($script:additionalArguments))
	{	
		$additionalArgs = $options[$script:additionalArguments]
    }

    return $additionalArgs
}

# Filter on name
function Test-Name
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [string]
        $Name,
        [string]
        $PackageName,
        [bool]
        $NameContainsWildcard
    )

    $nameRegex=$Name.TrimStart('*')
    $nameRegex=$nameRegex.TrimEnd('.')
    $nameRegex="^.*$nameRegex.*$"

    # filter on name
    if ($Name -and $PackageName -and ($PackageName -notmatch "$nameRegex"))
    {
        return $false
    }
            
    # exact name match
    if($Name -and $PackageName -and (-not $NameContainsWildcard) -and ($Name -ne $PackageName))
    {
        return $false
    }

    return $true
}

# Find whether a user specifies -force
function Get-ForceProperty
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
    )

    $force = $false 
    $options = $request.Options 
    if($options.ContainsKey('Force')) 
    { 
        $force = (-not [System.String]::IsNullOrWhiteSpace($options['Force']))
    }
    
    return $force

}

# Install choco
function Install-ChocoBinaries
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [parameter()]
        [bool]
        $Force
    )

    if ($script:isNanoServer)
    {
        Write-Error ($LocalizedData.ChocoUnSupportedOnNano -f $script:ProviderName)
        return $false
    }
  
    if($script:ChocoExePath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:ChocoExePath))
    {
        Write-Debug ("Choco already installed in '{0}'" -f $script:ChocoExePath)
        return $true
    }
   
    # Setup $script:ChocoExePath
    if (Get-ChocoPath)
    {
        Write-Debug ("Choco already installed in '{0}'" -f $script:ChocoExePath)
        return $true
    }
     
    # Should continue message for bootstrapping only NuGet.exe
    $shouldContinueQueryMessage = $LocalizedData.InstallChocoExeShouldContinueQuery
    $shouldContinueCaption = $LocalizedData.InstallChocoExeShouldContinueCaption
    

    if($Force -or $request.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption))
    {
        # install choco based on https://chocolatey.org/install#before-you-install
        Invoke-WebRequest 'https://chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression        
    }


    if (Get-ChocoPath)
    {
        return $true
    }
    else
    {
        # Throw the error message if one of the above conditions are not met
        ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $LocalizedData.FailToInstallChoco `
                    -ErrorId $errorId `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation

    }

    return $false
}

# Get the choco installed path
function Get-ChocoPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
    )

    # Using Get-Command cmdlet, get the location of Choco.exe if it is available under $env:PATH.           
    $chocoCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:ChocoExeName `
                                                        -ErrorAction SilentlyContinue `
                                                        -WarningAction SilentlyContinue | 
                    Microsoft.PowerShell.Core\Where-Object { 
                        $_.Path -and 
                        ((Microsoft.PowerShell.Management\Split-Path -Path $_.Path -Leaf) -eq $script:ChocoExeName) -and
                        (-not $_.Path.StartsWith($env:windir, [System.StringComparison]::OrdinalIgnoreCase)) 
                    } | Microsoft.PowerShell.Utility\Select-Object -First 1

    if($chocoCmd -and $chocoCmd.Path)
    {
        $script:ChocoExePath = $chocoCmd.Path
        $BootstrapChocoExe = $false
        Write-Verbose ($LocalizedData.ChocoFound -f $script:ChocoExePath)
    }
    else
    {
        return $null
    }

    return $chocoCmd.Path
}

# Check whether $version meets the criteria defined in $RequiredVersion, $MinimumVersion and $MaximumVersion
function Test-Version
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $Version,
         
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


    if(-not ($RequiredVersion -or $MinimumVersion -or $MaximumVersion))
    {
        return $true
    }

    if($RequiredVersion)
    {
        return  ($Version -eq $RequiredVersion)
    }

    $isMatch = $false

    if($MinimumVersion)
    {
        $isMatch = $Version -ge $MinimumVersion
    }

    if($MaximumVersion)
    {
        if($MinimumVersion)
        {
            $isMatch = $isMatch -and ($Version -le $MaximumVersion)        
        }
        else
        {
            $isMatch = $Version -le $MaximumVersion  
        }     
    }

    return $isMatch  
}

# Test if the $Name contains any wildcard characters
function Test-WildcardPattern
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $Name
    )

    return [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)    
}

# Validate versions
function Validate-VersionParameters
{
    Param(

        [Parameter()]
        [String[]]
        $Name,

        [Parameter()]
        [String]
        $MinimumVersion,

        [Parameter()]
        [String]
        $RequiredVersion,

        [Parameter()]
        [String]
        $MaximumVersion,

        [Parameter()]
        [Switch]
        $AllVersions
    )

    if($AllVersions -and ($RequiredVersion -or $MinimumVersion -or $MaximumVersion))
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.AllVersionsCannotBeUsedWithOtherVersionParameters `
                   -ErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters' `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument
    }
    elseif($RequiredVersion -and ($MinimumVersion -or $MaximumVersion))
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.VersionRangeAndRequiredVersionCannotBeSpecifiedTogether `
                   -ErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether" `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument
    }
    elseif($MinimumVersion -and $MaximumVersion -and ($MinimumVersion -gt $MaximumVersion))
    {
        $Message = $LocalizedData.MinimumVersionIsGreaterThanMaximumVersion -f ($MinimumVersion, $MaximumVersion)
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $Message `
                    -ErrorId "MinimumVersionIsGreaterThanMaximumVersion" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument
    }
    elseif($AllVersions -or $RequiredVersion -or $MinimumVersion -or $MaximumVersion)
    {
        if(-not $Name -or $Name.Count -ne 1 -or (Test-WildcardPattern -Name $Name[0]))
        {
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $LocalizedData.VersionParametersAreAllowedOnlyWithSingleName `
                       -ErrorId "VersionParametersAreAllowedOnlyWithSingleName" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument
        }
    }

    return $true
}

# Utility to throw an errorrecord
function ThrowError
{
    param
    (        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]        
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,
        
        [System.Object]
        $ExceptionObject,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
        
    $exception = New-Object $ExceptionName $ExceptionMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorId, $ErrorCategory, $ExceptionObject    
    $CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}

#endregion
