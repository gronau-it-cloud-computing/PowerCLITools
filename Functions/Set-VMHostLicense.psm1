function Set-VMHostLicense {
<#
    .SYNOPSIS
    Function to assign a license to a VMHost.
    
    .DESCRIPTION
    Function to assign a license to a VMHost.
    
    .PARAMETER VMHost
    VMHost to assign the license to.
    
    .PARAMETER LicenseKey
    License key of the license to assign to a VMHost.
    
    .PARAMETER LicenseName
    Optional name of the license.

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Set-VMHostLicense -LicenseKey "F2JQE-5SE2W-3KSN7-0SMH6-93NSH" -VMHost ESXi01
    
    .EXAMPLE
    PS> Get-VMHost ESXi01 | Set-VMHostLicense -LicenseKey "F2JQE-5SE2W-3KSN7-0SMH6-93NSH"
#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost,
    
    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$LicenseKey,   
    
    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$LicenseName 
    )    

    begin {
    
        
       
        # --- Check for the VIProperty OSName which should be loaded from the vSphere Tools Module Initialise script
        try {
            Get-VIProperty -Name VMHostID | Out-Null
        }        
        catch [Exception] {
            throw "Required VIProperty VMHostID does not exist"
        }   
               
        # --- Get access to the vCenter License Manager
        $ServiceInstance = Get-View ServiceInstance
        $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
        $LicenseAssignmentManager = Get-View $LicenseManager.LicenseAssignmentManager
    }
    
    process {
    

        try {

            
            foreach ($ESXiHost in $VMHost){
                if ($ESXiHost.GetType().Name -eq "string"){
                
                    try {
						$ESXiHost = Get-VMHost $ESXiHost -ErrorAction Stop
					}
					catch [Exception]{
						Write-Warning "VMHost $ESXiHost does not exist"
					}
                }
                
                elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]){
					Write-Warning "You did not pass a string or a VMHost object"
					Return
				}
                
                # --- Set the license via the License Manager with VMHostID
                $VMHostID = $ESXiHost.VMHostID
                
                $License = New-Object VMware.Vim.LicenseManagerLicenseInfo
                $License.LicenseKey = $LicenseKey
                
                if ($LicenseName){
                    $LicenseAssignmentManager.UpdateAssignedLicense($VMHostID, $License.LicenseKey, $LicenseName) | Out-Null
                }
                else {
                    $LicenseAssignmentManager.UpdateAssignedLicense($VMHostID, $License.LicenseKey, $null) | Out-Null
                }
                
            }
        }
        catch [Exception]{
        
            throw "Unable to set License $LicenseKey"
        }    
    }
    end {
        
    }
}