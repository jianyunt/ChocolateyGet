# Current script path
[string]$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Definition -Parent

# Define provider related variables
$script:AcceptLicense = "AcceptLicense"
$script:AdditionalArguments = "AdditionalArguments"
$script:AllVersions = "AllVersions"
$script:Force = "Force"
$script:PackageSource = "Chocolatey"

# Utility variables
$script:FastReferenceRegex = "(?<name>[^#]*)#(?<version>[^\s]*)#(?<source>[^#]*)"
$script:ChocoSourcePropertyNames = @(
	'Name',
	'Location',
	'Disabled',
	'UserName',
	'Certificate',
	'Priority',
	'Bypass Proxy',
	'Allow Self Service',
	'Visibile to Admins Only'
)

Import-LocalizedData LocalizedData -filename "ChocolateyGet.Resource.psd1"

# Dot sourcing private script files
Get-ChildItem $ScriptPath/private -Recurse -Filter '*.ps1' -File | ForEach-Object {
	. $_.FullName
}
# Dot sourcing public function files
Get-ChildItem $ScriptPath/public -Recurse -Filter '*.ps1' -File | ForEach-Object {
	. $_.FullName

	# Find all the functions defined no deeper than the first level deep and export it.
	# This looks ugly but allows us to not keep any uneeded variables from polluting the module.
	([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {
		Export-ModuleMember $_.Name
	}
}

# Install Chocolatey if not already present
if (-not (Get-ChocoPath)) {
	Write-Debug ("Choco not already installed")
	Install-Chocolatey
}
