# This function gets called during find-package, install-package, get-packagesource etc.
# OneGet uses this method to identify which provider can handle the packages from a particular source location.
function Resolve-PackageSource {

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Resolve-PackageSource'))

	$Sources = $request.PackageSources

	# No source name pattern specified, so return everything
	if (-not $Sources) {
		$Sources = "*"
	}

	# Get sources from Chocolatey
	[array]$RegisteredPackageSources = Foil\Get-ChocoSource

	# Filter sources by whether they're disabled in Chocolatey
	$RegisteredPackageSources | Where-Object {$_.Disabled -eq 'False'} | Where-Object {
		$src = $_.Name
		Write-Debug "Source $src is registred"
		# Pass the source on only if it matches the provided name pattern
		$Sources | Where-Object { $src -like $_ }
	} | ForEach-Object {
		New-PackageSource -Name $_.Name -Location $_.Location -Trusted $true -Registered $true
	}
}
