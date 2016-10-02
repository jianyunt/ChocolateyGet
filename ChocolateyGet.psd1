@{

RootModule = 'ChocolateyGet.psm1'
ModuleVersion = '1.0.0'
CompatiblePSEditions = @(Desktop)
GUID = 'c1735ed7-8b2f-426a-8cbc-b7feb6b8288d'
Author = 'Jianyun'
Copyright = ''
Description = 'An PowerShell OneGet provider that discovers packages from https://www.chocolatey.org.'
PowerShellVersion = '3.0'
FunctionsToExport = @('Compare-SemVer')
RequiredModules = @('PackageManagement')
PrivateData = @{"PackageManagementProviders" = 'ChocolateyGet.psm1'

    PSData = @{

        # Tags applied to this module to indicate this is a PackageManagement Provider.
        Tags = @("PackageManagement","Provider")

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/PowerShell/blob/master/LICENSE.txt'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Jianyunt/ChocolateyGet'

        # ReleaseNotes of this module
        ReleaseNotes = 'This is a PowerShell OneGet provider. It is a wrapper on top of Choco.     
        It discovers packages from https://www.chocolatey.org.
        '
        } # End of PSData
    }
}

