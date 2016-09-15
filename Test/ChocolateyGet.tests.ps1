
$ChocolateyGet = "ChocolateyGet"

import-module packagemanagement
Get-Packageprovider -verbose
$provider = Get-PackageProvider -verbose -ListAvailable
if($provider.Name -notcontains $ChocolateyGet)
{
    $a= Find-PackageProvider -Name $ChocolateyGet -verbose -ForceBootstrap

    if($a.Name -eq $ChocolateyGet)
    {
        Install-PackageProvider $ChocolateyGet -verbose -force
    }
    else
    {
        Write-Error "Fail to find $ChocolateyGet provider"
    }
}

Import-PackageProvider $ChocolateyGet -force

Describe "ChocolateyGet Version testing" -Tags @('BVT', 'DRT') {
    BeforeAll { 
        Import-Module ChocolateyGet
    }
    AfterAll {
        #reset the environment variable
       $env:BootstrapProviderTestfeedUrl=""
    }
    It "SemVer testing" {
        $version1="0.9.9 "
        $version2="0.9.9"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 0

        $version1="0.9.9-rc2"
        $version2="0.9.9-rc2"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 0

        $version1="1.0.0-beta-exp.sha.5114f85"
        $version2="1.0.0-beta-exp.sha.5114f85"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 0


        $version1="1.0.0-alpha-exp.sha.5114f85"
        $version2="1.0.0-beta-exp.sha.5114f85"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be -1


        $version1="1.0.0-alpha-exp.sha.5114f86"
        $version2="1.0.0-alpha-exp.sha.5114f85"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 0
   
        $version1="1.0.0-alpha-exp.sha1.5114f85"
        $version2="1.0.0-alpha-exp.sha.5114f85"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 0

        $version1="0.9.9 "
        $version2="0.9.9-rc2"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 1

        $Version1 = "1.1"
        $version2="1.1.1"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be -1

        $Version1 = "1.2.5"
        $version2="1.2.3.4"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 1

        $version1="1.0.0-alpha.1"
        $version2="1.0.0-alpha.beta"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be -1

        $version1="1.0.0-alpha.beta"
        $version2="1.0.0-rc.1"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be -1

        $version1="1.0.0"
        $version2="1.0.0-rc.11"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 1

        $version1="1.0.0-rc.1"
        $version2="2.0.0"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be -1

        $version1="1.0.0-beta.2"
        $version2="1.0.0-beta.11"
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be -1

        $version1="0.9.10-rc1" 
        $version2="0.9.10" 
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be -1

        $Version1= "0.9.10-beta-20160528" 
        $Version2= "0.9.10-alpha-20160528" 
        $a= ChocolateyGet\Compare-SemVer -Version1  $Version1  -Version2  $Version2
        $a | should be 1
    }
}


Describe "ChocolateyGet testing" -Tags @('BVT', 'DRT') {
    AfterAll {
        #reset the environment variable
       $env:BootstrapProviderTestfeedUrl=""
    }

    It "find-package" {

        $a=find-package -ProviderName $ChocolateyGet -name  nodejs -ForceBootstrap -force
        $a | ?{ $_.name -eq "nodejs" } | should not BeNullOrEmpty
        
        $b=find-package -ProviderName $ChocolateyGet -name  nodejs -allversions
        $b | ?{ $_.name -eq "nodejs" } | should not BeNullOrEmpty


        $c=find-package -ProviderName $ChocolateyGet -name nodejs -AdditionalArguments --exact
        $c | ?{ $_.name -eq "nodejs" } | should not BeNullOrEmpty        
    }

    It "find-package with wildcard search" {

        $d=find-package -ProviderName $ChocolateyGet -name *firefox*
        $d | ?{ $_.name -eq "firefox" } | should not BeNullOrEmpty
        
    }

    It "find-install-package nodejs" {

        $package = "nodejs"
        $a=find-package $package -verbose -provider $ChocolateyGet  -AdditionalArguments --exact | install-package -force
        $a.Name -contains $package | Should Be $true


        $b = get-package $package -verbose -provider $ChocolateyGet
        $b.Name -contains $package | Should Be $true

        $c= Uninstall-package $package -verbose  -ProviderName $ChocolateyGet -AdditionalArguments '-y --remove-dependencies'
        $c.Name -contains $package | Should Be $true
   }

   It "install-package with zip, get-uninstall-package" {

        $package = "7zip"

        $a= install-package -name $package -verbose -ProviderName $ChocolateyGet  -force
        $a.Name -contains $package | Should Be $true

        $a=get-package $package -provider $ChocolateyGet -verbose | uninstall-package -AdditionalArguments '-y --remove-dependencies' -Verbose
        $a.Name -contains $package | Should Be $true
    }        
 }
