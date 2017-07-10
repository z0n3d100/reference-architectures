
$primaryInst = "SQL2.contoso.local"
$secondaryInst = "SQL1.contoso.local"
$MyAgPrimaryPath = "SQLSERVER:\SQL\SQL2.contoso.local\AvailabilityGroups\alwayson-ag"  
$MyAgSecondaryPath = "SQLSERVER:\SQL\SQL1.contoso.local\AvailabilityGroups\alwayson-ag"  

#Add-Type -AssemblyName "Microsoft.SqlServer.Smo"
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo");
import-module SQLps;
# Connect to the specified instance
$srv = new-object ('Microsoft.SqlServer.Management.Smo.Server') $primaryInst
New-Item "f:\backup" –type directory

New-SMBShare –Name "Backup" –Path "f:\backup"  –FullAccess contoso\sqlservicetestuser,contoso\testuser

# Cycle through the databases
foreach ($db in $srv.Databases) {
    if ($db.IsSystemObject -ne $True -and $db.Name -notlike "AutoHa*") 
    {
        $dbname = $db.Name
        #"Changing database $dbname to set Recovery Model to Full"
        $db.RecoveryModel = 'Full'
        $db.Alter()
        $DatabaseBackupFile = "\\" + $primaryInst + "\Backup\" + $dbname +".bak"
        $LogBackupFile =   "\\" + $primaryInst + "\Backup\"  + $dbname +"_log.trn"

        Backup-SqlDatabase -Database $dbname -BackupFile $DatabaseBackupFile -ServerInstance $primaryInst  
        Backup-SqlDatabase -Database $dbname -BackupFile $LogBackupFile -ServerInstance $primaryInst  -BackupAction Log
        
        Restore-SqlDatabase -Database $dbname -BackupFile $DatabaseBackupFile -ServerInstance $secondaryInst -NoRecovery 
        Restore-SqlDatabase -Database $dbname -BackupFile $LogBackupFile -ServerInstance $secondaryInst -RestoreAction 'Log'   -NoRecovery

        Add-SqlAvailabilityDatabase -Path $MyAgPrimaryPath -Database $dbname  
        Add-SqlAvailabilityDatabase -Path $MyAgSecondaryPath -Database $dbname  
        
    }
}

