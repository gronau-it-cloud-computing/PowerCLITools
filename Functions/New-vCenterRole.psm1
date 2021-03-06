function New-vCenterRole {
<#
    .SYNOPSIS 
    Create a new role in vCenter.

    .DESCRIPTION
    Create a new role in vCenter.

    .PARAMETER Name
    Name of the vCenter role.
    
    .PARAMETER Privileges
    Privileges to add to the vCenter Role.

    .INPUTS
    None. You cannot pipe objects to New-vCenterRole.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> New-vCenterRole -Name 'Operations' -Privileges 'Allocate space','Health'

#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Privileges
    )
    
    
    try
    {    
        if (Get-VIRole | Where-Object {$_.Name -eq $Name}){
            Write-Verbose "$Name role already exists..."
        }
        else
        {
            Write-Verbose "Creating new vCenter Role $Name...`n"
            New-VIRole -Name $Name -Privilege $Privileges | Out-Null
            Write-Verbose "New vCenter Role $Name created successfully...`n"
        }
    }
    catch [Exception]
    {
        throw "New vCenter Role $Name not created...`n"
    }    
}