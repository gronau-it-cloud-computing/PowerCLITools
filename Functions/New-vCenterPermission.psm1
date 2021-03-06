function New-vCenterPermission {
<#
    .SYNOPSIS 
    Create a new permission in vCenter.

    .DESCRIPTION
    Create a new permission in vCenter.

    .PARAMETER Folder
    Name of the vCenter folder to assign the permission to.
    
    .PARAMETER ADPrincipal
    Name of the ADPrincipal to assign the permission for.
    
    .PARAMETER Role
    Name of the vCenter role to grant the permission

    .INPUTS
    None. You cannot pipe objects to New-vCenterPermission.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> New-vCenterPermission -Folder 'Toplevel' -ADPrincipal 'Ops\Test Users' -Role Administrator

#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Folder,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ADPrincipal,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Role
    )
    
    
    try
    {    
       
        # Check the vCenter role exists
         Write-Verbose "Checking the vCenter role $Role exists...`n"
        
        if (!(Get-VIRole | Where-Object {$_.Name -eq $Role})){
            throw "$Role role does not exist..."
        }
    
    
        Write-Verbose "Retrieving vCenter folder $folder...`n"
        
        if ($Folder -eq 'TopLevel'){
            $Entity = Get-Folder -Name Datacenters
        }
        else{
            $Entity = Get-Folder | Where-Object {$_.Name -eq $Folder -and $_.Type -eq 'VM'}
            
            if (!($Entity)){
                throw "Folder $folder does not exist..."
            }
        }
    
        Write-Verbose "Creating new vCenter Permission on folder $Folder for $ADPrincipal with role $Role...`n"
        
        New-VIPermission -Entity $Entity -Principal $ADPrincipal -Role $Role
        
        Write-Verbose "Created new vCenter Permission on folder $Folder for $ADPrincipal with role $Role...`n"
        
    }
    catch [Exception]
    {
        throw "New vCenter Permission not created...`n"
    }    
}