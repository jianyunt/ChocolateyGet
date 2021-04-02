function Add-PackageSource {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Location,

		[bool]
		$Trusted
	)

	Write-Verbose "New package source: $Name, $Location"

	Register-ChocoSource -Name $Name -Location $Location

	# Add new package source
	$packageSource = @{
		Name = $Name
		Location = $Location.TrimEnd("\")
		Trusted=$Trusted
		Registered= $true
	}

	New-PackageSource @packageSource
}
