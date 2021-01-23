[![Build status](https://ci.appveyor.com/api/projects/status/vxbk2jqy0r6y7cem/branch/master?svg=true)](https://ci.appveyor.com/project/jianyunt/chocolateyget/branch/master)

# ChocolateyGet
ChocolateyGet is Package Management (OneGet) provider that facilitates installing Chocolatey packages from any NuGet repository.

## Install ChocolateyGet
```PowerShell
Install-PackageProvider ChocolateyGet -Force
```

## Sample usages
### Search for a package
```PowerShell
Find-Package -Provider ChocolateyGet -Name nodejs

Find-Package -Provider ChocolateyGet -Name firefox*
```

### Install a package
```PowerShell
Find-Package nodejs -Verbose -Provider ChocolateyGet -AdditionalArguments --Exact | Install-Package

Install-Package -Name 7zip -Verbose -Provider ChocolateyGet
```
### Get list of installed packages
```PowerShell
Get-Package nodejs -Verbose -Provider ChocolateyGet
```
### Uninstall a package
```PowerShell
Get-Package nodejs -Provider ChocolateyGet -Verbose | Uninstall-Package -Verbose
```

### Manage package sources
```PowerShell
Register-PackageSource privateRepo -Provider ChocolateyGet -Location 'https://somewhere/out/there/api/v2/'
Find-Package nodejs -Verbose -Provider ChocolateyGet -Source privateRepo -AdditionalArguments --exact | Install-Package
Unregister-PackageSource privateRepo -Provider ChocolateyGet
```

ChocolateyGet integrates with Choco.exe to manage and store source information

## Pass in choco arguments
If you need to pass in some of choco arguments to the Find, Install, Get and Uninstall-Package cmdlets, you can use AdditionalArguments PowerShell property.

```powershell
Install-Package sysinternals -Provider ChocolateyGet -AcceptLicense -AdditionalArguments '--paramsglobal --params "/InstallDir=c:\windows\temp\sysinternals /QuickLaunchShortcut=false" -y --installargs MaintenanceService=false' -Verbose
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
		Source = 'privateRepo'
		RequiredVersion = 'latest'
		DependsOn = @('[PackageManagementSource]ChocoPrivateRepo', '[PackageManagementSource]ChocolateyRepo')
	}
}
```

If using the 'latest' functionality, best practice is to either:
* use the default Chocolatey.org source
* unregister the default Chocolatey.org source in favor of a **single** custom source

## API integration
Under PowerShell 5.1 and below ChocolateyGet invokes Chocolatey through it's native API by default rather than through interpreting CLI output. As a result, ChocolateyGet can operate without a local installation of Choco.exe.

The provider's standard battery of tests run about **36% faster** under the native API versus using the CLI interpreter, with operations that don't invoke a package (searching for packages, registering sources, etc.) running about **10x faster**.

By default, ChocolateyGet uses the API when invoked with PowerShell 5.1 and below, but can revert to using the CLI in the environment entries before the provider is first invoked:
```PowerShell
$env:CHOCO_CLI = $true
Find-Package -Provider ChocolateyGet -Name nodejs
```

If Choco.exe is already installed, the Native API will detect the existing Chocolatey installation path and leverage it for maintaining local package and source metadata.

Invoking the provider with the Native API is the first use of Chocolatey on your system, the provider will instruct the Native API to align where it extracts its files with the standard used by Choco.exe (%ProgramData%/Chocolatey) to avoid diverging locations of package and source metadata.

## Known Issues
### Compatibility
ChocolateyGet works with PowerShell for both FullCLR/'Desktop' (ex 5.1) and CoreCLR (ex: 7.0.1), though Chocolatey itself still requires FullCLR.

When used with CoreCLR, PowerShell 7.0.1 is a minimum requirement due to [a compatibility issue in PowerShell 7.0](https://github.com/PowerShell/PowerShell/pull/12203).

### Save a package
Save-Package is not supported with the ChocolateyGet provider, due to Chocolatey not supporting package downloads without special licensing.

### CLI Package search with MaximumVersion / AllVersions return unexpected results
Due to [a bug with Chocolatey](https://github.com/chocolatey/choco/issues/1843) versions 0.10.14 through 0.10.15, ChocolateyGet is unable to search packages by package range via command line as of version 2.1.0.

Until [Chocolatey 0.10.16 is released](https://github.com/chocolatey/choco/milestone/43), the following workarounds are available:
- Specify `RequiredVersion` if possible
  ```PowerShell
  Install-Package ninja -RequiredVersion 1.9.0 -Provider ChocolateyGet
  ```
- Downgrade Chocolatey to 0.10.13 until 0.10.16 is released (ChocolateyGet installs 0.10.13 by default)
  ```PowerShell
  Install-Package chocolatey -RequiredVersion 0.10.13 -Provider ChocolateyGet -Force
  Install-Package ninja -MaximumVersion 1.9.0 -Provider ChocolateyGet
  ```
- If you **must** use Chocolatey 0.10.14 or 0.10.15 for some reason, include the environment variable CHOCO_NONEXACT_SEARCH
  ```PowerShell
  $env:CHOCO_NONEXACT_SEARCH = $true
  Install-Package ninja -MaximumVersion 1.9.0 -Provider ChocolateyGet
  ```
  - Please note - this will revert the default search behavior change requested in [Issue #20](https://github.com/jianyunt/ChocolateyGet/issues/20)
- Use ChocolateyGet via PowerShell v5 or below in Native API mode, which uses Chocolatey version 0.10.13


## Legal and Licensing
ChocolateyGet is licensed under the [MIT license](./LICENSE.txt).
