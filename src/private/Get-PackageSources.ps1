# Utility function - Read the registered package sources from its configuration file
function Get-PackageSources {
	if ($script:NativeAPI) {
		Invoke-ChocoAPI -SourceList
	} else {
		Get-ChocoSource
	}
}
