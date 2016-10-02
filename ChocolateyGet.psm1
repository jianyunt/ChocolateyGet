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
$script:firstTime = $true

# Utility variables 
$script:PackageRegex = "(?<name>[^\s]*)(\s*)(?<version>[^\s]*)"
$script:PackageReportRegex="^[0-9]*(\s*)(packages installed)"
$script:FastReferenceRegex = "(?<name>[^#]*)#(?<version>[^\s]*)"

$script:FindPackageId = 10 
$script:InstallPackageId = 11
$script:UnInstallPackageId = 12
$script:InstalledPackageId = 15 
$script:InstallChocoId = 16 

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
    Write-Progress -Activity $LocalizedData.SearchingForPackage -PercentComplete $progress -Id $script:FindPackageId
                 
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

        Write-Progress -Activity $LocalizedData.ProcessingPackage -PercentComplete $progress -Id $script:FindPackageId
        
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
    
    Write-Progress -Activity $LocalizedData.Complete -PercentComplete 100 -Completed -Id $script:FindPackageId               
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
                 
    $shouldContinueQueryMessage = ($LocalizedData.InstallPackageQuery -f "Installing", $name)  
    $shouldContinueCaption = $LocalizedData.InstallPackageCaption
    

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

    Show-Progress -ProgressMessage $LocalizedData.InstallingPackage  -PercentComplete $progress -ProgressId $script:InstallPackageId 
    $packages= $job | Receive-Job -Wait   
    Process-Package -Name $name `
                     -RequiredVersion $version `
                     -OperationMessage $LocalizedData.InstallingPackage `
                     -ProgressId $script:InstallPackageId `
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

    Show-Progress -ProgressMessage $LocalizedData.UnInstallingPackage  -PercentComplete $progress -ProgressId $script:UnInstallPackageId 
    $packages= $job | Receive-Job -Wait   
    Write-debug  ("Completed calling $script:ChocoExePath $unInstallCmd")   
    
    Process-Package -Name $name `
                    -RequiredVersion $version `
                    -OperationMessage $LocalizedData.UnInstallingPackage `
                    -ProgressId $script:UnInstallPackageId `
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

    $force = Get-ForceProperty
    if(-not (Install-ChocoBinaries -Force $force)) { return }    
    $nameContainsWildCard = $false
    $additionalArgs = Get-AdditionalArguments
    $args = if($additionalArgs) {$additionalArgs.Split(' ')}

    Write-Progress -Activity $LocalizedData.FindingLocalPackage -PercentComplete 30  -Id $script:InstalledPackageId 

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
   
    Process-Package -Name $Name -ProgressId $script:InstalledPackageId `
                    -RequiredVersion $RequiredVersion `
                    -MinimumVersion $MinimumVersion `
                    -MaximumVersion $MaximumVersion `
                    -PercentComplete 20 `
                    -Packages $packages `
                    -NameContainsWildCard $nameContainsWildCard
    Write-Progress -Activity $LocalizedData.Complete -PercentComplete 100 -Completed -Id $script:InstalledPackageId    
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

    if($PSEdition -Match 'Core')
    {
        Write-Error ($LocalizedData.ChocoUnSupportedOnCoreCLR -f $script:ProviderName)
        return $false
    }
  
    if($script:ChocoExePath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:ChocoExePath))
    {
        Write-Debug ("Choco already installed in '{0}'" -f $script:ChocoExePath)
        return $true
    }
   
    # Setup $script:ChocoExePath
    if ((Get-ChocoPath) -and $script:ChocoExePath)
    {
        Write-Debug ("Choco already installed in '{0}'" -f $script:ChocoExePath)
        
        if(-not $script:firstTime) 
        {
            $script:firstTime = $false
            return $true
        }

        $progress = 5
        Write-Progress -Activity $LocalizedData.CheckingChoco -PercentComplete $progress -Id $script:InstallChocoId
        
        # For the first time in the current PowerShell Session, we check choco version to see if upgrade is needed 
        $name = "Chocolatey"  
        Write-Debug ("$script:ChocoExePath search $name")      
        $packages = & $script:ChocoExePath search $name
        
        $progress += 5  
        Write-Progress -Activity $LocalizedData.CheckingChoco -PercentComplete $progress -Id $script:InstallChocoId 

                     
        foreach ($pkg in $packages)
        {
            if($request.IsCanceled) { return } 
                      
            $Matches = $null
            if (($pkg -match $script:PackageRegex) -and ($pkg -notmatch $script:PackageReportRegex))
            {           
                $pkgname = $Matches.name
                $pkgversion = $Matches.version

                Write-Debug ("Choco message: '{0}'" -f $pkg)

                # check name match
                if(-not (Test-Name -Name $name -PackageName $pkgname))
                {
                    Write-Debug ("Skipping processing: '{0}'" -f $pkg)
                    continue
                }
             
                if ($pkgname -and $pkgversion)
                {
                    $installedVersion = Get-InstalledChocoVersion
                    
                    $progress += 5    
                    Write-Progress -Activity $LocalizedData.CheckingChoco -PercentComplete $progress -Id $script:InstallChocoId 

                    if((Compare-SemVer -Version1 $pkgversion.Trim('v') -Version2 $installedVersion) -eq 1)
                    {
                        # There is a newer version of Chocolatey available
                        Write-Verbose ($LocalizedData.FoundNewerChocolatey -f $pkgversion, $installedVersion) 

                        # Should continue message for upgrading Choco.exe
                        $shouldContinueQueryMessageUpgrade = ($LocalizedData.UpgradePackageQuery -f $pkgversion)
                        $shouldContinueCaptionUpgrade = ($LocalizedData.InstallPackageQuery -f "Upgrading", $name)  

                        if($Force -or $request.ShouldContinue($shouldContinueQueryMessageUpgrade, $shouldContinueCaptionUpgrade))
                        {
                            Write-Progress -Activity $LocalizedData.UpgradingChoco -PercentComplete $progress -Id $script:InstallChocoId 

                            Write-Debug ("Calling $script:ChocoExePath upgrade chocolatey")                               
                            $job=Start-Job -ScriptBlock {
                                   & $args[0] upgrade chocolatey -y
                               } -ArgumentList @($script:ChocoExePath)

                            Show-Progress -ProgressMessage $LocalizedData.UpgradingChoco `
                                          -PercentComplete $progress `
                                          -ProgressId $script:InstallChocoId 

                            $packages= $job | Receive-Job -Wait   
                            Process-Package -Name $name `
                                             -RequiredVersion $pkgversion `
                                             -OperationMessage $LocalizedData.UpgradingChoco `
                                             -ProgressId $script:InstallChocoId `
                                             -PercentComplete $progress `
                                             -Packages $packages     
                        }
                    }
                    else
                    {
                        Write-Debug ("Current version of chocolatey is up to date")
                    }
                    
                    break                  
                }               
            }
        } # foreach

        Write-Progress -Activity $LocalizedData.Complete -PercentComplete 100 -Completed -Id $script:InstallChocoId 
        return $true
    }                    
     
    # Should continue message for installing Choco.exe
    $shouldContinueQueryMessage = $LocalizedData.InstallChocoExeShouldContinueQuery
    $shouldContinueCaption = $LocalizedData.InstallChocoExeShouldContinueCaption
         
    if(-not $Force)
    {
        $continue = $request.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption)
        if(-not $continue)
        {
            Write-Error ($LocalizedData.UserDeclined -f "install")
            return $false
        }
    }

    # install choco based on https://chocolatey.org/install#before-you-install
    try{
        Invoke-WebRequest 'https://chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression  > $null
    } 
    catch
    {
        if($error[0])
        {
            Write-Error $error[0]
        }
    } 

    if (Get-ChocoPath)
    {
        return $true
    }
    else
    {
        Write-Error ($LocalizedData.FailToInstallChoco)         
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

function Get-InstalledChocoVersion
{
    $name = "Chocolatey"
    $installedChocoVersion = $null

    Write-Debug ("Calling $script:ChocoExePath search chocolatey --local-only")  
    $packages = & $script:ChocoExePath search chocolatey --local-only 
    
    foreach ($pkg in $packages)
    {
        if($request.IsCanceled) { return } 
                      
        $Matches = $null
        if (($pkg -match $script:PackageRegex) -and ($pkg -notmatch $script:PackageReportRegex))
        {           
            $pkgname = $Matches.name
            $pkgversion = $Matches.version

            Write-Debug ("Choco message: '{0}'" -f $pkg)

            # check name match
            if(-not (Test-Name -Name $name -PackageName $pkgname))
            {
                Write-Debug ("Skipping processing: '{0}'" -f $pkg)
                continue
            }
             
            if ($pkgname -and $pkgversion)
            {
                $installedChocoVersion = $pkgversion.Trim('v')                  
                break                  
            }               
        }
    } # foreach

    return $installedChocoVersion   
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


#region Semversion variables
$AllowFourPartsVersion = "(?<Version>\d+(\s*\.\s*\d+){0,3})";
$ThreePartsVersion = "(?<Version>\d+(\.\d+){2})";
# the pre-release regex is of the form -<pre-release version> where <pre-release> version is set of identifier 
# delimited by ".". Each identifer can be any characters in [A-z0-9a-z-]
$ReleasePattern = "(?<Release>-[A-Z0-9a-z\-]+(\.[A-Z0-9a-z\-]+)*)?";

# The build regex is of the same form except with a + instead of -
$BuildPattern = "(?<Build>\+[A-Z0-9a-z\-]+(\.[A-Z0-9a-z\-]+)*)?";
 
# For some reason Chocolatey version uses "-" instead of "+" for the build metadata. Here change it to "-"       
$ReleasePatternDash = "(?<Release>-[A-Z0-9a-z]+(\.[A-Z0-9a-z]+)*)?";
$BuildPatternDash = "(?<Build>\-[A-Z0-9a-z\-]+(\.[A-Z0-9a-z\-]+)*)?";

# Purposely this should be the regex
$SemanticVersionPattern = "^" + $AllowFourPartsVersion + $ReleasePattern +$BuildPattern + "$"

# But we use this one because Chocolatey uses <version>-<release>-<build> format
$SemanticVersionPatternDash = "^" + $AllowFourPartsVersion + $ReleasePatternDash + $BuildPatternDash + "$"

#endregion

# Compare two sematic verions
# -1 if $Version1 < $Version2
# 0  if $Version1 = $Version2
# 1  if $Version1 > $Version2
function Compare-SemVer
{
    [CmdletBinding()]
    [OutputType([int])]

    param(
    [string]
    $Version1,
    [string]
    $Version2
    )

    $versionObject1 = Get-VersionPSObject $Version1
    $versionObject2 = Get-VersionPSObject $Version2

    if((-not $versionObject1) -and (-not $versionObject2))
    {
        return 0
    }

    if((-not $versionObject1) -and ($versionObject2))
    {
        return -1
    }

    if(($versionObject1) -and (-not $versionObject2))
    {
        return 1
    }

    $VersionResult = ([Version]$versionObject1.Version).CompareTo([Version]$versionObject2.Version)
    if($VersionResult -ne 0)
    {
        return $VersionResult
    }

    if($versionObject1.Release -and (-not $versionObject2.Release))
    {
        return -1
    }

    if(-not $versionObject1.Release -and $versionObject2.Release)
    {
        return 1
    }


    $ReleaseResult = Compare-ReleaseMetadata -Version1Metadata $versionObject1.Release  -Version2Metadata $versionObject2.Release    
    return $ReleaseResult
    
    # Based on http://semver.org/, Build metadata SHOULD be ignored when determining version precedence    
 }


function Get-VersionPSObject
{
    param(
    [Parameter(Mandatory=$true)]
    [string]
    $Version
    )

    $isMatch=$Version.Trim() -match $SemanticVersionPatternDash 
    if($isMatch)
    {            
        if ($Matches.Version) {$v = $Matches.Version.Trim()} else {$v = $Matches.Version}
        if ($Matches.Release) {$r = $Matches.Release.Trim("-, +")} else {$r = $Matches.Release} 
        if ($Matches.Build) {$b = $Matches.Build.Trim("-, +")} else {$b = $Matches.Build}  

        return New-Object PSObject -Property @{ 
            Version = $v
            Release = $r
            Build = $b
        }
    }
    else
    {
        ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage ($LocalizedData.InvalidVersionFormat -f $Version, $SemanticVersionPatternDash) `
                    -ErrorId "InvalidVersionFormat" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation
    }   
 }

 
 function Compare-ReleaseMetadata
 {
    [CmdletBinding()]
    [OutputType([int])]

    param(
    [string]
    $Version1Metadata,
    [string]
    $Version2Metadata
    )

    if((-not $Version1Metadata) -and (-not $Version2Metadata))
    {
        return 0
    }

    # For release part, 1.0.0 is newer/greater then 1.0.0-alpha. So return 1 here.
    if((-not $Version1Metadata) -and $Version2Metadata)
    {
        return 1
    }

    if(($Version1Metadata) -and (-not $Version2Metadata))
    {
        return -1
    }

    $version1Parts=$Version1Metadata.Trim('-').Split('.')
    $version2Parts=$Version2Metadata.Trim('-').Split('.')

    $length = [System.Math]::Min($version1Parts.Length, $version2Parts.Length)

    for ($i = 0; ($i -lt $length); $i++)
    {
        $result = Compare-MetadataPart -Version1Part $version1Parts[$i] -Version2Part $version2Parts[$i]

        if ($result -ne 0)
        {
            return $result
        }
    }

    # so far we found two versions are the same. If length is the same, we think two version are indeed the same
    if($version1Parts.Length -eq $version1Parts.Length)
    {
        return 0
    }

    # 1.0.0-alpha < 1.0.0-alpha.1
    if($version1Parts.Length -lt $length)
    {
        return -1
    }
    else
    {
        return 1
    }
 }


 function Compare-MetadataPart
 {
    [CmdletBinding()]
    [OutputType([int])]

    param(
    [string]
    $Version1Part,
    [string]
    $Version2Part
    )

    if((-not $Version1Part) -and (-not $Version2Part))
    {
        return 0
    }

    # For release part, 1.0.0 is newer/greater then 1.0.0-alpha. So return 1 here.
    if((-not $Version1Part) -and $Version2Part)
    {
        return 1
    }

    if(($Version1Part) -and (-not $Version2Part))
    {
        return -1
    }

    $version1Num = 0
    $version2Num = 0

    $v1IsNumeric = [System.Int32]::TryParse($Version1Part, [ref] $version1Num);
    $v2IsNumeric = [System.Int32]::TryParse($Version2Part, [ref] $version2Num);

    $result = 0
    # if both are numeric compare them as numbers
    if ($v1IsNumeric -and $v2IsNumeric)
    {
       $result = $version1Num.CompareTo($version2Num);
    }   
    elseif ($v1IsNumeric -or $v2IsNumeric)
    {
        # numeric numbers come before alpha chars
        if ($v1IsNumeric) { return -1 }
        else { return 1 }
    }
    else
    {
         $result = [string]::Compare($Version1Part, $Version2Part)
    }

    return $result
 }


#endregion


#Export-ModuleMember -Function Compare-SemVer
