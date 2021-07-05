$scriptAnalyzerRules = Get-ScriptAnalyzerRule

Get-ChildItem .\ -Recurse -Filter *.ps*1 | ForEach-Object {
    Describe "File $($_) should not produce any PSScriptAnalyzer warnings" {
        $analysis = Invoke-ScriptAnalyzer -Path $_.FullName
        foreach ($rule in $scriptAnalyzerRules) {
            It "Should pass $rule" {
                $analysis | Where-Object RuleName -EQ $rule | Should -BeNullOrEmpty
            }
        }
    }
}