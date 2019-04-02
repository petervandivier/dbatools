
function Compare-ColumnSetPair {
    <#
    .SYNOPSIS
        Given a pair of input arrays, return to the caller a merged array with a confidence value that $source.node[N] corresponds to $target.node[M].

    .DESCRIPTION
        Internal function to determine INSERT->SELECT mappings.

        When performing a data load, it is necessary to specify FROM->TO mapping(s) for all COLUMN objects between two TABLES. Sometimes it's very straightforward as in...

            INSERT foo ( id, name )
            SELECT id, name
            FROM bar;

        ...other times, it is not. Consider...

            INSERT foo ( id, name )
            SELECT
                 row_number() over (order by SELECT NULL) AS row_num
                ,label
            FROM dbo.Products;

        ...this function attempts to standardize mapping protocol between arbitrary user-supplied arrays for the dbatools module.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$Source,
        [Parameter(Mandatory)]
        [object]$Target
    )

    <#function Assert-UniqueLabel {
        [CmdletBinding()]
        param (
            [array]$array
        )
        $array.Count -eq ($array | Select-Object -Unique).Count
    }#>

    # $Source, $Target | Add-Member -MemberType NoteProperty -Name "IsUniqueLabel" -Value (Assert-UniqueLabel $_.Name)

    $SourceSet = $Source | Select-Object ID, Name, Identity, Computed, DataType, @{n = "IsExactMatch"; e = { $false } }, @{n = "IsMapped"; e = { $false } }
    $TargetSet = $Target | Select-Object ID, Name, Identity, Computed, DataType, @{n = "IsExactMatch"; e = { $false } }, @{n = "IsMapped"; e = { $false } }

    $MatchSet = $SourceSet | ForEach-Object {
        $SourceID = $_.ID
        $SourceName = $_.Name

        $TargetMatch = $TargetSet | Where-Object Name -EQ $SourceName

        $IsExactMatch = $false
        $IsMapped = $false

        if ($TargetMatch) {
            $IsExactMatch = $true
            $IsMapped = $true

            $TargetID = $TargetMatch.ID
            $TargetName = $TargetMatch.Name
        } else {

        }

        $_.IsExactMatch = $IsExactMatch
        $_.IsMapped = $IsMapped
        ($TargetSet | Where-Object Name -EQ $SourceName).IsExactMatch = $IsExactMatch

        [PSCustomObject]@{
            SourceID     = $SourceID
            SourceName   = $SourceName
            IsExactMatch = $IsExactMatch
            TargetID     = $TargetID
            TargetName   = $TargetName
        }
    }

    <#$TargetSet | Where-Object IsMapped -ne $true | ForEach-Object {
        $_.IsMapped = $false

        $MatchSet += [PSCustomObject]@{
            TargetID   = $_.ID
            TargetName = $_.Name
        }
    }#>

    return $MatchSet
}
