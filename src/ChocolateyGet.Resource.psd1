ConvertFrom-StringData @'
###PSLOC
	ProviderDebugMessage='ChocolateyGet': '{0}'.
	FastPackageReference='ChocolateyGet': The FastPackageReference is '{0}'.

	SavePackageNotSupported='ChocolateyGet': Save-Package is not supported because Choco does not support downloading packages.

	InstallChocoExeShouldContinueQuery=ChocolateyGet is built on Choco.exe. Do you want ChocolateyGet to install Choco.exe from 'https://chocolatey.org/install.ps1' now?
	InstallChocoExeShouldContinueCaption=Choco.exe is required to continue
	UserDeclined=User declined to {0} Chocolatey.

	NotInstalled=Package '{0}' is not installed.
	FailToInstall=Failed to install the package because the package reference '{0}' is incorrect.
	FailToUninstall=Failed to uninstall the package because the package reference '{0}' is incorrect.
	FailToInstallChoco=choco installed failed. You may relaunch PowerShell as elevated mode and try again.
	UnexpectedChocoResponse=Output from choco.exe for package reference '{0}' did not match the exepected format. Please review Chocolatey logs for more information.

	InstallPackageQuery={0} package '{1}'. By {0} you accept licenses for the package(s). The package possibly needs to run 'chocolateyInstall.ps1'.
	InstallPackageCaption=Are you sure you want to perform this action?

	SpecifiedSource=Using the specified source names: '{0}'.
	PackageSourceNotFound=No package source with the name '{0}' was found.
	UnspecifiedSource=Multiple non-default sources are available, but the default source is not. A source name must be specified.
###PSLOC
'@
