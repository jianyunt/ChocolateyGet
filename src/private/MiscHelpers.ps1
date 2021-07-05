# Get AdditionalArguments property from the input cmdline
function Get-AdditionalArguments {
	[CmdletBinding()]
	[OutputType([string])]
	param (
	)

	$additionalArgs = $null
	$options = $request.Options

	if($options.ContainsKey($script:additionalArguments)) {
		$additionalArgs = $options[$script:additionalArguments]
	}

	$additionalArgs
}

# Find whether a user specifies -force
function Get-ForceProperty {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
	)

	$force = $false
	$options = $request.Options

	if ($options.ContainsKey('Force')) {
		$force = (-not [System.String]::IsNullOrWhiteSpace($options['Force']))
	}

	$force
}

# Find whether a user specifies -AcceptLicense
function Get-AcceptLicenseProperty {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
	)

	$acceptLicense = $false
	$options = $request.Options

	if ($options.ContainsKey($script:AcceptLicense)) {
		$acceptLicense = (-not [System.String]::IsNullOrWhiteSpace($options[$script:AcceptLicense]))
	}

	$acceptLicense
}

# Utility to throw an errorrecord
function ThrowError {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification='ThrowError exists in neither 5.1 or 7+. PSSAs documentation is outdated.')]
	param (
		# We need to grab and use the 'parent' (parent = 1) scope to properly return output to the user
		[parameter()]
		[System.Management.Automation.PSCmdlet]
		$CallerPSCmdlet = ((Get-Variable -Scope 1 'PSCmdlet').Value),

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ExceptionName,

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ExceptionMessage,

		[System.Object]
		$ExceptionObject,

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ErrorId,

		[parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[System.Management.Automation.ErrorCategory]
		$ErrorCategory
	)

	$errorRecord = New-Object System.Management.Automation.ErrorRecord (New-Object $ExceptionName $ExceptionMessage), $ErrorId, $ErrorCategory, $ExceptionObject
	$CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}
