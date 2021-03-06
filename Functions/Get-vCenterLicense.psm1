function Get-vCenterLicense {
<#
    .SYNOPSIS
    Function to retrieve vCenter licenses.
    
    .DESCRIPTION
    Function to retrieve vCenter licenses.
    
    .PARAMETER LicenseKey
    License key to query

    .INPUTS
    String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-vCenterLicense
    
    .EXAMPLE
    PS> Get-vCenterLicense -LicenseKey "F2JQE-5SE2W-3KSN7-0SMH6-93NSH"
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (
    
    [parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$LicenseKey  
    ) 
    
    begin {
    
        $LicenseObject = @()    
        
        # --- Get access to the vCenter License Manager
        $ServiceInstance = Get-View ServiceInstance
        $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
    }
    
    process {
    
        try {
            
            if ($LicenseKey){
               
                # --- Query the License Manager
                foreach ($Key in $LicenseKey){
                
                    if ($License = $LicenseManager.Licenses | Where-Object {$_.LicenseKey -eq $Key}){
                    
                        $Object = [pscustomobject]@{                        
                            
                            Key = $License.LicenseKey
                            Type = $License.Name
                            Total = $License.Total
                            Used = $License.Used
                        }
                        
                        $LicenseObject += $Object
                    }
                    else {
                        Write-Verbose "Unable to find license key $Key"
                    }                    
                }
                            
            }
			else {

				# --- Query the License Manager
				foreach ($License in $LicenseManager.Licenses){
			
				$Object = [pscustomobject]@{                        
					
					Key = $License.LicenseKey
					Type = $License.Name
					Total = $License.Total
					Used = $License.Used
				}
				
				$LicenseObject += $Object
				}
            }
        }
            
        catch [Exception]{
        
            throw "Unable to retrieve Licenses for vCenter $defaultVIServer"
        } 
    }
    
    end {
        Write-Output $LicenseObject
    }
}