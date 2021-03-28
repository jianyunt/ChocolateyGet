$ChocolateyGet = 'ChocolateyGet'

Import-PackageProvider $ChocolateyGet -Force

if ($PSEdition -eq 'Desktop' -and -not $env:CHOCO_CLI) {
	$platform = 'API'
} else {
	$platform = 'CLI'
}

Describe "$platform basic package search operations" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'gets a list of latest installed packages' {
			Get-Package -Provider $ChocolateyGet | Where-Object {$_.Name -contains 'chocolatey'} | Should -Not -BeNullOrEmpty
		}
		It 'searches for the latest version of a package' {
			Find-Package -Provider $ChocolateyGet -Name $package | Where-Object {$_.Name -contains $package}  | Should -Not -BeNullOrEmpty
		}
		It 'searches for all versions of a package' {
			Find-Package -Provider $ChocolateyGet -Name $package -AllVersions | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'searches for the latest version of a package with a wildcard pattern' {
			Find-Package -Provider $ChocolateyGet -Name "$package*" | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
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
			Find-Package -Provider $ChocolateyGet -Name $package -AdditionalArguments $params | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "$platform DSC-compliant package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for the latest version of a package' {
			Find-Package -Provider $ChocolateyGet -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -Provider $ChocolateyGet -Name $package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -Provider $ChocolateyGet -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -Provider $ChocolateyGet -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
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
			Find-Package -Provider $ChocolateyGet -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -Force -Provider $ChocolateyGet -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed parameters to the package' {
			Get-ChildItem -Path $installDir -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -Provider $ChocolateyGet -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -Provider $ChocolateyGet -Name $package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "$platform pipline-based package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -Provider $ChocolateyGet -Name $package | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -Provider $ChocolateyGet -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
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
			Find-Package -Provider $ChocolateyGet -Name $package | Install-Package -Force -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed parameters to the package' {
			Get-ChildItem -Path $installDir -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -Provider $ChocolateyGet -Name $package | Uninstall-Package -AdditionalArguments $params | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "$platform multi-source support" {
	BeforeAll {
		$altSource = 'LocalChocoSource'
		$altLocation = $PSScriptRoot
		$package = 'cpu-z'

		Save-Package $package -Source 'http://chocolatey.org/api/v2' -Path $altLocation
		Unregister-PackageSource -Name $altSource -Provider $ChocolateyGet -ErrorAction SilentlyContinue
	}
	AfterAll {
		Remove-Item "$altLocation\*.nupkg" -Force -ErrorAction SilentlyContinue
		Unregister-PackageSource -Name $altSource -Provider $ChocolateyGet -ErrorAction SilentlyContinue
	}

	It 'refuses to register a source with no location' {
		Register-PackageSource -Name $altSource -Provider $ChocolateyGet -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $altSource} | Should -BeNullOrEmpty
	}
	It 'registers an alternative package source' {
		Register-PackageSource -Name $altSource -Provider $ChocolateyGet -Location $altLocation | Where-Object {$_.Name -eq $altSource} | Should -Not -BeNullOrEmpty
	}
	It 'searches for and installs the latest version of a package from an alternate source' {
		Find-Package -Provider $ChocolateyGet -Name $package -source $altSource | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
	}
	It 'finds and uninstalls a package installed from an alternate source' {
		Get-Package -Provider $ChocolateyGet -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
	}
	It 'unregisters an alternative package source' {
		Unregister-PackageSource -Name $altSource -Provider $ChocolateyGet
		Get-PackageSource -Provider $ChocolateyGet | Where-Object {$_.Name -eq $altSource} | Should -BeNullOrEmpty
	}
}

Describe "$platform version filters" {
	$package = 'ninja'
	# Keep at least one version back, to test the 'latest' feature
	$version = '1.10.1'

	AfterAll {
		Uninstall-Package -Name $package -Provider $ChocolateyGet -ErrorAction SilentlyContinue
	}

	Context 'required version' {
		It 'searches for and silently installs a specific package version' {
			Find-Package -Provider $ChocolateyGet -Name $package -RequiredVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -Provider $ChocolateyGet -Name $package -RequiredVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
	}

	Context 'minimum version' {
		It 'searches for and silently installs a minimum package version' {
			Find-Package -Provider $ChocolateyGet -Name $package -MinimumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -ge $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a minimum package version' {
			Get-Package -Provider $ChocolateyGet -Name $package -MinimumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -ge $version} | Should -Not -BeNullOrEmpty
		}
	}

	Context 'maximum version' {
		It 'searches for and silently installs a maximum package version' {
			Find-Package -Provider $ChocolateyGet -Name $package -MaximumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -le $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a maximum package version' {
			Get-Package -Provider $ChocolateyGet -Name $package -MaximumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -le $version} | Should -Not -BeNullOrEmpty
		}
	}

	Context '"latest" version' {
		It 'does not find the "latest" locally installed version if an outdated version is installed' {
			Install-Package -name $package -requiredVersion $version -Provider $ChocolateyGet -Force
			Get-Package -Provider $ChocolateyGet -Name $package -RequiredVersion 'latest' -ErrorAction SilentlyContinue | Where-Object {$_.Name -contains $package} | Should -BeNullOrEmpty
		}
		It 'searches for and silently installs the latest package version' {
			Find-Package -Provider $ChocolateyGet -Name $package -RequiredVersion 'latest' | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -gt $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -Provider $ChocolateyGet -Name $package -RequiredVersion 'latest' | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -gt $version} | Should -Not -BeNullOrEmpty
		}
	}
}
