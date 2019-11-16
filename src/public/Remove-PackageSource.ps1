function Remove-PackageSource {
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name
	)

	Write-Debug ('Remove-PackageSource')

	[array]$RegisteredPackageSources = Get-PackageSources

	if (-not ($RegisteredPackageSources.Name -eq $Name)) {
		Write-Error -Message "Package source $Name not found" -ErrorId "PackageSourceNotFound" -Category InvalidOperation -TargetObject $Name
		return
	}

	Invoke-Choco -SourceRemove -SourceName $Name
}

