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

	$chocoParams = @{
		SourceName = $Name
		SourceLocation = $Location
	}

	if ($script:NativeAPI) {
		Invoke-ChocoAPI -SourceAdd @chocoParams
	} else {
		Add-ChocoSource @chocoParams
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
