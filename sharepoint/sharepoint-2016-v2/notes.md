# Sharepoint 2016 with azbb v2 and DSC

## Differences with the doc:

- I had to shorten the names on several of the VMs, so they no longer match the ones in the doc.

- On the 'Validate access to the SharePoint site from the on-premises network' section 
    https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/sharepoint/#validate-access-to-the-sharepoint-site-from-the-on-premises-network
    Point 4 and 5 were not needed, access to http://portal.contoso.local required no credentials.

## Deployment order:

1. sharepoint-2016-v2.json  (setup onprem and part of sharepoint infraestructure, prepare cluster)

2. sharepoint-2016-v2-create-cluster-ext.json  (create cluster and always on group and listener)

3. sharepoint-2016-v2-part2.json (create the rest of the infraestructure)

At this point you should check TCP connectivity between 'ra-sp-app-vm1' and 'ra-sp-sql-lb' on port 1433
Otherwise reboot 'ra-sp-sql2-vm2'.

4. sharepoint-2016-v2-create-farm-ext.json (create sharepoint farm primary node)

This extension sometimes fail but DSC keeps retrying and succeeds at installing the sharepoing farm.

5. sharepoint-2016-v2-part2-extensions.json (create sharepoint cache, search and web)

6. sharepoint-2016-v2-security.json (create network security groups)
