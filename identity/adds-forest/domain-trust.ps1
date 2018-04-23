$strRemoteDomain = "contoso.com"
$strRemoteAdmin = "testuser"
$strRemoteAdminPassword = "AweS0me@PW"

$remoteContext = New-Object -TypeName "System.DirectoryServices.ActiveDirectory.DirectoryContext" -ArgumentList @( "Domain", $strRemoteDomain, $strRemoteAdmin, $strRemoteAdminPassword)
try {
        $remoteDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($remoteContext)
        Write-Host "GetDomain: Succeeded for domain $($remoteDomain)"
    }
catch {
        Write-Warning "GetDomain: Failed:`n`tError: $($($_.Exception).Message)"
}
Write-Host "Connected to domain: $($remoteDomain.Name)"

$localDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
Write-Host "Connected to Local domain: $($localDomain.Name)"
try {
        $localDomain.CreateTrustRelationship($remoteDomain,"Inbound")
        Write-Host "CreateTrustRelationship: Succeeded for domain $($remoteDomain)"
}
catch {
        Write-Warning "CreateTrustRelationship: Failed for domain $($remoteDomain)`n`tError: $($($_.Exception).Message)"
}