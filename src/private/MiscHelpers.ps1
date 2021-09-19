function Get-PromptBypass {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
	)

	# Skip any user prompts if either the Force or AcceptLicense options passed in the cmdlet invocation
	$request.Options.ContainsKey($script:Force) -Or $request.Options.ContainsKey($script:AcceptLicense)
}

# Utility to throw an errorrecord
function ThrowError {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification='ThrowError exists in neither 5.1 or 7+. PSSAs documentation is outdated.')]
	param (
		# We need to grab and use the 'parent' (parent = 1) scope to properly return output to the user
		[Parameter()]
		[System.Management.Automation.PSCmdlet]
		$CallerPSCmdlet = ((Get-Variable -Scope 1 'PSCmdlet').Value),

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ExceptionName,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ExceptionMessage,

		[System.Object]
		$ExceptionObject,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ErrorId,

		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[System.Management.Automation.ErrorCategory]
		$ErrorCategory
	)

	$errorRecord = New-Object System.Management.Automation.ErrorRecord (New-Object $ExceptionName $ExceptionMessage), $ErrorId, $ErrorCategory, $ExceptionObject
	$CallerPSCmdlet.ThrowTerminatingError($errorRecord)
}
