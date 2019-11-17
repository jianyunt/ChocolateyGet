# Convert the output from choco.exe into Software Identities (SWIDs).
# We do this by pattern matching the output for anything that looks like it contains the package we were looking for, and a version.
# Chocolatey doesn't return source information in its packge output, so we have to inject source information based on what the user requested.
# If a custom source isn't specified, default to using Chocolatey.org.
function ConvertTo-SoftwareIdentity {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		[string[]]
		$ChocoOutput,

		[Parameter()]
		[string]
		$RequestedName,

		[Parameter()]
		[string]
		$Source = $script:PackageSourceName
	)

	begin {
		$packageRegex = "^(?<name>[\S]+)[\|\s](?<version>[\S]+)"
		$packageReportRegex="^[0-9]*(\s*)(packages installed)"
	}

	process {
		# Each line we get from choco.exe isnt necessarily a package, but it could be
		foreach ($packageCandidate in $ChocoOutput) {
			if (($packageCandidate -Match $packageRegex) -and ($packageCandidate -notmatch $packageReportRegex) -and $Matches.name -and $Matches.version) {
				# If a particular package name wasnt queried for by the user, return everything that choco does
				if (-not ($RequestedName) -or (Test-PackageName -RequestedName $RequestedName -PackageName $Matches.name)) {
					# Return a new SWID based on the output from choco
					Write-Debug "Package identified: $($Matches.name), $($Matches.version)"
					$swid = @{
						FastPackageReference = $Matches.name+"#"+ $Matches.version.TrimStart('v')+"#"+$Source
						Name = $Matches.name
						Version = $Matches.version
						versionScheme = "MultiPartNumeric"
						FromTrustedSource = $true
						Source = $Source
					}
					New-SoftwareIdentity @swid
				}
			}
		}
	}
}
