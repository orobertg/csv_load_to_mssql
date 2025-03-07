# csv_load_to_mssql

## Load a CSV data file into MS SQL Server with a Powershell script
Load a csv data file into an MS SQL Server database with a dynamically generated table based on the csv header columns and data values using a powershell script. This script generates the table and table column structure using data types numeric (int or float), date and string\text found in the csv file.

## How to run this Powershell script
Example below uses the supplied csv file using a Windows machine C drive C:\projects\sql_data folder with the Powershell script in the same folder. Database is called 'kaggle_db' and is located on a local install of SQL Server with the default port 1433

* step 1: create a folder called projects
* step 2: create a sub-folder called sql_data in projects folder
* step 3: copy diabetes_data.csv file to the sql_data sub-folder
* step 4: copy import_csv_to_MSSQL.ps1 Powershell script to the sql_data folder
* step 5: change the parameters for ServerInstance, ServerUserName (SQL Server User Name), ServerPassword (SQL Server User login name password), DatabaseName (target SQL Database)

## Example 

Powershell Terminal statement to execute script:

```sql
.\import_csv_to_MSSQL.ps1 -FileName 'C:\projects\sql_data\diabetes_data.csv' -ServerInstance 'localhost,1433' -ServerUsername 'SA' -ServerPassword 'sqlpassword' -DatabaseName 'kaggle_db' -Encoding UTF8
```

## Requirements

* SQL Server that accepts SQL Login Authenticated connections 
* SQL Server user login with previleges to write and create tables in your database
* Priveleges to run Powershell scripts on your machine/server

## About

Looking for a portable way to streamline loading csv data files into an MS SQL Database without having to use MS SQL's Import Data files GUI or bulkinsert statements in a SQL script, and instead leverage Powershell in a Windows Server environment where other custom tools may not be loaded.