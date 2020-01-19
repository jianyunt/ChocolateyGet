# Utility function - Read the registered package sources from its configuration file
function Get-PackageSources {
	$ChocoSourcePropertyNames = @(
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

	Invoke-Choco -SourceList | ConvertFrom-String -Delimiter "\|" -PropertyNames $ChocoSourcePropertyNames
}
