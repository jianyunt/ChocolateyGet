Get-ChildItem .\ -Recurse -Filter *.ps*1 | ForEach-Object {
    Describe "File $($_) should not produce any PSScriptAnalyzer warnings" {
        Invoke-ScriptAnalyzer -Path $_.FullName | ForEach-Object {
            It "should not fail rule $($_.RuleName) on line $($_.Line) with message '$($_.Message)'" {
                $false | Should -Be $true
            }
        }
    }
}