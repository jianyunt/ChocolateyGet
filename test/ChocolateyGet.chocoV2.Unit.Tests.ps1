[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='PSSA does not understand Pester scopes well')]
param()

BeforeAll {
	Import-PackageProvider 'ChocolateyGet' -Force
}

Describe 'Chocolatey V2 test validity' {
	BeforeAll {
		$package = 'chocolatey'
		$version = '2.0.0'
		# Upgrade to Chocolatey v2 to test the API changes
		choco upgrade $package --yes
	}
	It 'confirms version of Chocolatey is at least 2.0.0' {
		Get-Package -Provider 'ChocolateyGet' | Where-Object {$_.Name -eq $package -And $_.Version -ge $version} | Should -Not -BeNullOrEmpty
	}
}

Describe 'Chocolatey V2 basic package search operations' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'curl'
		}

		It 'searches for all versions of a package' {
			Find-Package -Provider 'ChocolateyGet' -Name $package -AllVersions | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'searches for the latest version of a package with a wildcard pattern' {
			Find-Package -Provider 'ChocolateyGet' -Name "$package*" | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with additional arguments' {
		BeforeAll {
			$package = 'sysinternals'
			$installDir = Join-Path -Path $env:ProgramFiles -ChildPath $package
			$params = "--paramsglobal --params ""/InstallDir:$installDir /QuickLaunchShortcut:false"""
			Remove-Item -Force -Recurse -Path $installDir -ErrorAction SilentlyContinue
		}

		It 'searches for the exact package name' {
			Find-Package -Provider 'ChocolateyGet' -Name $package -AdditionalArguments $params | Should -Not -BeNullOrEmpty
		}
	}
}

Describe 'Chocolatey V2 DSC-compliant package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'curl'
		}

		It 'searches for the latest version of a package' {
			Find-Package -Provider 'ChocolateyGet' -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -Provider 'ChocolateyGet' -Name $package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -Provider 'ChocolateyGet' -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -Provider 'ChocolateyGet' -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with additional parameters' {
		BeforeAll {
			$package = 'sysinternals'
			$installDir = Join-Path -Path $env:ProgramFiles -ChildPath $package
			$params = "--paramsglobal --params ""/InstallDir:$installDir /QuickLaunchShortcut:false"""
			Remove-Item -Force -Recurse -Path $installDir -ErrorAction SilentlyContinue
		}

		It 'searches for the latest version of a package' {
			Find-Package -Provider 'ChocolateyGet' -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -Force -Provider 'ChocolateyGet' -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed parameters to the package' {
			Get-ChildItem -Path $installDir -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -Provider 'ChocolateyGet' -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -Provider 'ChocolateyGet' -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with package parameters passed explicitly' {
		BeforeAll {
			$package = 'kitty'
			$installDir = Join-Path -Path $env:ChocolateyInstall -ChildPath (Join-Path -Path 'lib' -ChildPath $package)
			$kittyIniPath = Join-Path -Path $installDir -ChildPath (Join-Path -Path 'tools' -ChildPath 'kitty.ini')
			$packageParams = "/Portable"
			$wrappedParams = "--params ""/Dummy"""
			Remove-Item -Force -Recurse -Path $installDir -ErrorAction SilentlyContinue
		}
		It 'silently installs the latest version of a package with explicit parameters' {
			Install-Package -Force -Provider 'ChocolateyGet' -Name $package -PackageParameters $packageParams | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed explicit parameters to the package' {
			$kittyIniPath | Should -Exist
			$kittyIniPath | Should -FileContentMatch 'savemode=dir'
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -Provider 'ChocolateyGet' -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package with explicit and wrapped parameters' {
			Install-Package -Force -Provider 'ChocolateyGet' -Name $package -PackageParameters $packageParams -AdditionalArguments $wrappedParams | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed wrapped parameters to the package' {
			$kittyIniPath | Should -Not -Exist
		}
		It 'silently uninstalls the locally installed package just installed again' {
			Uninstall-Package -Provider 'ChocolateyGet' -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe 'Chocolatey V2 pipeline-based package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'curl'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -Provider 'ChocolateyGet' -Name $package | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -Provider 'ChocolateyGet' -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with dependencies' {
		BeforeAll {
			$package = 'cpu-z'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -Provider 'ChocolateyGet' -Name $package | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed, along with its dependencies' {
			Get-Package -Provider 'ChocolateyGet' -Name $package | Uninstall-Package -RemoveDependencies | Should -HaveCount 4
		}
	}
	Context 'with additional parameters' {
		BeforeAll {
			$package = 'sysinternals'
			$installDir = Join-Path -Path $env:ProgramFiles -ChildPath $package
			$params = "--paramsglobal --params ""/InstallDir:$installDir /QuickLaunchShortcut:false"""
			Remove-Item -Force -Recurse -Path $installDir -ErrorAction SilentlyContinue
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -Provider 'ChocolateyGet' -Name $package | Install-Package -Force -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed parameters to the package' {
			Get-ChildItem -Path $installDir -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -Provider 'ChocolateyGet' -Name $package | Uninstall-Package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe 'Chocolatey V2 multi-source support' {
	BeforeAll {
		$altSource = 'LocalChocoSource'
		$altLocation = $PSScriptRoot
		$package = 'curl'

		Save-Package $package -Source 'http://chocolatey.org/api/v2' -Path $altLocation
		Unregister-PackageSource -Name $altSource -Provider 'ChocolateyGet' -ErrorAction SilentlyContinue
	}
	AfterAll {
		Remove-Item "$altLocation\*.nupkg" -Force -ErrorAction SilentlyContinue
		Unregister-PackageSource -Name $altSource -Provider 'ChocolateyGet' -ErrorAction SilentlyContinue
	}

	It 'refuses to register a source with no location' {
		Register-PackageSource -Name $altSource -Provider 'ChocolateyGet' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $altSource} | Should -BeNullOrEmpty
	}
	It 'registers an alternative package source' {
		Register-PackageSource -Name $altSource -Provider 'ChocolateyGet' -Location $altLocation | Where-Object {$_.Name -eq $altSource} | Should -Not -BeNullOrEmpty
	}
	It 'searches for and installs the latest version of a package from an alternate source' {
		Find-Package -Provider 'ChocolateyGet' -Name $package -source $altSource | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
	}
	It 'finds and uninstalls a package installed from an alternate source' {
		Get-Package -Provider 'ChocolateyGet' -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
	}
	It 'unregisters an alternative package source' {
		Unregister-PackageSource -Name $altSource -Provider 'ChocolateyGet'
		Get-PackageSource -Provider 'ChocolateyGet' | Where-Object {$_.Name -eq $altSource} | Should -BeNullOrEmpty
	}
}

Describe 'Chocolatey V2 version filters' {
	BeforeAll {
		$package = 'ninja'
		# Keep at least one version back, to test the 'latest' feature
		$version = '1.10.1'
	}
	AfterAll {
		Uninstall-Package -Name $package -Provider 'ChocolateyGet' -ErrorAction SilentlyContinue
	}

	Context 'required version' {
		It 'searches for and silently installs a specific package version' {
			Find-Package -Provider 'ChocolateyGet' -Name $package -RequiredVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -Provider 'ChocolateyGet' -Name $package -RequiredVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
	}

	Context 'minimum version' {
		It 'searches for and silently installs a minimum package version' {
			Find-Package -Provider 'ChocolateyGet' -Name $package -MinimumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -ge $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a minimum package version' {
			Get-Package -Provider 'ChocolateyGet' -Name $package -MinimumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -ge $version} | Should -Not -BeNullOrEmpty
		}
	}

	Context 'maximum version' {
		It 'searches for and silently installs a maximum package version' {
			Find-Package -Provider 'ChocolateyGet' -Name $package -MaximumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -le $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a maximum package version' {
			Get-Package -Provider 'ChocolateyGet' -Name $package -MaximumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -le $version} | Should -Not -BeNullOrEmpty
		}
	}

	Context '"latest" version' {
		It 'does not find the "latest" locally installed version if an outdated version is installed' {
			Install-Package -Name $package -RequiredVersion $version -Provider 'ChocolateyGet' -Force
			Get-Package -Provider 'ChocolateyGet' -Name $package -RequiredVersion 'latest' -ErrorAction SilentlyContinue | Where-Object {$_.Name -contains $package} | Should -BeNullOrEmpty
		}
		It 'searches for and silently installs the latest package version' {
			Find-Package -Provider 'ChocolateyGet' -Name $package -RequiredVersion 'latest' | Install-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -gt $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -Provider 'ChocolateyGet' -Name $package -RequiredVersion 'latest' | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -And $_.Version -gt $version} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "error handling on Chocolatey failures" {
	Context 'package installation' {
		BeforeAll {
			$package = 'googlechrome'
			# This version is known to be broken, per https://github.com/chocolatey-community/chocolatey-coreteampackages/issues/1608
			$version = '87.0.4280.141'
		}
		AfterAll {
			Uninstall-Package -Name $package -Provider 'ChocolateyGet' -ErrorAction SilentlyContinue
		}

		It 'fails to silently install a package that cannot be installed' {
			{Install-Package -Provider 'ChocolateyGet' -Name $package -RequiredVersion $version -Force -ErrorAction Stop -WarningAction SilentlyContinue} | Should -Throw
		}
	}
	Context 'package uninstallation' {
		BeforeAll {
			$package = 'chromium'
			# This version is known to be broken, per https://github.com/chocolatey-community/chocolatey-coreteampackages/issues/341
			$version = '56.0.2897.0'
			Install-Package -Provider 'ChocolateyGet' -Name $package -RequiredVersion $version -Force
		}

		It 'fails to silently uninstall a package that cannot be uninstalled' {
			{Uninstall-Package -Provider 'ChocolateyGet' -Name $package -Force -ErrorAction Stop -WarningAction SilentlyContinue} | Should -Throw
		}
	}
}
