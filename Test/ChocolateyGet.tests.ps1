
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
