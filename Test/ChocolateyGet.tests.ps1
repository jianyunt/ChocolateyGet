﻿
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

	It "get-package" {
		$a=get-package -ProviderName $ChocolateyGet -verbose
		$a | should not BeNullOrEmpty
		
		$b=get-package -ProviderName $ChocolateyGet -name chocolatey -allversions -verbose
		$b | ?{ $_.name -eq "chocolatey" } | should not BeNullOrEmpty
	}

		It "find-package" {

		$a=find-package -ProviderName $ChocolateyGet -name  nodejs -ForceBootstrap -force
		$a | ?{ $_.name -eq "nodejs" } | should not BeNullOrEmpty
		
		$b=find-package -ProviderName $ChocolateyGet -name  nodejs -allversions -verbose
		$b | ?{ $_.name -eq "nodejs" } | should not BeNullOrEmpty

		$c=find-package -ProviderName $ChocolateyGet -name nodejs -AdditionalArguments --exact -verbose
		$c | ?{ $_.name -eq "nodejs" } | should not BeNullOrEmpty
	}

	It "find-package with wildcard search" {

		$d=find-package -ProviderName $ChocolateyGet -name *firefox* -Verbose
		$d | ?{ $_.name -eq "firefox" } | should not BeNullOrEmpty
		
	}

	It "find-install-package nodejs" {

		$package = "nodejs"
		$a=find-package $package -verbose -provider $ChocolateyGet -AdditionalArguments --exact | install-package -force -verbose
		$a.Name -contains $package | Should Be $true

		$b = get-package $package -verbose -provider $ChocolateyGet
		$b.Name -contains $package | Should Be $true

		$c= Uninstall-package $package -verbose -ProviderName $ChocolateyGet -AdditionalArguments '-y --remove-dependencies'
		$c.Name -contains $package | Should Be $true
	}

	It "install-package with zip, get-uninstall-package" {

		$package = "7zip"

		$a= install-package -name $package -verbose -ProviderName $ChocolateyGet -force
		$a.Name -contains $package | Should Be $true

		$a=get-package $package -provider $ChocolateyGet -verbose | uninstall-package -AdditionalArguments '-y --remove-dependencies' -Verbose
		$a.Name -contains $package | Should Be $true
	}
}

Describe "ChocolateyGet multi-source testing" -Tags @('BVT', 'DRT') {
	BeforeAll {
		$altSourceName = "LocalChocoSource"
		$altSourceLocation = $PSScriptRoot
		$package = "nodejs"

		Save-Package $package -Source 'http://chocolatey.org/api/v2' -Path $altSourceLocation
		Unregister-PackageSource -Name $altSourceName -ProviderName $ChocolateyGet -ErrorAction SilentlyContinue
	}
	AfterAll {
		Remove-item $altSourceLocation\$package* -Force -ErrorAction SilentlyContinue
		Unregister-PackageSource -Name $altSourceName -ProviderName $ChocolateyGet -ErrorAction SilentlyContinue
	}

	It "refuses to register a source with no location" {
		$a = Register-PackageSource -Name $altSourceName -ProviderName $ChocolateyGet -Verbose -ErrorAction SilentlyContinue
		$a.Name -eq $altSourceName | Should Be $false
	}

	It "installs and uninstalls from an alternative package source" {
		
		$a = Register-PackageSource -Name $altSourceName -ProviderName $ChocolateyGet -Location $altSourceLocation -Verbose
		$a.Name -eq $altSourceName | Should Be $true

		$b=find-package $package -verbose -provider $ChocolateyGet -source $altSourceName -AdditionalArguments --exact | install-package -force
		$b.Name -contains $package | Should Be $true

		$c = get-package $package -verbose -provider $ChocolateyGet
		$c.Name -contains $package | Should Be $true

		$d= Uninstall-package $package -verbose -ProviderName $ChocolateyGet -AdditionalArguments '-y --remove-dependencies'
		$d.Name -contains $package | Should Be $true

		Unregister-PackageSource -Name $altSourceName -ProviderName $ChocolateyGet
		$e = Get-PackageSource -ProviderName $ChocolateyGet
		$e.Name -eq $altSourceName | Should Be $false
	}
}

Describe "ChocolateyGet DSC integration with args/params support" -Tags @('BVT', 'DRT') {
	$package = "sysinternals"
	
	$argsAndParams = "--paramsglobal --params ""/InstallDir=c:\windows\temp\sysinternals /QuickLaunchShortcut=false"" -y --installargs MaintenanceService=false"
	
	It "finds, installs and uninstalls packages when given installation arguments parameters that would otherwise cause search to fail" {

		$a = find-package $package -verbose -provider $ChocolateyGet -AdditionalArguments $argsAndParams
		$a = install-package $a -force -AdditionalArguments $argsAndParams -Verbose
		$a.Name -contains $package | Should Be $true

		$b = get-package $package -verbose -provider $ChocolateyGet -AdditionalArguments $argsAndParams
		$b.Name -contains $package | Should Be $true

		$c = Uninstall-package $package -verbose -ProviderName $ChocolateyGet -AdditionalArguments $argsAndParams
		$c.Name -contains $package | Should Be $true

	}        
}
Describe "ChocolateyGet support for 'latest' RequiredVersion value with DSC support" -Tags @('BVT', 'DRT') {
	
	$package = "curl"
	$version = "7.60.0"

	AfterEach {
		Uninstall-Package -Name $package -Verbose -ProviderName $ChocolateyGet -Force -ErrorAction SilentlyContinue
	}
	
	It "does not find the 'latest' locally installed version if an outdated version is installed" {
		$a = install-package -name $package -requiredVersion $version -verbose -ProviderName $ChocolateyGet -Force
		$a.Name -contains $package | Should Be $true

		$b = get-package $package -requiredVersion 'latest' -verbose -provider $ChocolateyGet -ErrorAction SilentlyContinue
		$b.Name -contains $package | Should Be $false
	}

	It "finds, installs, and uninstalls the latest version when the 'latest' RequiredVersion value is set" {
		$a = find-package $package -requiredversion 'latest' -verbose -provider $ChocolateyGet
		$a = install-package $a -force -Verbose
		$a.Name -contains $package | Should Be $true

		$b = get-package $package -requiredversion 'latest' -verbose -provider $ChocolateyGet
		$b = Uninstall-package $b -verbose
		$b.Name -contains $package | Should Be $true
	}
}
