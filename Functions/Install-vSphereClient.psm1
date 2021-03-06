function Install-vSphereClient {
<#
    .SYNOPSIS
    Function to install VMware vSphere Client.
    
    .DESCRIPTION
    Function to install VMware vSphere Client.
    
    .PARAMETER MediaPath
    Path to the vCenter vSphere Client Media executable

    .PARAMETER InstallDir
    Custom directory to install vCenter vSphere Client
    
    .PARAMETER Quiet
    Do not display a dialogue box during install

    .INPUTS
    IO.FileInfo.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Install-vSphereClient -MediaPath "E:\Software\VMware\VIM\vSphere-Client\VMware-viclient.exe" -InstallDir "E:\VMware\vCenter Client"
#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [IO.FileInfo]$MediaPath,
     
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [IO.FileInfo]$InstallDir,
    
    [parameter(Mandatory=$false)]
    [Switch]$Quiet
    
    )
    
    
    try {    
        
        # --- Test the path to $MediaPath exists 
        if (!($MediaPath.Exists)) {throw "Cannot continue. vSphere Client Media does not exist"}

        
        # --- Build the arguments for the installer
        if ($PSBoundParameters.ContainsKey('Quiet')) {        
            $Arguments = " /q /s /w /L1033 /v`" /qn "
        }
        else {
            $Arguments = " /q /s /w /L1033 /v`" /qr "        
        }
        
        if ($PSBoundParameters.ContainsKey('InstallDir')) {
            $Arguments += "INSTALLDIR=\`"$($InstallDir)\`" "
        }
        
        $Arguments += "`""          

        Write-Verbose "Arguments for the install are: $arguments"
        
        # --- Start the install        
        Start-Process $MediaPath $Arguments -Wait
    }
    
    catch [Exception] {
        throw "Could not install the vSphere Client"
    }    
}