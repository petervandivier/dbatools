
function ConvertTo-ColumnVector {
    <#
        .SYNOPSIS
            Standardize format of information needed to define a group of database columns.

        .DESCRIPTION
            This function is intends to handle 2 main cases. We expect either a strict [ColumnCollection] or a user-supplied array (which must be error-corrected)
                1. [Microsoft.SqlServer.Management.Smo.ColumnCollection]
                2. [System.Array]

            Given an array, we attempt to extract Ordinal Position ("ID"), or infer it if it is not parsed.

            If

            (is)Identity, (is)Computed, and DataType attributes are persisted if supplied but other attributes are discarded
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$array
    )
    <# TODO:
    function Assert-UniqueLabel {
        [CmdletBinding()]
        param (
            [array]$array
        )
        $array.Count -eq ($array | Select-Object -Unique).Count
    }#>

    # if ()
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
        if (($array | Get-Member | Where-Object { $_.MemberType -like "Property" }).Count -eq 1 ) {
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

    $return_array = $array | ForEach-Object {
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

    return $return_array
}
