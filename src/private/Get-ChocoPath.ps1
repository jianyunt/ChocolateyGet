# Get the choco installed path
function Get-ChocoPath {
	[CmdletBinding()]
	[OutputType([string])]

	param (
	)

	# Using Get-Command cmdlet, get the location of Choco.exe if it is available under $env:PATH.
	Get-Command -Name $script:ChocoExeName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
		Where-Object {
			$_.Path -and
			((Split-Path -Path $_.Path -Leaf) -eq $script:ChocoExeName) -and
			(-not $_.Path.StartsWith($env:windir, [System.StringComparison]::OrdinalIgnoreCase))
		} | Select-Object -First 1
}
