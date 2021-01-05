# SQL-LogFileSizeShrink

This script will check the Log file size. If free file space is less than 20% that mean byond threshold and qualifies for the alert. It sends E-mail by combining all these alerts (example mentioned in o/p) then it will wait For 10 Minutes. After 10 minutes it will take backup first the shrink the log file without manual intervention.

Alert serial number, Server Name, Database Name,  %Free File Space - Free log file space. It will send an email, if scheduled then it is monitoring as well as log file size auto handling technique.

# Prerequisites

SQL Server
SSMS - SQL Server Management Studio

# Note

Set SSMS E-Mail Profile<br>
Alert - Serial number<br>
Server Name - Machine Name<br>
Database Name - Database Name of which log file belong<br>
Free Space (%) - Free Space of the log file in Ratio (%)<br>

# Use

Create profile and script in SSMS then schedule it as per requirement.

# Input
@profile_name = 'LogFileSizeAlert', -- Replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
@recipients = 'example@outlook.com', -- Replace with your email address
@subject = 'Log File Beyond Threshold' ;

# Example O/P
![alt text](https://github.com/Sahista-Patel/SQL-LogFileSizeShrink/blob/Powershell/logfilesize.PNG)


# License
Copyright 2020 Harsh & Sahista

# Contribution
[Harsh Parecha] (https://github.com/TheLastJediCoder)<br>
[Sahista Patel] (https://github.com/Sahista-Patel)<br>
We love contributions, please comment to contribute!

# Code of Conduct
Contributors have adopted the Covenant as its Code of Conduct. Please understand copyright and what actions will not be abided.
