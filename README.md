[![Build status](https://ci.appveyor.com/api/projects/status/vxbk2jqy0r6y7cem/branch/master?svg=true)](https://ci.appveyor.com/project/jianyunt/chocolateyget/branch/master)

# ChocolateyGet
ChocolateyGet is Package Management (OneGet) provider that facilitates installing Chocolatey packages from any NuGet repository.

## Install ChocolateyGet
```PowerShell
Find-PackageProvider ChocolateyGet -verbose

Install-PackageProvider ChocolateyGet -verbose

Import-PackageProvider ChocolateyGet

# Run Get-PackageProvider to check if the ChocolateyGet provider is imported
Get-PackageProvider -verbose
```

## Sample usages
### Search for a package
```PowerShell
Find-Package -ProviderName ChocolateyGet -name  nodejs

Find-Package -ProviderName ChocolateyGet -name firefox*
```

### Install a package
```PowerShell
Find-Package nodejs -verbose -provider ChocolateyGet -AdditionalArguments --exact | Install-Package

Install-Package -name 7zip -verbose -ProviderName ChocolateyGet
```
### Get list of installed packages
```PowerShell
Get-Package nodejs -verbose -provider ChocolateyGet
```
### Uninstall a package
```PowerShell
Get-Package nodejs -provider ChocolateyGet -verbose | Uninstall-Package -AdditionalArguments '-y --remove-dependencies' -Verbose
```

### Manage package sources
```PowerShell
Register-PackageSource privateRepo -provider ChocolateyGet -location 'https://somewhere/out/there/api/v2/'
Find-Package nodejs -verbose -provider ChocolateyGet -source privateRepo -AdditionalArguments --exact | Install-Package
Unregister-PackageSource privateRepo -provider ChocolateyGet
```

ChocolateyGet integrates with Choco.exe to manage and store source information

## Pass in choco arguments
If you need to pass in some of choco arguments to the Find, Install, Get and UnInstall-Package cmdlets, you can use AdditionalArguments PowerShell property.

## DSC Compatibility
Fully compatible with the PackageManagement DSC resources
```PowerShell
Configuration MyNode {
	Import-DscResource -Name PackageManagement,PackageManagementSource
	PackageManagement ChocolateyGet {
		Name = 'ChocolateyGet'
		Source = 'PSGallery'
	}
	PackageManagementSource ChocoPrivateRepo {
		Name = 'privateRepo'
		ProviderName = 'ChocolateyGet'
		SourceLocation = 'https://somewhere/out/there/api/v2/'
		InstallationPolicy = 'Trusted'
		DependsOn = '[PackageManagement]ChocolateyGet'
	}
	PackageManagement NodeJS {
		Name = 'nodejs'
		Source = 'privateRepo'
		DependsOn = '[PackageManagementSource]ChocoPrivateRepo'
	}
}
```

## Keep packages up to date
A common complaint of PackageManagement/OneGet is it doesn't allow for updating installed packages, while Chocolatey does.
In order to reconcile the two, ChocolateyGet has a reserved keyword 'latest' that when passed as a Required Version can compare the version of what's currently installed against what's in the repository.
```PowerShell

PS C:\Users\ethan> Find-Package curl -RequiredVersion latest -ProviderName ChocolateyGet

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           7.68.0           chocolatey

PS C:\Users\ethan> Install-Package curl -RequiredVersion 7.60.0 -ProviderName ChocolateyGet -Force

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           v7.60.0          chocolatey

PS C:\Users\ethan> Get-Package curl -RequiredVersion latest -ProviderName ChocolateyGet
Get-Package : No package found for 'curl'.
At line:1 char:1
+ Get-Package curl -RequiredVersion latest -ProviderName ChocolateyGet
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (Microsoft.Power...lets.GetPackage:GetPackage) [Get-Package], Exception
    + FullyQualifiedErrorId : NoMatchFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackage

PS C:\Users\ethan> Install-Package curl -RequiredVersion latest -ProviderName ChocolateyGet -Force

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           v7.68.0          chocolatey

PS C:\Users\ethan> Get-Package curl -RequiredVersion latest -ProviderName ChocolateyGet

Name                           Version          Source                           ProviderName
----                           -------          ------                           ------------
curl                           7.68.0           Chocolatey                       ChocolateyGet

```

This feature can be combined with a PackageManagement-compatible configuration management system (ex: [PowerShell DSC LCM in 'ApplyAndAutoCorrect' mode](https://docs.microsoft.com/en-us/powershell/scripting/dsc/managing-nodes/metaconfig)) to regularly keep certain packages up to date:
```PowerShell
Configuration MyNode {
	Import-DscResource -Name PackageManagement
	PackageManagement ChocolateyGet {
		Name = 'ChocolateyGet'
		Source = 'PSGallery'
	}
	PackageManagement SysInternals {
		Name = 'sysinternals'
		RequiredVersion = 'latest'
		ProviderName = 'ChocolateyGet'
		DependsOn = '[PackageManagement]ChocolateyGet'
	}
}
```

**Please note** - Since Chocolatey doesn't track source information of installed packages, and since PackageManagement doesn't support passing source information when invoking `Get-Package`, the 'latest' functionality **will not work** if Chocolatey.org is removed as a source **and** multiple custom sources are defined.

Furthermore, if both Chocolatey.org and a custom source are configured, the custom source **will be ignored** when the 'latest' required version is used with `Get-Package`.

Example PowerShell DSC configuration using the 'latest' required version with a custom source:

```PowerShell
Configuration MyNode {
	Import-DscResource -Name PackageManagement,PackageManagementSource
	PackageManagement ChocolateyGet {
		Name = 'ChocolateyGet'
		Source = 'PSGallery'
	}
	PackageManagementSource ChocoPrivateRepo {
		Name = 'privateRepo'
		ProviderName = 'ChocolateyGet'
		SourceLocation = 'https://somewhere/out/there/api/v2/'
		InstallationPolicy = 'Trusted'
		DependsOn = '[PackageManagement]ChocolateyGet'
	}
	PackageManagementSource ChocolateyRepo {
		Name = 'Chocolatey'
		ProviderName = 'ChocolateyGet'
		Ensure = 'Absent'
		DependsOn = '[PackageManagement]ChocolateyGet'
	}
	# The source information wont actually be used by the Get-Package step of the PackageManagement DSC resource check, but it helps make clear to the reader where the package should come from
	PackageManagement NodeJS {
		Name = 'nodejs'
		Source = 'privateRepo'
		RequiredVersion = 'latest'
		DependsOn = @('[PackageManagementSource]ChocoPrivateRepo', '[PackageManagementSource]ChocolateyRepo')
	}
}
```

If using the 'latest' functionality, best practice is to either:
* use the default Chocolatey.org source
* unregister the default Chocolatey.org source in favor of a **single** custom source

## Known Issues
Currently ChocolateyGet works on Full CLR.
It is not supported on CoreClr.
This means ChocolateyGet provider is not supported on Nano server or Linux OSs.
The primarily reason is that the current version of choco.exe does not seem to support on CoreClr yet.

### Save a package
Save-Package is not supported with the ChocolateyGet provider, due to Chocolatey not supporting package downloads without special licensing.

## Legal and Licensing
ChocolateyGet is licensed under the [MIT license](./LICENSE.txt).
