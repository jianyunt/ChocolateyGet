# Convert the output from choco.exe into Software Identities (SWIDs).
# We do this by pattern matching the output for anything that looks like it contains the package we were looking for, and a version.
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
		$RequestedName,

		[Parameter()]
		[string]
		$Source = $script:PackageSourceName
	)

	process {
		# Each line we get from choco.exe isnt necessarily a package, but it could be
		foreach ($packageCandidate in $ChocoOutput) {
			# If a particular package name wasnt queried for by the user, return everything that choco does
			if (-not ($RequestedName) -or (Test-PackageName -RequestedName $RequestedName -PackageName $packageCandidate.name)) {
				# Return a new SWID based on the output from choco
				Write-Debug "Package identified: $($packageCandidate.name), $($packageCandidate.version)"
				$swid = @{
					FastPackageReference = $packageCandidate.name+"#"+ $packageCandidate.version.TrimStart('v')+"#"+$Source
					Name = $packageCandidate.name
					Version = $packageCandidate.version.TrimStart('v')
					versionScheme = "MultiPartNumeric"
					FromTrustedSource = $true
					Source = $Source
				}
				New-SoftwareIdentity @swid
			}
		}
	}
}
