# How to run this powershell script to import a csv file into an MS SQL Server database with a dynamically generated table based on the csv columns
# This generates table column data types based on numeric (int or float), date and string\text

Example uses the supplied csv file located on a Windows machine C drive C:\projects\sql_data folder with the powershell script in the same folder.
Database is called 'kaggle_db' and is located on a local install of SQL Server with the default port 1433

step 1: create a folder called projects
step 2: create a sub-folder called sql_data in projects folder
step 3: copy diabetes_data.csv file to the sql_data sub-folder
step 4: copy import_csv_to_MSSQL.ps1 powershell script to the sql_data folder
step 5: change the parameters for ServerInstance, ServerUserName (SQL Server User Name), ServerPassword (SQL Server User login name password), DatabaseName (target SQL Database)

Example Powershell Terminal statement to execute script:

.\import_csv_to_MSSQL.ps1 -FileName 'C:\projects\sql_data\diabetes_data.csv' -ServerInstance 'localhost,1433' -ServerUsername 'SA' -ServerPassword 'sqlpassword' -DatabaseName 'kaggle_db' -Encoding UTF8