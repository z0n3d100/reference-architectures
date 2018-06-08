# DomainName                   - Active Directory Domain e.g.: contoso
# DomainFQDNName               - FQDN for the Active Directory Domain e.g.: contoso.local
# SqlAlwaysOnEndpointName      - SQL Always On endpoint name
# ServerRole                   - Server role, one of: Application | DistributedCache | WebFrontEnd | Search
# driveletter                  - Drive letter for the Data disk e.g.: F
# CentralAdmin                 - Indicates if the server is the central admin or not: "True" or "False"
# Passphrase                   - Passphrase PSCredentials object
# FarmAccount                  - Farm account PSCredentials object 
# SPSetupAccount               - A PSCredentials object with rights to create the farm
# ServicePoolManagedAccount    - Service Pool PSCredentials object
# WebPoolManagedAccount        - Web Pool PSCredentials object
# SuperUserAlias               - Super User alias
# SuperReaderAlias             - Super Reader alias
# webAppPoolName               - Web App Pool name
# serviceAppPoolName           - Service App Pool name
# RetryCount                   - Defines how many retries should be performed while waiting for the domain to be provisioned
# RetryIntervalSec             - Defines the seconds between each retry to check if the domain has been provisioned
configuration CreateJoinFarm
{
    param
    (
        [Parameter(Mandatory)]
        [String]$domainName,
		
        [Parameter(Mandatory)]
        [String]$DomainFQDNName,
		
        [Parameter(Mandatory)]
        [String]$SqlAlwaysOnEndpointName,
		
        [Parameter(Mandatory)]
        [String]$ServerRole,

        [Parameter(Mandatory)] 
        [String]$driveletter,
		
        [Parameter(Mandatory)] 
        [String]$CentralAdmin,
		
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Passphrase,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$FarmAccount,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SPSetupAccount,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$ServicePoolManagedAccount,
		
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WebPoolManagedAccount,
		
        [String] $SuperUserAlias = "sp_superuser",
        [String] $SuperReaderAlias = "sp_superreader",
        [string]$webAppPoolName = "SharePoint Sites",
        [string]$serviceAppPoolName = "Service App Pool",
		
        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName SharePointDsc
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xStorage, xComputerManagement, xActiveDirectory
    Import-DscResource -ModuleName xCredSSP

    node localhost
    {
        $runCentralAdmin = $false
        if ($CentralAdmin.ToLower() -eq "true")
        {
            $runCentralAdmin = $true
        }

        [System.Management.Automation.PSCredential]$FarmAccountCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($FarmAccount.UserName)", $FarmAccount.Password)
        [System.Management.Automation.PSCredential]$SPSetupAccountCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($SPSetupAccount.UserName)", $SPSetupAccount.Password) 
        [System.Management.Automation.PSCredential]$ServicePoolManagedAccountCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($ServicePoolManagedAccount.UserName)", $ServicePoolManagedAccount.Password) 
        [System.Management.Automation.PSCredential]$WebPoolManagedAccountCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($WebPoolManagedAccount.UserName)", $WebPoolManagedAccount.Password) 

        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true
            AllowModuleOverWrite = $true
        }
        
        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec = $RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk2
        {
            DiskNumber = 2
            DriveLetter = $driveletter
            FSLabel = 'Data'
            DependsOn = '[xWaitforDisk]Disk2'
        }
		
        WindowsFeature ADPowerShell
        {
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
            DependsOn = '[xDisk]ADDataDisk2'
        }

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $DomainFQDNName
            DomainUserCredential= $SPSetupAccountCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec 
	        DependsOn = "[WindowsFeature]ADPowerShell"
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainFQDNName
            Credential = $SPSetupAccountCreds
	        DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        WindowsFeature DNSPowerShell
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = '[xDisk]ADDataDisk2'
        }

        #**********************************************************
        # Basic farm configuration
        #
        # This section creates the new SharePoint farm object, and
        # provisions generic services and components used by the
        # whole farm
        #**********************************************************
        SPFarm CreateSPFarm
        {
            Ensure                   = "Present"
            DatabaseServer           = $SqlAlwaysOnEndpointName
            FarmConfigDatabaseName   = "SP_Config_2016"
            Passphrase               = $Passphrase
            FarmAccount              = $FarmAccountCreds
            PsDscRunAsCredential     = $SPSetupAccount
            AdminContentDatabaseName = "SP_AdminContent"
            CentralAdministrationPort = "2016"
            RunCentralAdmin          = $runCentralAdmin
            ServerRole               = $ServerRole
        }
        SPManagedAccount ServicePoolManagedAccount
        {
            AccountName          = $ServicePoolManagedAccount.UserName
            Account              = $ServicePoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }
        SPManagedAccount WebPoolManagedAccount
        {
            AccountName          = $WebPoolManagedAccount.UserName
            Account              = $WebPoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }

        xCredSSP CredSSPServer
        { 
            Ensure = "Present"
            Role = "Server"
        } 
       
        xCredSSP CredSSPClient
        { 
            Ensure = "Present"
            Role = "Client"
            DelegateComputers = "*.$DomainFQDNName"
        }

        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
        {
            PsDscRunAsCredential                        = $SPSetupAccount
            LogPath                                     = "F:\ULS"
            LogSpaceInGB                                = 5
            AppAnalyticsAutomaticUploadEnabled          = $false
            CustomerExperienceImprovementProgramEnabled = $true
            DaysToKeepLogs                              = 7
            DownloadErrorReportingUpdatesEnabled        = $false
            ErrorReportingAutomaticUploadEnabled        = $false
            ErrorReportingEnabled                       = $false
            EventLogFloodProtectionEnabled              = $true
            EventLogFloodProtectionNotifyInterval       = 5
            EventLogFloodProtectionQuietPeriod          = 2
            EventLogFloodProtectionThreshold            = 5
            EventLogFloodProtectionTriggerPeriod        = 2
            LogCutInterval                              = 15
            LogMaxDiskSpaceUsageEnabled                 = $true
            ScriptErrorReportingDelay                   = 30
            ScriptErrorReportingEnabled                 = $true
            ScriptErrorReportingRequireAuth             = $true
            DependsOn                                   = "[SPFarm]CreateSPFarm"
        }
        SPUsageApplication UsageApplication
        {
            Name                  = "Usage Service Application"
            DatabaseName          = "SP2016_Usage"
            UsageLogCutTime       = 5
            UsageLogLocation      = "F:\UsageLogs"
            UsageLogMaxFileSizeKB = 1024
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[SPFarm]CreateSPFarm"
        }
        SPStateServiceApp StateServiceApp
        {
            Name                 = "State Service Application"
            DatabaseName         = "SP2016_State"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }

        if ($ServerRole -eq "DistributedCache" -or $ServerRole -eq "SingleServerFarm" -or $ServerRole -eq "Custom" )
        {        
            SPDistributedCacheService EnableDistributedCache
            {
                Name                 = "AppFabricCachingService"
                Ensure               = "Present"
                CacheSizeInMB        = 1024
                ServiceAccount       = $ServicePoolManagedAccount.UserName
                PsDscRunAsCredential = $SPSetupAccount
                CreateFirewallRules  = $true
                DependsOn            = @('[SPFarm]CreateSPFarm','[SPManagedAccount]ServicePoolManagedAccount')
            }
        }

        #**********************************************************
        # Web applications
        #
        # This section creates the web applications in the
        # SharePoint farm, as well as managed paths and other web
        # application settings
        #**********************************************************
        SPServiceAppPool MainServiceAppPool
        {
            Name = $serviceAppPoolName
            ServiceAccount = $ServicePoolManagedAccountCreds.UserName
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn = @("[SPFarm]CreateSPFarm", "[SPManagedAccount]WebPoolManagedAccount")
        }

        if ($ServerRole -eq "WebFrontEnd")
        {		
            SPWebApplication SharePointSites
            {
                Name = "SharePoint Sites"
                ApplicationPool = $webAppPoolName
                ApplicationPoolAccount = $WebPoolManagedAccountCreds.UserName
                AllowAnonymous = $false
                # AuthenticationMethod = "NTLM"
                DatabaseName = "SP2016_Sites_Content"
                Url = "http://portal.$DomainFQDNName"
                HostHeader = "portal.$DomainFQDNName"
                Port = 80
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = @("[SPFarm]CreateSPFarm", "[SPManagedAccount]WebPoolManagedAccount")
            }
        
            SPWebApplication OneDriveSites
            {
                Name = "OneDrive"
                ApplicationPool = $webAppPoolName
                ApplicationPoolAccount = $WebPoolManagedAccountCreds.UserName
                AllowAnonymous = $false
                # AuthenticationMethod = "NTLM"
                DatabaseName = "SP2016_Sites_OneDrive"
                HostHeader = "OneDrive.$DomainFQDNName"
                Url = "http://OneDrive.$DomainFQDNName"
                Port = 80
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = @("[SPFarm]CreateSPFarm", "[SPManagedAccount]WebPoolManagedAccount")
            }

            SPCacheAccounts WebAppCacheAccounts
            {
                WebAppUrl = "http://Portal.$DomainFQDNName"
                SuperUserAlias = "${DomainName}\$SuperUserAlias"
                SuperReaderAlias = "${DomainName}\$SuperReaderAlias"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPWebApplication]SharePointSites"
            }

            SPCacheAccounts OneDriveCacheAccounts
            {
                WebAppUrl = "http://OneDrive.$DomainFQDNName"
                SuperUserAlias = "${DomainName}\$SuperUserAlias"
                SuperReaderAlias = "${DomainName}\$SuperReaderAlias"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPWebApplication]OneDriveSites"
            }

            SPSite TeamSite
            {
                Url = "http://Portal.$DomainFQDNName"
                OwnerAlias = $SPSetupAccountCreds.UserName
                Name = "Root Demo Site"
                Template = "STS#0"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPWebApplication]SharePointSites"
            }

            SPSite MySiteHost
            {
                Url = "http://OneDrive.$DomainFQDNName"
                OwnerAlias = $SPSetupAccountCreds.UserName
                Name = "OneDrive"
                Template = "SPSMSITEHOST#0"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPWebApplication]OneDriveSites"
            }
        }
        
        #**********************************************************
        # Service instances
        #
        # This section describes which services should be running
        # and not running on the server
        #**********************************************************

        if ($ServerRole -eq "WebFrontEnd" -or $ServerRole -eq "Application" -or $ServerRole -eq "SingleServerFarm" -or $ServerRole -eq "Custom" )
        {
            SPServiceInstance AppManagementServiceInstance
            {  
                Name = "App Management Service"
                Ensure = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPServiceAppPool]MainServiceAppPool" 
            }
            SPServiceInstance ManagedMetadataServiceInstance
            {  
                Name = "Managed Metadata Web Service"
                Ensure = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPServiceAppPool]MainServiceAppPool" 
            }
            SPServiceInstance SubscriptionSettingsServiceInstance
            {  
                Name = "Microsoft SharePoint Foundation Subscription Settings Service"
                Ensure = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPServiceAppPool]MainServiceAppPool" 
            }
            SPServiceInstance UserProfileServiceInstance
            {  
                Name = "User Profile Service"
                Ensure = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPServiceAppPool]MainServiceAppPool" 
            }
        }

        if ($ServerRole -eq "Search" -or $ServerRole -eq "SingleServerFarm" -or $ServerRole -eq "Custom" )
        {
            SPServiceInstance SearchServiceInstance
            {  
                Name = "SharePoint Server Search"
                Ensure = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = "[SPServiceAppPool]MainServiceAppPool" 
            }
        }
        #**********************************************************
        # Service applications
        #
        # This section creates service applications and required
        # dependencies
        #**********************************************************

        if ($ServerRole -eq "WebFrontEnd" -or $ServerRole -eq "Application" -or $ServerRole -eq "SingleServerFarm" -or $ServerRole -eq "Custom" )
        {
            SPAppManagementServiceApp AppManagementServiceApp
            {
                Name = "App Management Service Application"
                ApplicationPool = $serviceAppPoolName
                DatabaseName = "SP2016_AppManagement"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = '[SPServiceAppPool]MainServiceAppPool'      
            }

            SPSubscriptionSettingsServiceApp SubscriptionSettingsServiceApp
            {
                Name = "Subscription Settings Service Application"
                ApplicationPool = $serviceAppPoolName
                DatabaseName = "SP2016_SubscriptionSettings"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn = '[SPServiceAppPool]MainServiceAppPool'      
            }

            SPManagedMetaDataServiceApp ManagedMetadataServiceApp
            {  
                Name = "Managed Metadata Service Application"
                PsDscRunAsCredential = $SPSetupAccount
                ApplicationPool = $serviceAppPoolName
                DatabaseName = "SP2016_MMS"
                DependsOn = @('[SPServiceAppPool]MainServiceAppPool', '[SPServiceInstance]ManagedMetadataServiceInstance')
            }
            if ($ServerRole -eq "WebFrontEnd" )
            {
                SPUserProfileServiceApp UserProfileApp
                {
                    Name = "User Profile Service Application"
                    ProfileDBName = "SP2016_Profile"
                    ProfileDBServer = $SqlAlwaysOnEndpointName
                    SocialDBName = "SP2016_Social"
                    SocialDBServer = $SqlAlwaysOnEndpointName
                    SyncDBName = "SP2016_Sync"
                    SyncDBServer = $SqlAlwaysOnEndpointName
                    MySiteHostLocation = "http://OneDrive.$DomainFQDNName"
                    # FarmAccount = $FarmAccountCreds
                    ApplicationPool = $serviceAppPoolName
                    PsDscRunAsCredential = $SPSetupAccount
                    DependsOn = '[SPServiceAppPool]MainServiceAppPool'
                }
            }

            if ($ServerRole -eq "Application" -or $ServerRole -eq "SingleServerFarm" -or $ServerRole -eq "Custom" )
            {
                SPUserProfileServiceApp UserProfileApp
                {
                    Name = "User Profile Service Application"
                    ProfileDBName = "SP2016_Profile"
                    ProfileDBServer = $SqlAlwaysOnEndpointName
                    SocialDBName = "SP2016_Social"
                    SocialDBServer = $SqlAlwaysOnEndpointName
                    SyncDBName = "SP2016_Sync"
                    SyncDBServer = $SqlAlwaysOnEndpointName
                    # FarmAccount = $FarmAccountCreds
                    ApplicationPool = $serviceAppPoolName
                    PsDscRunAsCredential = $SPSetupAccount
                    DependsOn = '[SPServiceAppPool]MainServiceAppPool'
                }
            }       
        }

    }
}
