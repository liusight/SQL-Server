#import SQL Server module
Import-Module SQLPS -DisableNameChecking
##              and   isnull(last_notification,'1/1/2015') < dateadd(minute, - notification_age, getdate())


$query = @"
            SELECT  server_monitoring_id, connect_data, notification_age, last_notification
              FROM [insightDB].[dbo].[server_monitoring]
              where db_type = 'S'
              and   active='Y'
              and   DBInstanceMonitor = 'Y'




"@



$instanceMonitoringInfo = Invoke-Sqlcmd -ServerInstance "DBInstance007" -Database "insightDB" -Query $query -querytimeout 600 -connectiontimeout 60



$result = @()



$instanceMonitoringInfo |
ForEach-Object {



  $InstanceInfo = $_



#capture info you want to capture
   $item = [PSCustomObject] @{
     ServerMonitoringID = $InstanceInfo[0]
     InstanceName       = $InstanceInfo[1]
     notification_age   = $InstanceInfo[2]
     last_notification  = $InstanceInfo[3]
   }
   #create a new "row" and add to the results array
   $result += $item
}



$anonUsername = "anonymous"
$anonPassword = ConvertTo-SecureString -String "anonymous" -AsPlainText -Force
$anonCredentials = New-Object System.Management.Automation.PSCredential($anonUsername,$anonPassword)



$body = "The following server(s) Failed: `r`r"
$send_email = 0



$result |
ForEach-Object {



  try {
      $current = $_.InstanceName
      $currentID = $_.ServerMonitoringID
      
      "ping: $current"
       $result = Invoke-Sqlcmd -ServerInstance $_.InstanceName -Database "Master" -Query "Select getdate()" -ErrorAction SilentlyContinue -querytimeout 600 -connectiontimeout 60
    } catch {
       $send_email = 1
       "Failed: $current ID: $currentID"
       $body = "$body $current`r"
       $update_query = "update [insightDB].[dbo].[server_monitoring] set last_notification = getdate() where server_monitoring_id = $currentID"
       Invoke-Sqlcmd -ServerInstance "DBInstance007" -Database "insightDB" -Query $update_query -ErrorAction SilentlyContinue -querytimeout 600 -connectiontimeout 60
       Write-EventLog -LogName Application -Source 'SQLHealthCheck' -EventID 666 -EntryType Warning -Message "Healthcheck failed $current" -Category 1 -RawData 10,20
    }
}



if ($send_email -eq 1) {
    Send-MailMessage -From "DBInstance007_@liusight.com" -To "support@liusight.com;jane.doe@liusight.com".Split(';') -Subject "Powershell DB Instance Monitor - Server Failed" -Body $body -Priority High -SmtpServer "relay.liusight.com" -credential $anonCredentials
}








USE InsightDB
GO

/****** Object:  Table [dbo].[server_monitoring]    Script Date: 6/21/2024 11:19:00 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[server_monitoring](
	[server_monitoring_id] [int] NOT NULL,
	[server_name] [varchar](100) NOT NULL,
	[instance_name] [varchar](100) NULL,
	[connect_data] [varchar](300) NOT NULL,
	[db_type] [char](1) NOT NULL,
	[active] [char](1) NOT NULL,
	[created_on] [datetime] NOT NULL,
	[notification_age] [int] NULL,
	[last_notification] [datetime] NULL,
	[DBInstanceMonitor] [char](1) NULL,
	[All_DB_Info] [char](1) NULL,
	[Notes] [varchar](255) NULL,
 CONSTRAINT [PK_server_monitoring1] PRIMARY KEY CLUSTERED 
(
	[server_monitoring_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


