Get-ChildItem .\ -Recurse -File | ForEach-Object {
	Describe "file $($_) should not produce any PSScriptAnalyzer warnings" {
		Invoke-ScriptAnalyzer -Path $_.FullName | ForEach-Object {
			It "should not fail rule $($_.RuleName) on line $($_.Line) with message ""$($_.Message)""" {
				$false | Should -Be $true
			}
		}
	}
}
