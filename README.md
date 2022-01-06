[![Build status](https://ci.appveyor.com/api/projects/status/vxbk2jqy0r6y7cem/branch/master?svg=true)](https://ci.appveyor.com/project/jianyunt/chocolateyget/branch/master)

# ChocolateyGet
ChocolateyGet is a Package Management (OneGet) provider that facilitates installing Chocolatey packages from any NuGet repository.

## Install ChocolateyGet

```PowerShell
Install-PackageProvider ChocolateyGet -Force
```
Note: Please do **not** use `Import-Module` with Package Management providers, as they are not meant to be imported in that manner. Either use `Import-PackageProvider` or specify the provider name with the `-Provider` argument to the PackageManagement cmdlets, such as in the examples below:

## Sample usages

Note: When ran for the **first time**, any of the subsequent commands will install Chocolatey if not already present in your system. Run them in an **elevated shell**, otherwise the installation will fail.

### Search for a package

```PowerShell
Find-Package -Provider ChocolateyGet -Name nodejs

Find-Package -Provider ChocolateyGet -Name firefox*
```

### Install a package
```PowerShell
Find-Package nodejs -Verbose -Provider ChocolateyGet | Install-Package

Install-Package -Name 7zip -Verbose -Provider ChocolateyGet
```
### Get list of installed packages
```PowerShell
Get-Package nodejs -Verbose -Provider ChocolateyGet
```
### Uninstall a package
```PowerShell
Get-Package keepass-plugin-winhello -Provider ChocolateyGet -Verbose | Uninstall-Package -Verbose -RemoveDependencies
```

### Manage package sources
```PowerShell
Register-PackageSource privateRepo -Provider ChocolateyGet -Location 'https://somewhere/out/there/api/v2/'
Find-Package nodejs -Verbose -Provider ChocolateyGet -Source privateRepo | Install-Package
Unregister-PackageSource privateRepo -Provider ChocolateyGet
```

ChocolateyGet integrates with Choco.exe to manage and store source information

## Pass in choco arguments
If you need to pass in additional package installation options, you can use either the dedicated package parameter and argument properties or the combined AdditionalArguments property.

```powershell
Install-Package sysinternals -Provider ChocolateyGet -AcceptLicense -AdditionalArguments '--paramsglobal' -PackageParameters '/InstallDir:c:\windows\temp\sysinternals /QuickLaunchShortcut:false' -InstallArguments 'MaintenanceService=false' -Verbose
```

```powershell
Install-Package sysinternals -Provider ChocolateyGet -AcceptLicense -AdditionalArguments '--paramsglobal --params "/InstallDir:c:\windows\temp\sysinternals /QuickLaunchShortcut:false" -y --installargs MaintenanceService=false' -Verbose
```

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
		ProviderName = 'ChocolateyGet'
		Source = 'privateRepo'
		DependsOn = '[PackageManagementSource]ChocoPrivateRepo'
	}
}
```

## Keep packages up to date
A common complaint of PackageManagement/OneGet is it doesn't allow for updating installed packages, while Chocolatey does.
In order to reconcile the two, ChocolateyGet has a reserved keyword 'latest' that when passed as a Required Version can compare the version of what's currently installed against what's in the repository.
```PowerShell

PS C:\Users\ethan> Find-Package curl -RequiredVersion latest -Provider ChocolateyGet

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           7.68.0           chocolatey

PS C:\Users\ethan> Install-Package curl -RequiredVersion 7.60.0 -Provider ChocolateyGet -Force

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           v7.60.0          chocolatey

PS C:\Users\ethan> Get-Package curl -RequiredVersion latest -Provider ChocolateyGet
Get-Package : No package found for 'curl'.
At line:1 char:1
+ Get-Package curl -RequiredVersion latest -Provider ChocolateyGet
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (Microsoft.Power...lets.GetPackage:GetPackage) [Get-Package], Exception
    + FullyQualifiedErrorId : NoMatchFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackage

PS C:\Users\ethan> Install-Package curl -RequiredVersion latest -Provider ChocolateyGet -Force

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           v7.68.0          chocolatey

PS C:\Users\ethan> Get-Package curl -RequiredVersion latest -Provider ChocolateyGet

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
		ProviderName = 'ChocolateyGet'
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
### Compatibility
ChocolateyGet works with PowerShell for both FullCLR/'Desktop' (ex 5.1) and CoreCLR (ex: 7.0.1), though Chocolatey itself still requires FullCLR.

When used with CoreCLR, PowerShell 7.0.1 is a minimum requirement due to [a compatibility issue in PowerShell 7.0](https://github.com/PowerShell/PowerShell/pull/12203).

### Save a package
Save-Package is not supported with the ChocolateyGet provider, due to Chocolatey not supporting package downloads without special licensing.

### Package search with MaximumVersion / AllVersions return unexpected results
Due to [a bug with Chocolatey](https://github.com/chocolatey/choco/issues/1843) versions 0.10.14 through 0.10.15, ChocolateyGet is unable to search packages by package range via command line as of version 2.1.0.
Please upgrade Chocolatey to version 0.11.0 or higher to correct this issue.

## Legal and Licensing
ChocolateyGet is licensed under the [MIT license](./LICENSE.txt).
