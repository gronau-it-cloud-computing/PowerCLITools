function Set-VMHostSyslogConfig {
<#
    .SYNOPSIS
    Function to set the Syslog config of a VMHost.
    
    .DESCRIPTION
    Function to set the Syslog config of a VMHost. Added extra functionality that Set-VMHostSysLogServer is missing
    Set-VMHostSysLogServer does not (currently) include the ability to set protocol specific paths, e.g. ssl://syslog01.domain.local
    Set-VMHostSysLogServer does not (currently) include the ability to add multiple Syslogservers
    Set-VMHostSysLogServer also does not open the necessary firewall ports in ESXi 5.0 or make the configuration active straightaway
    
    .PARAMETER VMHost
    VMHost to configure Syslog settings for.

    .PARAMETER SyslogServer
    SyslogServer to use

    .PARAMETER SyslogServerPort
    SyslogServerPort to use
    
    .PARAMETER Protocol
    Protocol to use for Syslog server

    .PARAMETER Reload
    Reload the config after a change or vCenter restart

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Set-VMHostSyslogConfig -SyslogServer "syslog01.domain.local" -VMHost ESXi01

    .EXAMPLE
    Set both servers "syslog01.domain.local","splunk.domain.local" to use SSL and port 1514

    PS> Set-VMHostSyslogConfig -SyslogServer "syslog01.domain.local","splunk.domain.local" -Protocol SSL -SyslogServerPort 1514 -VMHost ESXi01

    .EXAMPLE
    Set a mixture of servers, protocols and ports

    PS> Set-VMHostSyslogConfig -SyslogServer "syslog01.domain.local","ssl://splunk.domain.local:1514" -VMHost ESXi01
    
    .EXAMPLE
    PS> Get-VMHost ESXi01 | Set-VMHostSyslogConfig -SyslogServer "syslog01.domain.local"

#>
[CmdletBinding(DefaultParametersetName="Configure")]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost,

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="Configure")]
    [ValidateNotNullOrEmpty()]
    [String[]]$SyslogServer,

    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="Configure")]
    [ValidateNotNullOrEmpty()]
    [int]$SyslogServerPort,
    
    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="Configure")]
    [ValidateSet("UDP","TCP","SSL")]
    [String]$Protocol,

    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="Reload")]
    [Switch]$Reload
    )    

    begin {
        
        # --- Create the value to enter into Syslog.global.logHost
        $SyslogGlobalLoghostObject = @()


        foreach ($SyslogDestination in $SyslogServer){

            $SyslogGlobalLoghost = $SyslogDestination

            if ($PSBoundParameters.ContainsKey('Protocol')){

                $SyslogGlobalLoghost = $Protocol.ToLower() + "://" + $SyslogGlobalLoghost
            }

            if ($PSBoundParameters.ContainsKey('SyslogServerPort')){

                $SyslogGlobalLoghost = $SyslogGlobalLoghost + ":" + $SyslogServerPort
            }

            $SyslogGlobalLoghostObject += $SyslogGlobalLoghost
       }

       if (($SyslogGlobalLoghostObject | Measure-Object).Count -gt 1){

            $SyslogGlobalLoghostAdvancedSetting = $SyslogGlobalLoghostObject -join ", "
       }
       else {
            
            $SyslogGlobalLoghostAdvancedSetting = $SyslogGlobalLoghostObject[0]
       }        
    }
    
    process {    
    
        foreach ($ESXiHost in $VMHost){

            try {            

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
            

                switch ($PsCmdlet.ParameterSetName) 
                { 
                    "Configure"  {
                
                        Write-Verbose "Configuring the Syslog service for $ESXiHost"
                    
                    
                        # --- Open firewall ports for Syslog if ESXi 5 or later

                        if ($ESXiHost.Version -ge 5){

                            Write-Verbose "Opening firewall ports for Syslog on $ESXiHost"
                            $SyslogFirewall = Get-VMHostFirewallException -VMHost $ESXiHost -Name Syslog

                            if (!($SyslogFirewall.Enabled)){
                            
                                try {

                                    $SyslogFirewall | Set-VMHostFirewallException -Enabled $true | Out-Null
                                    Write-Verbose "Successfully opened firewall ports for Syslog on $ESXiHost"
                                }
                                catch [Exception]{
                                
                                    Write-Verbose "Failed to open firewall ports for Syslog on $ESXiHost"
                                }
                            }
                            else {

                                Write-Verbose "Firewall ports for Syslog on $ESXiHost are already open"
                            }

                        }
                        else {

                            Write-Verbose "ESXi version is less than 5 so no need to open firewall ports"
                        }

                        # --- Set Advanced Configuration value Syslog.global.logHost

                        Write-Verbose "Setting $SyslogGlobalLoghostAdvancedSetting as Syslog.global.logHost on $ESXiHost"

                        try {

                            Get-AdvancedSetting -Entity $ESXiHost -Name 'Syslog.global.logHost' | Set-AdvancedSetting -Value $SyslogGlobalLoghostAdvancedSetting -Confirm:$false | Out-Null
                            Write-Verbose "Successfully set $SyslogGlobalLoghostAdvancedSetting as Syslog.global.logHost on $ESXiHost"
                        }
                        catch [Exception]{

                            Write-Verbose "Unable to set $SyslogGlobalLoghostAdvancedSetting as Syslog.global.logHost on $ESXiHost"    
                        }

                        # --- Restart the Syslog service via ESXCli
                        Write-Verbose "Restarting the Syslog service for $ESXiHost"
                        $ESXCli = Get-EsxCli -VMHost $ESXiHost
                        $Refresh = $ESXCli.System.Syslog.Reload()

                        if ($Refresh -eq "true"){

                            Write-Verbose "Syslog service for $ESXiHost was successfully restarted"
                        }
                        else {
                        
                            Write-Verbose "There was an issue restarting the Syslog service for $ESXiHost"
                        }

                        break
                    }
                 
                    "Reload"  {
                    
                        # --- Restart the Syslog service via ESXCli
                        Write-Verbose "Restarting the Syslog service for $ESXiHost"
                        $ESXCli = Get-EsxCli -VMHost $ESXiHost
                        $Refresh = $ESXCli.System.Syslog.Reload()

                        if ($Refresh -eq "true"){

                            Write-Verbose "Syslog service for $ESXiHost was successfully restarted"
                        }
                        else {
                        
                            Write-Verbose "There was an issue restarting the Syslog service for $ESXiHost"
                        }

                        break
                    } 
                }
            }
            catch [Exception]{
        
                throw "Unable to set Syslog config"
            }
        }   
    }
    end {
        
    }
}