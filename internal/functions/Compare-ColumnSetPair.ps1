
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

    $TargetSet | Where-Object { $_.IsMapped -eq $false } | ForEach-Object {
        $MatchSet += [PSCustomObject]@{
            IsExactMatch = $false
            TargetID     = $_.ID
            TargetName   = $_.Name
        }
    }

    return $MatchSet
}
