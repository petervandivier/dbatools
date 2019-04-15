# how to test internal function?!?
$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Foo the bar" {
        $tblColRaw = (Get-DbaDbTable -SqlInstance $script:instance1 -Database 'msdb' -Table "dbo.syssessions").Columns
        $tblColVector = ConvertTo-ColumnVector $tblColRaw

    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    Context "Bar the foo right the fook back" {
    }
}
