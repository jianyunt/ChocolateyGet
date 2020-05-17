# Utility function - Read the registered package sources from its configuration file
function Get-PackageSources {
	Invoke-Choco -SourceList
}
