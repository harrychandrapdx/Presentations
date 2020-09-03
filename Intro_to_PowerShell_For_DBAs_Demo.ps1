# The demo are running on PowerShell 5.1 with Windows Server 2019 & SQL Server 2019

#####################################################################
#
# Checking Powershell Version 
#
#####################################################################

$PSVersionTable 

#####################################################################
#
# PowerShell Execution Policy - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7
#
#####################################################################
 
Get-ExecutionPolicy -Scope CurrentUser

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser # RemoteSigned is most common settings for Execution Policy. Default is Restricted.

#####################################################################
#
# Working with Modules
#
#####################################################################

Get-Module # List of loaded modules

Get-InstalledModule # List of all installed modules

####  Need to run in powershell session as Administrator to allow all users in the machine to have access to the module  #####
Install-Module -Name dbatools # Optional: if not running as Administrator, add: -Scope AllUsers OR CurrentUser 
Install-Module -Name SqlServer
##############################################################

Import-Module -Name dbatools # To load module before cmdlets available for use
Import-Module -Name SqlServer # To load module before cmdlets available for use

Update-Module -Name SqlServer

Remove-Module -Name dbatools # To unload module

Uninstall-Module -Name ModuleName # To uninstall module

Save-Module -Name dbatools -Path "<Location C:\Temp>" 

#####################################################################
#
# Basic helpful cmdlets 
#
#####################################################################

Get-Command -Module sqlserver # Returns all cmdlets in the module

(Get-Command -Module sqlserver).count # To find out the count of cmdlets available in the SqlServer module

Get-Help Get-Service -online # Get info on cmdlet Get-Service directly from MS Docs. This will open a browser.

Get-Service | Get-Member # This will return the methods, properties and type of the object. 

Get-Alias # Return a list of alias in the environment


#####################################################################
#
# Check for SQL Server service
#
#####################################################################

Get-Service -ComputerName "SQL2019-01" | Where-Object DisplayName -like "*SQL*" # return services with SQL in the DisplayName


#####################################################################
#
# Method Example
#
#####################################################################

$SQLSrvc = Get-Service -ComputerName "SQL2019-01" -Name "MSSQLSERVER" # Example of variable in PowerShell. $SQLSrvc is the name and will be instanciate once the command is executed.   

$SQLSrvc | GM # GM is an alias for Get-Member command.  

$SQLSrvc.Stop() # This is how you invoke a method named Stop(). Executing this command will stop the SQL service in the $SQLSrvc object.
$SQLSrvc.Start() #  Executing this command will stop the SQL service in the $SQLSrvc object.

# Property Example

$SQLSrvc.DisplayName # This is an example how to display a single property.

$SQLSrvc | select DisplayName, ServiceName, Status # This is an example how to display multiple properties.

$SQLSrvc | Format-List

#####################################################################
#
# How to handle credential
#
#####################################################################

# Assign user sa to a variable called $username
$username =  "sa" 

# Example how to prompt user for an input and assign the value to $pwd variable as a secure string.
$pwd = Read-Host "Please enter password for $username" -assecurestring 

# Creating new PSCredential object by passing username and pwd 
$cred = New-Object System.Management.Automation.PSCredential $username, $pwd



#####################################################################
#
# Find SQL Instance
#
#####################################################################


# Using SqlServer Module 
# Return all cmdlets with instance in their name
get-command -Module sqlserver | ? name -Like "*instance*" 

# If a SQL instance found, it will connect to SQL2019-01 with the credential and return info on SQL Instance 
Get-SqlInstance -ServerInstance SQL2019-01 -Credential $cred 

# Return the databases name, recovery model and compat level from the SQL instance
Get-SqlInstance -ServerInstance SQL2019-01 -Credential $cred | Get-Sqldatabase | Select-Object Name, RecoveryModel, CompatibilityLevel 


# Using DBAtools Module
# Return all cmdlets with instance in their name
get-command -Module dbatools | ? name -Like "*instance*"

# Check computer for any SQL installation
Find-DbaInstance -ComputerName "SQL2019-01"

# Return the databases name, recovery model and compat level from the SQL instance
Find-DbaInstance -ComputerName "SQL2019-01" | Get-DbaDatabase | Select-Object Name, RecoveryModel, CompatibilityLevel 

# Return SQL instance properties with more details
Get-DbaInstanceProperty -SqlInstance "SQL2019-01"

# Finding SQL instance on multiple servers 

$Comp = get-content C:\backups\vmlist.txt # Get a list of computers from a text file
    # OR  
$Comp = @('SQL2019-01', 'SQL2019-02') # Example of an Array.

<# 
    Using a foreach loop to go through the objects in $Comp. 
    Recommended way to write in a script for readability and debugging purposes.
#>
Foreach($computer in $Machine){ 
    Find-DbaInstance -ComputerName $computer 
}

# OR 

# Short-hand using alias is good for adhoc, command-line type execution.
@('SQL2019-01', 'SQL2019-02') | % { Find-DbaInstance -ComputerName $_}



#####################################################################
#
# Backups
#
#####################################################################

<#
    Using SQL Server Module 
#>

# Return all cmdlets with backup in their name
get-command -Module SqlServer | ? name -Like "*backup*"

# Get backup history 
Get-SqlBackupHistory -ServerInstance "SQL2019-01" -Since Midnight -verbose

# Performing backup/restore 
Backup-SqlDatabase -ServerInstance "SQL2019-01" -Database "AdventureWorksLT2019" -BackupAction Database -BackupFile "C:\backups\AdventureWorksLT2019_copy_to_sql2019-02.bak" -CopyOnly -CompressionOption On -

Restore-SqlDatabase -ServerInstance "SQL2019-02" -Database "AdventureWorksLT2019" -BackupFile "C:\backups\AdventureWorksLT2019_copy_to_sql2019-02.bak" -AutoRelocateFile -Credential $cred -Verbose


<#
    Using DBAtools Module 
#>

# Return all cmdlets with backup in their name
get-command -Module DBATools | ? name -Like "*backup*"

# Get last db backup info  
Get-DbaLastBackup -SqlInstance "SQL2019-01" | format-table -AutoSize

Get-DbaLastBackup -SqlInstance "SQL2019-01" -ExcludeDatabase ("master","model","msdb") | format-table -AutoSize

# Performing backup/restore 
$db = "AdventureWorksLT2019"
$bkpfile = "C:\backups\AdventureWorksLT2019_copy_to_sql2019-02.bak"

Backup-DbaDatabase -SqlInstance "SQL2019-01" -Database $db -Path $bkpfile -CopyOnly -CompressBackup -Verify

Restore-DbaDatabase -SqlInstance "sql2019-02" -DatabaseName $db -Path $bkpfile -UseDestinationDefaultDirectories

    # OR you can use the Copy-DbaDatabase

Copy-DbaDatabase -Source "SQL2019-01" -SourceSqlCredential $cred -Database "AdventureWorksLT2019" -Destination "SQL2019-01" -DestinationSqlCredential $cred -UseLastBackup

#####################################################################
#
# SQL Agent Jobs
#
#####################################################################

# Return all cmdlets with backup in their name
get-command -Module DBATools | ? name -Like "*job*"

# Return all failed job since midnight 
Get-SqlAgentJobHistory -ServerInstance sql2019-01 -Since Midnight -OutcomesType Failed     

Get-SqlAgentJobHistory -ServerInstance sql2019-01 -Since Midnight -OutcomesType Failed | where StepName -ne "(Job outcome)" | FL

#####################################################################
#
# Working with Logins and DB Users
#
#####################################################################

# Using SqlServer Module
# Return all cmdlets with login in their name
get-command -Module SqlServer | ? name -Like "*login*"

# Creating new SQL login
Add-SqlLogin -ServerInstance "SQL2019-01" -LoginName "milo" -LoginType SqlLogin -DefaultDatabase "AdventureWorksLT2019" -Enable

# Adding new login to Sysadmin Role
$login = Get-SqlLogin -ServerInstance "SQL2019-01" -LoginName "milo" 

$login | gm # Check available methods/properties of the object returned by Get-SqlLogin

$login.AddToRole("Sysadmin");

# DBAtools module
# Return all cmdlets with login in their name
get-command -Module DBAtools | ? name -Like "*login*"

# Creating new SQL login & assign sysadmin role to the login
New-DbaLogin -SqlInstance "SQL2019-01" -Login "Milo2" -enable -DefaultDatabase master | Set-DbaLogin -AddRole sysadmin -Enable

# Checking roles assigned to a login
(Get-DbaLogin -SqlInstance "sql2019-01" -Login "Milo2").listmembers() 

# Create user in DB for login Milo2
New-DbaDbUser -SqlInstance "SQL2019-01" -Database "AdventureWorksLT2019" -login "Milo2" -Username "Milo2" 

# How do we assign roles in the database for the new user
$user = Get-DbaDbUser -SqlInstance "SQL2019-01" -Database "AdventureWorksLT2019" | ? Name -EQ "Milo2"

$user | gm # find method to allow us to assign roles to db user

# Adding user to db_datareader role 
$user.AddToRole("db_datareader"); 

# Verify user role
$user.IsMember("db_datareader") 
$user.IsMember("db_datawriter") 


#####################################################################
#
# Sending mail
#
#####################################################################
$smtp = "smtp.yourmailserver.com"
$emailcred = "Mailservercredential"
$To = "destination email"
$From = "source email"
$Body = "This is a test email from powershell."
$Subject = "Test email"

Send-MailMessage -To $To -From $From -Subject $Subject -Body $Body -SmtpServer $smtp -Credential $emailcred


