# ChocolateyGet
ChocolateyGet provider allows to download packages from Chocolatey.org repository via OneGet.


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

find-package -ProviderName $ChocolateyGet -name firefox*
```

### install-packages
```PowerShell
find-package nodejs -verbose -provider ChocolateyGet -AdditionalArguments --exact | install-package

install-package -name 7zip -verbose -ProviderName ChocolateyGet
```
### get-packages
```PowerShell
get-package nodejs -verbose -provider $ChocolateyGet
```
### uninstall-package
```PowerShell
get-package nodejs -provider $ChocolateyGet -verbose | uninstall-package -AdditionalArguments '-y --remove-dependencies' -Verbose
```
### save-package

save-package is not supported for ChocolateyGet provider. It is because ChocolateyGet is a wrapper of choco.exe which currently does not support down packages only.

## Pass in choco arguments
If you need to pass in some of choco arguments to the Find, Install, Get and Uninstall-package cmdlets, you can use AdditionalArguments PowerShell property.

