# Declare variables
$server = "localhost";
$database = "AdventureWorks2016CTP3";
$mySchema = "dbo"
$matchText = "Employee";  # Definition text to search. Be aware this accepts a regular expression
$replaceText = "EmployeeTest"; # Text to replace $matchText
$alter = $false;     # Set to $false to test by viewing backup/change folders after execution; Set to $true if you want the script to alter database objects
$count = 0;  # foreach loop matching count
$countln = 0; # linecount

# Create backup and change folders if not exists
if(!(Test-Path -path C:\powershell\backup\procs\)) { New-Item C:\powershell\backup\procs\ -type directory }
if(!(Test-Path -path C:\powershell\change\procs\)) { New-Item C:\powershell\change\procs\ -type directory }

$backupFolder = "C:\powershell\backup\";        # Change script folders. Need a \ (back slash) on the end
$changeFolder = "C:\powershell\change\"         # One file per object, backup & change folders

# SMO is a .Net library for working with SQL Server
# http://msdn.microsoft.com/en-us/library/ms162209(v=sql.100).aspx
# Load the SQL Management Objects assembly (Pipe out-null supresses output)
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

# Create our SMO objects
# Once you create a server\instance object, you can then drill down and work with the rest of the server objects
# List SMO namespaces to use | (http://msdn.microsoft.com/en-us/library/ms162233(v=sql.100).aspx)
$srv = New-Object "Microsoft.SqlServer.Management.SMO.Server" $server;
$db = New-Object ("Microsoft.SqlServer.Management.SMO.Database");

# Get the database
$db = $srv.Databases[$database];

# For each stored procedure in the database
foreach($proc in $db.StoredProcedures)
{
# For each matching stored prcoedure
if(($proc.TextBody -match $matchText) -and ($proc.Schema -eq $mySchema))
   {
   $countln++
   Write-Host "$countln - "  $proc.Schema $proc.Name;
   # Backup of the original proc definition
   $proc.Script() | Out-File ($backupFolder + "procs\" + ([string]$srv.name -replace("\\", "_")) + "_" + [string]$db.Name + "_" + [string]$proc.Schema + "_" + [string]$proc.name + "_backup.sql");
   # New procedure definition sql
   $proc.Script() -replace($matchtext, $replaceText) | Out-File ($changeFolder + "procs\" + ([string]$srv.name -replace("\\", "_")) + "_" + [string]$db.Name + "_" + [string]$proc.Schema + "_" + [string]$proc.name + ".sql");
   # If set to true this will change the procedure definition on the server!
   if($alter)
      {
         $proc.TextBody = $proc.TextBody -replace($matchtext, $replaceText);
         $proc.Alter();
         Write-Host "Altered " $proc.Name;
      }
   $count++
   }
}

Write-Host "Finished processing $count matches in $database on $server."