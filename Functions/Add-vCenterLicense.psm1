function Add-vCenterLicense {
<#
    .SYNOPSIS
    Function to add a license to vCenter.
    
    .DESCRIPTION
    Function to add a license to vCenter.
    
    .PARAMETER LicenseKey
    License key of the license to add to vCenter

    .INPUTS
    String.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Add-vCenterLicense -LicenseKey "F2JQE-5SE2W-3KSN7-0SMH6-93NSH","SMNW9-0276S-02MJS-HFNDJ-WKDM4"
    
    .EXAMPLE
    PS> "F2JQE-5SE2W-3KSN7-0SMH6-93NSH" | Add-vCenterLicense
#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$LicenseKey   
    )    

    begin {    
               
        # --- Get access to the vCenter License Manager
        $ServiceInstance = Get-View ServiceInstance
        $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
    }
    
    process {
    

        try {
            
            foreach ($Key in $LicenseKey){
                
                # --- Test the License Key is valid
                $LicenseDecode = $LicenseManager.DecodeLicense("$Key")
                $LicenseDecode.Properties | ForEach-Object {
                
                    if ($_.Key -eq "lc_error"){
                    
                        Write-Warning "License Key $Key is invalid, unable to add this key"
                        
                        $LicenseDecode.Properties | ForEach-Object {
                        
                            if ($_.Key -eq "diagnostic"){
                            
                                Write-Warning "Reason: $($_.Value)"
                            }
                        }
                        
                        Continue
                    }
                }
                
                # --- Add the License Key to vCenter
                $AddedLicense = $LicenseManager.AddLicense("$Key",$null)

            }
        }
        catch [Exception]{
        
            throw "Unable to add License $Key"
        }    
    }
    end {
        
    }
}