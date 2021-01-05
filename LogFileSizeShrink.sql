-- <#
-- .SYNOPSIS
--     This script will check the Log file size. If free file space is less than 20% that mean byond threshold and qualifies for the alert.
--     It sends E-mail by combining all these alerts (example mentioned in o/p) then it will wait For 10 Minutes.
--     After 10 minutes it will take backup first the shrink the log file without manual intervention. Cool!
-- .DESCRIPTION
--     Alert serial number, Server Name, Database Name,  %Free File Space - Free log file space.
--     It will send an email, if scheduled then it is monitoring as well as log file size auto handling technique.
-- .INPUTS
--     Set E-Mail profile in SSMS. Replace it with example one as mentioned in comment. 
--     Please set varibles like recipients E-Mail id and profile as and when guided by comment through code.
-- .EXAMPLE
--     Create script and schedule it as per requirement.
--     This will execute the script and gives HTML content in email with the details in body.
-- .NOTES
--     PUBLIC
-- .AUTHOR
--     Harsh Parecha
--     Sahista Patel
-- #>

DROP TABLE IF EXISTS #Temp;
CREATE TABLE #Temp
(
[ID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
[Server] [varchar] (128) NULL,
[Database1] [varchar] (128) NULL,
[File Name] [sys].[sysname] NOT NULL,
[File Size] [varchar] (53) NULL,
[File Used Space] [varchar] (53) NULL,
[File Free Space] [varchar] (53) NULL,
[% Free File Space] [varchar] (51) NULL,
[Autogrowth] [varchar] (53) NULL
)
 
EXEC sp_MSforeachdb ' USE [?];
INSERT INTO #Temp
SELECT  @@SERVERNAME [Server] ,
        DB_NAME() [Database1] ,
        MF.name [File Name] ,
        CAST(CAST(MF.size / 128.0 AS DECIMAL(15, 2)) AS VARCHAR(50)) + '' MB'' [File Size] ,
        CAST(CONVERT(DECIMAL(10, 2), MF.size / 128.0 - ( ( size / 128.0 ) - CAST(FILEPROPERTY(MF.name, ''SPACEUSED'') AS INT) / 128.0 )) AS VARCHAR(50)) + '' MB'' [File Used Space] ,
        CAST(CONVERT(DECIMAL(10, 2), MF.size / 128.0 - CAST(FILEPROPERTY(MF.name, ''SPACEUSED'') AS INT) / 128.0) AS VARCHAR(50)) + '' MB'' [File Free Space] ,
        CAST(CONVERT(DECIMAL(10, 2), ( ( MF.size / 128.0 - CAST(FILEPROPERTY(MF.name, ''SPACEUSED'') AS INT) / 128.0 ) / ( MF.size / 128.0 ) ) * 100) AS VARCHAR(50)) + ''%'' [% Free File Space] ,
        IIF(MF.growth = 0, ''N/A'', CASE WHEN MF.is_percent_growth = 1 THEN CAST(MF.growth AS VARCHAR(50)) + ''%'' 
                                    ELSE CAST(MF.growth / 128 AS VARCHAR(50)) + '' MB''
                                    END) [Autogrowth]
FROM    sys.database_files MF
        CROSS APPLY sys.dm_os_volume_stats(DB_ID(''?''), MF.file_id) VS
WHERE MF.type = 1 AND DB_NAME() NOT IN ("master", "model", "tempdb", "msdb", "Resource", "ReportServer$MSSQL", "ReportServer$MSSQLTempDB") AND CAST(CONVERT(DECIMAL(10, 2), ( ( MF.size / 128.0 - CAST(FILEPROPERTY(MF.name, ''SPACEUSED'') AS INT) / 128.0 ) / ( MF.size / 128.0 ) ) * 100) AS DECIMAL(50)) < 20
' 
 
-- SELECT * FROM #Temp
DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)
 
SET @xml = CAST(( SELECT [ID] AS 'td','',[Server] AS 'td','', [Database1] AS 'td','',[% Free File Space] AS 'td'
FROM #Temp 
ORDER BY ID 
FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
 
SET @body ='<html><body><H3>LogFile Beyond Threshold</H3>
<table border = 1> 
<tr>
<th> Alert </th> <th> Server Name </th> <th> Database </th> <th> %Free File Space </th></tr>'    
 
SET @body = @body + @xml +'</table></body></html>'
 
EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'LogFileSizeAlert', -- Replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
@recipients = 'example@outlook.com', -- Replace with your email address
@subject = 'Log File Beyond Threshold' ;
 
-- SELECT GETDATE() CurrentTime
WAITFOR DELAY '00:10:00'; -- Delay set as per requirement. 
-- SELECT GETDATE() CurrentTime
 
DECLARE @counter INT = 1;
DECLARE @Database1 VARCHAR(128);
DECLARE @Path VARCHAR(max);
DECLARE @Name VARCHAR(max);
 
WHILE @counter <= (SELECT MAX(ID) FROM #Temp)
BEGIN
    SET @Path = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQL\MSSQL\Backup\'; -- Set Path where backup should be placed.
    SET @Database1 = (SELECT Database1 FROM #Temp where ID = @counter)
    SET @Path += @Database1;
    SET @Path += '_LogBackup_';
    SET @Path += (SELECT REPLACE(CONVERT(CHAR(19),GETDATE(), 20), ':', '-'));
    SET @Path += '.bak'
    SET @Name = @Database1;
    SET @Name += ' -Full Database Backup';
    BEGIN TRY
        BACKUP DATABASE @Database1 TO  
        DISK = @Path 
        WITH NOFORMAT, NOINIT,  NAME = @Name , SKIP, NOREWIND, NOUNLOAD,  STATS = 10
    END TRY
    BEGIN CATCH
        DELETE FROM #Temp WHERE [Database1] = @Database1
    END CATCH
    SET @counter = @counter + 1;
    SET @Name = NULL;
 
END
-- SELECT * FROM #Temp
WHILE @counter <= (SELECT MAX(ID) FROM #Temp)
BEGIN
    SET @Name = (SELECT [File Name] FROM #Temp where ID = @counter)
    DBCC SHRINKFILE (@Name , 0, TRUNCATEONLY)
    SET @Name = NULL;
 
END
