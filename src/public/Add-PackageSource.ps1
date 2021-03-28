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

	if ($script:NativeAPI) {
		Invoke-ChocoAPI -SourceAdd -Source $Name -Location $Location
	} else {
		Register-ChocoSource -Name $Name -Location $Location
	}

	# Add new package source
	$packageSource = @{
		Name = $Name
		Location = $Location.TrimEnd("\")
		Trusted=$Trusted
		Registered= $true
	}

	New-PackageSource @packageSource
}
