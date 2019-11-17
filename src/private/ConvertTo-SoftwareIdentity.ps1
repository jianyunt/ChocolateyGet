function ConvertTo-SoftwareIdentity {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		[string[]]
		$Packages,

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
		foreach ($package in $Packages) {
			if (($package -Match $packageRegex) -and ($package -notmatch $packageReportRegex) -and $Matches.name -and $Matches.version) {
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