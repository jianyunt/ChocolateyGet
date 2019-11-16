# This function gets called during find-package, install-package, get-packagesource etc.
# OneGet uses this method to identify which provider can handle the packages from a particular source location.
function Resolve-PackageSource {

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Resolve-PackageSource'))

	$SourceNames = $request.PackageSources

	if (-not $SourceNames) {
		$SourceNames = "*"
	}
	
	# get Sources from the registered config file
	[array]$RegisteredPackageSources = Get-PackageSources

	$RegisteredPackageSources | Where-Object {$_.Disabled -eq 'False'} | Where-Object {
		$src = $_.Name
		Write-Debug "Source $src is registred"
		$SourceNames | Where-Object { $src -like $_ }
	} | ForEach-Object { 
		New-PackageSource -Name $_.Name -Location $_.Location -Trusted $true -Registered $true 
	}
}
