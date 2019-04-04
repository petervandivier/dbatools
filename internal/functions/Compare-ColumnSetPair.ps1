
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

    function ConvertTo-ColumnVector {
        <#
            .SYNOPSIS
                Standardize format of information needed to define a group of database columns.

            .DESCRIPTION
                This function is currently mapped to handle 3 possible input types. As of init commit, there are (loosely) 3 cases to handle for:
                    1. SMO $.Columns collection (see Get-DbaDbTable)
                    2. Labelled array
                    3. Unlabelled vector

                Any array with a type labelled "Name" will parse. If no label of "Name" is found, the only permissible input is a list.

                This function will also assign an Ordinal Position to each column by seeking for the "ID" attribute where available and assigning 1-indexed in-order incrementing numbers where not.

                (is)Identity, (is)Computed, and DataType attributes are persisted if supplied but other attributes are discarded

        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [object]$array
        )

        if ($array | Get-Member | Where-Object { $_.Name -eq "Name" }) {
            if (-not ($array | Get-Member | Where-Object { $_.Name -eq "ID" })) {
                # TODO: Handle for incomplete/gapped ID vector
                $ID = 0

                $array | ForEach-Object {
                    $ID += 1
                    $_ | Add-Member -MemberType "NoteProperty" -Name "ID" -Value $ID
                }
            }
        } else {
            if (($array | Get-Member | Where-Object { $_.MemberType -eq "Property" }).Count -eq 1 ) {
                # unlabelled/wrong-labelled vector
                $ID = 0
                $array = $array | ForEach-Object {
                    $ID += 1
                    [PSCustomObject]@{
                        ID   = $ID
                        Name = $_
                    }
                }
            } else {
                # "Name" attribute not found and the object is not a list
                # Silently fail and abort in outer function
            }
        }
        Remove-Variable ID -ErrorAction SilentlyContinue

        $array = $array | Sort-Object -Property 'ID' | ForEach-Object {

            [PSCustomObject]@{
                ID           = $_.ID
                Name         = $_.Name
                Identity     = $_.Identity
                Computed     = $_.Computed
                DataType     = $_.DataType
                IsExactMatch = [bool]$null
                IsMapped     = $false
            }
        }

        return $array
    }

    <#function Assert-UniqueLabel {
        [CmdletBinding()]
        param (
            [array]$array
        )
        $array.Count -eq ($array | Select-Object -Unique).Count
    }#>

    # $Source, $Target | Add-Member -MemberType NoteProperty -Name "IsUniqueLabel" -Value (Assert-UniqueLabel $_.Name)

    $SourceSet = ConvertTo-ColumnVector $Source
    $TargetSet = ConvertTo-ColumnVector $Target

    if (-not($SourceSet)) {
        $errMsg = "The array provided for the SOURCE column set could not be parsed."
    }
    if (-not($TargetSet)) {
        if ($errMsg) {
            $errMsg = "Neither array supplied for source or target could be parsed into a column set for comparison."
        } else {
            $errMsg = "The array provided for the TARGET column set could not be parsed."
        }
    }
    if ($errMsg) {
        # NOTE TO SELF - write-message before PR
        Write-Error $errMsg
        return
    }
    Remove-Variable errMsg -ErrorAction SilentlyContinue

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

        $TargetSet | Where-Object Name -EQ $SourceName | ForEach-Object {
            $_.IsExactMatch = $IsExactMatch
            $_.IsMapped = $IsMapped
        }

        [PSCustomObject]@{
            SourceID     = $SourceID
            SourceName   = $SourceName
            IsExactMatch = $IsExactMatch
            TargetID     = $TargetID
            TargetName   = $TargetName
        }

        # needed to handle for additional source columns not mapped in target
        # assume these could be disposed better with proper scoping?
        Remove-Variable SourceID, SourceName, TargetMatch, IsExactMatch, IsMapped, TargetID, TargetName -ErrorAction SilentlyContinue
    }

    $TargetSet | Where-Object { $_.IsMapped -eq $false } | ForEach-Object {
        $MatchSet += [PSCustomObject]@{
            IsExactMatch = $false
            TargetID     = $_.ID
            TargetName   = $_.Name
        }
    }

    return $MatchSet
}
