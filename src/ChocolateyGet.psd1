@{
	RootModule = 'ChocolateyGet.psm1'
	ModuleVersion = '3.1.1'
	GUID = 'c1735ed7-8b2f-426a-8cbc-b7feb6b8288d'
	Author = 'Jianyun'
	Copyright = ''
	Description = 'Package Management (OneGet) provider that facilitates installing Chocolatey packages from any NuGet repository.'
	# Refuse to load in CoreCLR if PowerShell below 7.0.1 due to regressions with how 7.0 loads PackageManagement DLLs
	# https://github.com/PowerShell/PowerShell/pull/12203
	PowerShellVersion = if ($PSEdition -eq 'Core') {
		'7.0.1'
	} else {
		'5.1'
	}
	RequiredModules = @(
		@{
			ModuleName='PackageManagement'
			ModuleVersion='1.1.7.2'
		},
		@{
			ModuleName='Foil'
			ModuleVersion='0.0.3'
		}
	)
	PrivateData = @{
		PackageManagementProviders = 'ChocolateyGet.psm1'
		PSData = @{
			# Tags applied to this module to indicate this is a PackageManagement Provider.
			Tags = @('PackageManagement','Provider','Chocolatey','PSEdition_Desktop','PSEdition_Core','Windows')

			# A URL to the license for this module.
			LicenseUri = 'https://github.com/PowerShell/PowerShell/blob/master/LICENSE.txt'

			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/Jianyunt/ChocolateyGet'

			# ReleaseNotes of this module
			ReleaseNotes = 'This is a PowerShell OneGet provider. It is a wrapper on top of Choco.
			It discovers Chocolatey packages from https://www.chocolatey.org and other NuGet repos.'
		}
	}
}
