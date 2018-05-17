# Sharepoint 2016 with azbb v2 and DSC

Run the following azbb templates:

1. sharepoint-2016-v2.json  (setup onprem and part of sharepoint infraestructure, prepare cluster)

2. sharepoint-2016-v2-create-cluster-ext.json  (create cluster and always on group and listener)

3. sharepoint-2016-v2-part2.json (create the rest of the infraestructure)

4. sharepoint-2016-v2-create-farm-ext.json (create sharepoint farm primary node)

5. sharepoint-2016-v2-part2-extensions.json (create sharepoint cache, search and web)

6. sharepoint-2016-v2-security.json (create network security groups)



$TrustedDomainName = "contoso.local"
#$TrustedDomainDnsIpAddresses = "192.168.0.4,192.168.0.5"

$TrustingDomainName = "fabrikam.com"
$TrustingDomainDnsIpAddresses = "192.168.0.4,192.168.0.5"

$ForwardIpAddress  = $TrustingDomainDnsIpAddresses
$ForwardDomainName = $TrustingDomainName

$IpAddresses = @()
foreach($address in $ForwardIpAddress.Split(',')){
    $IpAddresses += [IPAddress]$address.Trim()
}
Add-DnsServerConditionalForwarderZone -Name "$ForwardDomainName" -ReplicationScope "Domain" -MasterServers $IpAddresses

netdom trust $TrustingDomainName /d:$TrustedDomainName /add