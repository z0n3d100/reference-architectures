Configuration AddADFSNode
{ 
   param
    (
        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$DomainName,
        
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,
        
        [Parameter(Mandatory)]
        [string]$NetBiosDomainName,

        [Parameter(Mandatory)]
        [string]$PrimaryAdfsServer,

        [Parameter(Mandatory)]
        [string]$FederationName,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    #Import the required DSC Resources
    Import-DscResource -Module xActiveDirectory, xPendingReboot, xComputerManagement, cADFS
    
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Thumbprint =(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint
    
    Node localhost
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = "ContinueConfiguration"            
            ConfigurationMode = "ApplyOnly"            
            RebootNodeIfNeeded = $true            
        }

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec
        }
         
        xComputer JoinDomain
        {
            Name          = $MachineName 
            DomainName    = $DomainName
            Credential    = $DomainCreds  # Credential to join to domain
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot1
        { 
            Name = "RebootServer"
            DependsOn = "[xComputer]JoinDomain"
        }

        WindowsFeature InstallADFS
        {
            Ensure = "Present"
            Name   = "ADFS-Federation"
            IncludeAllSubFeature = $true
            DependsOn = "[xPendingReboot]Reboot1"
        }

        cADFSNode AddADFSNode
        {   
            Ensure = "Present"
            PrimaryADFSServer = $PrimaryAdfsServer
            CertificateThumbprint = $Thumbprint
            ServiceCredential = $DomainCreds
            DependsOn = "[WindowsFeature]InstallADFS"
        }

        $ServiceAccountName = "${NetBiosDomainName}\$($Admincreds.UserName)";

        cADFSDeviceRegistration cADFSDeviceRegistration
        {
            Ensure = "Present"
            DomainName = "contoso.com"
            ServiceCredential = $DomainCreds
            InstallCredential = $DomainCreds
            ServiceAccountName = $ServiceAccountName
            RegistrationQuota = 10
            MaximumRegistrationInactivityPeriod = 90
            DependsOn = "[cADFSNode]AddADFSNode"         
        }
    }
}