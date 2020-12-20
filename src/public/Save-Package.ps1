# This function is called by OneGet while a user types Save-Package.
function Download-Package {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FastPackageReference,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Location
	)

	Write-Debug ($LocalizedData.ProviderDebugMessage -f ('Download-Package'))

	Write-Warning $LocalizedData.SavePackageNotSupported
}
