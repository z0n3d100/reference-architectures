Configuration JoinDomain {
    param
    #v1.4
    (
        [Parameter(Mandatory)]
        [string]$DomainName,
      
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds
    )

    Import-DscResource -ModuleName xComputerManagement
       
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node localhost
    {
        xComputer JoinDomain
        {
            DomainName = $DomainName
            Credential = $DomainCreds
            Name = "localhost"
        }
   }
}