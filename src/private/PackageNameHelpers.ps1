# Test if the $Name contains any wildcard characters
function Test-WildcardPattern {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		$Name
	)

	[System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)
}

function Test-PackageName {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory=$true)]
		[string]
		$Name,

		[Parameter(Mandatory=$true)]
		[string]
		$RequestedName
	)

	$nameRegex='^.*'+($RequestedName.TrimStart('*')).TrimEnd('.')+'.*$'

	# Return true if the package name returned from choco matched what we were expecting
	($Name -match $nameRegex) -and (
		($RequestedName -eq $Name) -or (Test-WildcardPattern -name $RequestedName)
	)
}
