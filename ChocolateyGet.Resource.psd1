ConvertFrom-StringData @'
###PSLOC
	ProviderDebugMessage='ChocolateyGet': '{0}'.
	FastPackageReference='ChocolateyGet': The FastPackageReference is '{0}'.

	SearchingForPackage=Searching for package
	InstallingPackage=Installing package
	FindingLocalPackage=Finding local packages
	UnInstallingPackage=UnInstalling package
	ProcessingPackage=Processing package
	CheckingChoco=Checking if a newer version of Chocolatey available
	UpgradingChoco=Upgrading Chocolatey
	Complete=Complete

	SearchingEntireRepo=Searching the entire repo is not supported. Please specify package name.
	ChocoUnSupportedOnCoreCLR='{0}': Choco is not supported on CoreCLR (Nano Server or *nix).

	SearchVersionNotSupported='ChocolateyGet': Choco does not support seaching for a specific version. Returning all versions instead.
	SavePackageNotSupported='ChocolateyGet': Save-Package is not supported because Choco does not support downloading packages.

	InstallChocoExeShouldContinueQuery=ChocolateyGet is built on Choco.exe. Do you want ChocolateyGet to install Choco.exe from 'https://chocolatey.org/install.ps1' now?
	InstallChocoExeShouldContinueCaption=Choco.exe is required to continue
	UserDeclined=User declined to {0} Chocolatey.

	NotInstalled=Package '{0}' is not installed.
	FailToInstall=Failed to install the package because the fast reference '{0}' is incorrect.
	FailToUninstall=Failed to uninstall the package because the fast reference '{0}' is incorrect.
	FailToInstallChoco=choco installed failed. You may relaunch PowerShell as elevated mode and try again.
	OperationFailed='{0}' '{1}' Failed. You may relaunch PowerShell as elevated mode or try again with -Verbose -Debug to get more information.
	FoundNewerChocolatey=Found Chocolatey version '{0}' is greater than the installed one '{1}'
	InvalidVersionFormat=Version '{0}' does not match the regex '{1}'
	UnexpectedChocoResponse=Successful output from choco.exe for fast reference '{0}' did not match the exepected format. Please review Chocolatey logs for more information.

	OperationSucceed='{0}' '{1}' Successfully.
	ChocoFound=Found choco.exe in '{0}'.
	ChocoNotFound=Unable to find choco.exe under $PATH.
	InstallPackageQuery={0} package '{1}'. By {0} you accept licenses for the package(s). The package possibly needs to run 'chocolateyInstall.ps1'.
	InstallPackageCaption=Are you sure you want to perform this action?
	UpgradePackageQuery=There is a newer version '{0}' of Chocolatey available. Do you want to upgrade?

	NameShouldNotContainWildcardCharacters=The specified name '{0}' should not contain any wildcard characters, please correct it and try again.
	AllVersionsCannotBeUsedWithOtherVersionParameters=You cannot use the parameter AllVersions with RequiredVersion, MinimumVersion or MaximumVersion in the same command.
	VersionRangeAndRequiredVersionCannotBeSpecifiedTogether=You cannot use the parameters RequiredVersion and either MinimumVersion or MaximumVersion in the same command. Specify only one of these parameters in your command.
	RequiredVersionAllowedOnlyWithSingleModuleName=The RequiredVersion parameter is allowed only when a single module name is specified as the value of the Name parameter, without any wildcard characters.
	MinimumVersionIsGreaterThanMaximumVersion=The specified MinimumVersion '{0}' is greater than the specified MaximumVersion '{1}'.
	VersionParametersAreAllowedOnlyWithSingleName=The RequiredVersion, MinimumVersion, MaximumVersion or AllVersions parameters are allowed only when you specify a single name as the value of the Name parameter, without any wildcard characters.

	PackageSourceNameContainsWildCards=The package source name '{0}' should not have wildcards, correct it and try again.
	SourceRegistered=Successfully registered the package source '{0}' with location '{1}'.
	PackageSourceDetails=Package source details, Name = '{0}', Location = '{1}'; IsTrusted = '{2}'; IsRegistered = '{3}'.
	PackageSourceNotFound=No package source with the name '{0}' was found.
	PackageSourceUnregistered=Successfully unregistered the Package source '{0}'.
	SpecifiedSourceName=Using the specified source names: '{0}'.
	NoSourceNameIsSpecified=The Source parameter was not specified. We will use all of the registered package sources.
	UnspecifiedSource=Multiple non-default sources are available, but the default source is not. A source name must be specified.

###PSLOC
'@
