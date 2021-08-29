# Convert the objects returned from Foil into Software Identities (SWIDs).
# Chocolatey doesn't return source information in its packge output, so we have to inject source information based on what the user requested.
# If a custom source isn't specified, default to using Chocolatey.org.
function ConvertTo-SoftwareIdentity {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		[object[]]
		$ChocoOutput,

		[Parameter()]
		[string]
		$Source = $script:PackageSource
	)

	process {
		# Each line we get from choco.exe isnt necessarily a package, but it could be
		foreach ($packageCandidate in $ChocoOutput) {
			# Return a new SWID based on the output from choco
			Write-Debug "Package identified: $($packageCandidate.Name), $($packageCandidate.version)"
			$swid = @{
				FastPackageReference = $packageCandidate.Name+"#"+ $packageCandidate.version.TrimStart('v')+"#"+$Source
				Name = $packageCandidate.Name
				Version = $packageCandidate.version.TrimStart('v')
				versionScheme = "MultiPartNumeric"
				FromTrustedSource = $true
				Source = $Source
			}
			New-SoftwareIdentity @swid
		}
	}
}
