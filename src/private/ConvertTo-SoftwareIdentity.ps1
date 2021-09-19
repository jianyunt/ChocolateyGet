# Convert the objects returned from Foil into Software Identities (SWIDs).
# Chocolatey (and therefore Foil) doesn't return source information in its packge output, so we have to inject source information based on what the user requested.
# If a custom source isn't specified, default to using Chocolatey.org.
function ConvertTo-SoftwareIdentity {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		[object[]]
		$InputObject,

		[Parameter()]
		[string]
		$Source = $script:PackageSource
	)

	process {
		Write-Debug ($LocalizedData.ProviderDebugMessage -f ('ConvertTo-SoftwareIdentity'))
		foreach ($package in $InputObject) {
			# Return a new SWID based on the output from Foil
			Write-Debug "Package identified: $($package.Name), $($package.version)"
			$swid = @{
				FastPackageReference = $package.Name+"#"+ $package.version+"#"+$Source
				Name = $package.Name
				Version = $package.version
				versionScheme = "MultiPartNumeric"
				FromTrustedSource = $true
				Source = $Source
			}
			New-SoftwareIdentity @swid
		}
	}
}
