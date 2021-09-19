# This function gets called during Find-Package, Install-Package, Get-PackageSource etc.
# OneGet uses this method to identify which provider can handle the packages from a particular source location.
function Resolve-PackageSource {

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Resolve-PackageSource'))

	# Get sources from Chocolatey
	Foil\Get-ChocoSource | Where-Object {$_.Disabled -eq 'False'} | ForEach-Object {
		New-PackageSource -Name $_.Name -Location $_.Location -Trusted $true -Registered $true
	}
}
