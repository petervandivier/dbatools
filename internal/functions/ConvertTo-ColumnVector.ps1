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

    # having trouble leaking scope on variable modifications. i'm sure there's a cleaner way to do this...

    if ($array.PSObject.Properties.TypeNameOfValue -contains 'Microsoft.SqlServer.Management.Smo.SqlSmoObject') {
        # do nothing, the object is well-formed (I hope...)
        # TODO: make this suck less
        # TODO: Handle for [tables[]].Columns input :facepalm:
    } else {
        # If object has NoteProperties, attempt to parse them

        $ID = 0

        $return_array = $array | Get-Member | Where-Object MemberType -eq 'NoteProperty' | ForEach-Object {
            $ID += 1

            [PSCustomObject]@{
                ID   = $ID
                Name = $_.Name
            }
        }

        if (-not($return_array)) {
            # no NoteProperties were found; object is a list
            # Assign each leaf as the "Name" value and infer ordinal position

            $return_array = $array | ForEach-Object {
                $ID += 1

                [PSCustomObject]@{
                    ID   = $ID
                    Name = $_
                }
            }
        }

        Remove-Variable ID -ErrorAction SilentlyContinue
    }

    $return_array = $return_array | ForEach-Object {
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
