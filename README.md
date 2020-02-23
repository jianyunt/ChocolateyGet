[![Build status](https://ci.appveyor.com/api/projects/status/vxbk2jqy0r6y7cem/branch/master?svg=true)](https://ci.appveyor.com/project/jianyunt/chocolateyget/branch/master)

# ChocolateyGet
ChocolateyGet provider allows to download Chocolatey packages from any NuGet repository via OneGet


## Get the ChocolateyGet installed
```PowerShell
Find-PackageProvider ChocolateyGet -verbose

Install-PackageProvider ChocolateyGet -verbose

Import-PackageProvider ChocolateyGet

# Run Get-Packageprovider to check if the ChocolateyGet provider is imported
Get-Packageprovider -verbose
```

## Sample usages
### find-packages
```PowerShell
find-package -ProviderName ChocolateyGet -name  nodejs

find-package -ProviderName ChocolateyGet -name firefox*
```

### install-packages
```PowerShell
find-package nodejs -verbose -provider ChocolateyGet -AdditionalArguments --exact | install-package

install-package -name 7zip -verbose -ProviderName ChocolateyGet
```
### get-packages
```PowerShell
get-package nodejs -verbose -provider ChocolateyGet
```
### uninstall-package
```PowerShell
get-package nodejs -provider ChocolateyGet -verbose | uninstall-package -AdditionalArguments '-y --remove-dependencies' -Verbose
```
### save-package

save-package is not supported for ChocolateyGet provider.
It is because ChocolateyGet is a wrapper of choco.exe which currently does not support down packages only.

### register-packagesource / unregister-packagesource
```PowerShell
register-packagesource privateRepo -provider ChocolateyGet -location 'https://somewhere/out/there/api/v2/'
find-package nodejs -verbose -provider ChocolateyGet -source privateRepo -AdditionalArguments --exact | install-package
unregister-packagesource privateRepo -provider ChocolateyGet
```

OneGet integrates with Chocolatey sources to manage source information

## Pass in choco arguments
If you need to pass in some of choco arguments to the Find, Install, Get and Uninstall-package cmdlets, you can use AdditionalArguments PowerShell property.

## DSC Compatibility
Fully compatible with the PackageManagement DSC resources
```PowerShell
Configuration ChocoNodeJS {
	PackageManagement ChocolateyGet {
		Name = 'chocolateyget'
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
In order to reconile the two, ChocolateyGet has a reserved keyword 'latest' that when passed as a Required Version can compare the version of what's currently installed against what's in the repository.
```PowerShell
PS C:\Users\ethan> Install-Package curl -RequiredVersion 7.60.0 -ProviderName ChocolateyGet -Force

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           v7.60.0          chocolatey


PS C:\Users\ethan> Get-Package curl -ProviderName ChocolateyGet

Name                           Version          Source                           ProviderName
----                           -------          ------                           ------------
curl                           7.60.0           Chocolatey                       ChocolateyGet


PS C:\Users\ethan> Get-Package curl -RequiredVersion latest -ProviderName ChocolateyGet
Get-Package : No package found for 'curl'.
At line:1 char:1
+ Get-Package curl -RequiredVersion latest -ProviderName ChocolateyGet
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (Microsoft.Power...lets.GetPackage:GetPackage) [Get-Package], Exception
    + FullyQualifiedErrorId : NoMatchFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackage

PS C:\Users\ethan> Find-Package curl -ProviderName ChocolateyGet

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           7.68.0           chocolatey


PS C:\Users\ethan> Find-Package curl -RequiredVersion latest -ProviderName ChocolateyGet

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           7.68.0           chocolatey


PS C:\Users\ethan> Find-Package curl -RequiredVersion latest -ProviderName ChocolateyGet | Install-Package -Force

Name                           Version          Source           Summary
----                           -------          ------           -------
curl                           v7.68.0          chocolatey


PS C:\Users\ethan> Get-Package curl -ProviderName ChocolateyGet

Name                           Version          Source                           ProviderName
----                           -------          ------                           ------------
curl                           7.68.0           Chocolatey                       ChocolateyGet


PS C:\Users\ethan> Get-Package curl -RequiredVersion latest -ProviderName ChocolateyGet

Name                           Version          Source                           ProviderName
----                           -------          ------                           ------------
curl                           7.68.0           Chocolatey                       ChocolateyGet

```

This feature can be combined with a PackageManagement-compatible configuration management system (ex: PowerShell DSC) to regularly keep certain packages up to date:
```PowerShell
	PackageManagement SysInternals {
		Name = 'sysinternals'
		RequiredVersion = 'latest'
		ProviderName = 'ChocolateyGet'
	}
```

## Known Issues
Currently ChocolateyGet works on Full CLR.
It is not supported on CoreClr.
This means ChocolateyGet provider is not supported on Nano server or Linux OSs.
The primarily reason is that the current version of choco.exe does not seem to support on CoreClr yet.

## Legal and Licensing

ChocolateyGet is licensed under the [MIT license](./LICENSE.txt).
