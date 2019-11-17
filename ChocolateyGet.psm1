#region Private Variables
# Current script path
[string]$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Definition -Parent

# Define provider related variables
$script:ProviderName = "ChocolateyGet"
$script:PackageSourceName = "Chocolatey"
$script:additionalArguments = "AdditionalArguments"
$script:AllVersions = "AllVersions"

# Define choco related variables
$script:ChocoExeName = 'choco.exe'
$script:firstTime = $true

# Utility variables
$script:FastReferenceRegex = "(?<name>[^#]*)#(?<version>[^\s]*)#(?<source>[^#]*)"

Microsoft.PowerShell.Utility\Import-LocalizedData LocalizedData -filename 'ChocolateyGet.Resource.psd1'

#endregion Private Variables

#region Methods

# Dot sourcing private script files
Get-ChildItem $ScriptPath/src/private -Recurse -Filter "*.ps1" -File | ForEach-Object { 
	. $_.FullName
}

# Load and export methods

# Dot sourcing public function files
Get-ChildItem $ScriptPath/src/public -Recurse -Filter "*.ps1" -File | ForEach-Object { 
	. $_.FullName

	# Find all the functions defined no deeper than the first level deep and export it.
	# This looks ugly but allows us to not keep any uneeded variables from polluting the module.
	([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {
		Export-ModuleMember $_.Name
	}
}
#endregion Methods

#region Module Cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
	# cleanup when unloading module (if any)
}
#endregion Module Cleanup
