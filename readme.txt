# How to run the script to import a csv file into a dynamically generated table into an MS SQL Server database:

step 1: create a folder called projects on C drive.
step 2: create a sub-folder called sql_data in projects folder
step 3: copy diabetes_data.csv file to the sql_data sub-folder
step 4: copy import_csv_to_MSSQL.ps1 powershell script to the sql_data folder
step 5: change the parameters for ServerInstance, ServerUserName (SQL Server User Name), ServerPassword (SQL Server User login name password), DatabaseName (target SQL Database)

Example Powershell Terminal statement to execute script:

.\import_csv_to_MSSQL.ps1 -FileName 'C:\projects\sql_data\diabetes_data.csv' -ServerInstance 'localhost,1433' -ServerUsername 'SA' -ServerPassword 'sqlpassword' -DatabaseName 'kaggle_db' -Encoding UTF8