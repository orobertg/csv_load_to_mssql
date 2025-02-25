[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FileName,  # Full path to the CSV file
    [Parameter(Mandatory = $false)]
    [string]$ServerInstance = "YourServerInstance",  # e.g., "localhost\SQLEXPRESS"
    [Parameter(Mandatory = $false)]
	[string]$ServerUsername = "YourServerUsername",  # e.g., "SA"
    [Parameter(Mandatory = $false)]
	[string]$ServerPassword = "YourServerPassword",  # e.g., "SAPassWord"
    [Parameter(Mandatory = $false)]
    [string]$DatabaseName = "YourDatabaseName",      # Target database name
    [Parameter(Mandatory = $false)]
    [string]$Encoding = "Default"                    # Optionally specify an encoding (e.g., UTF8)
)

# Check if Invoke-Sqlcmd is available
if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Host "The 'Invoke-Sqlcmd' cmdlet is not available. The SqlServer module is required."
    $response = Read-Host "Do you want to install the SqlServer module? (Y/N)"
    if ($response -eq 'Y') {
        try {
            Write-Host "Installing the SqlServer module..."
            Install-Module -Name SqlServer -Scope CurrentUser -Force
            Import-Module SqlServer -ErrorAction Stop
            Write-Host "The SqlServer module has been installed and imported successfully."
        }
        catch {
            Write-Error "Installation failed: $_"
            exit 1
        }
    }
    else {
        Write-Error "The SqlServer module is required to run this script. Exiting."
        exit 1
    }
}

# Now you can safely use Invoke-Sqlcmd in your script.
Invoke-Sqlcmd -Query "SELECT GETDATE();" -ServerInstance $ServerInstance -Username $ServerUsername -Password $ServerPassword -Database $DatabaseName -TrustServerCertificate

# Check if a table with the same name already exists in the database
$checkTableQuery = @"
SELECT COUNT(*) AS TableCount 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'dbo' 
  AND TABLE_NAME = '$tableName';
"@

$tableCheckResult = Invoke-Sqlcmd -Query $checkTableQuery -ServerInstance $ServerInstance -Username $ServerUsername -Password $ServerPassword -Database $DatabaseName -TrustServerCertificate

if ($tableCheckResult.TableCount -gt 0) {
    Write-Error "A table named '$tableName' already exists in the database '$DatabaseName'. Exiting."
    exit
}

# Ensure the CSV file exists
if (-not (Test-Path $FileName)) {
    Write-Error "File '$FileName' does not exist. Exiting."
    exit
}

$csvPath = $FileName

# Automatically generate the table name from the CSV file name (without extension).
$tableName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)

# Import the CSV file. Use encoding if specified.
if ($Encoding -ne "Default") {
    $csvData = Import-Csv -Path $csvPath -Encoding $Encoding
}
else {
    $csvData = Import-Csv -Path $csvPath
}

if ($csvData.Count -eq 0) {
    Write-Error "CSV file is empty or no data could be parsed. Exiting."
    exit
}

# Use the provided file name for the CSV path.
$csvPath = $FileName

# Automatically generate the table name from the CSV file name (without extension).
$tableName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)

# Read the CSV file
$csvData = Import-Csv -Path $csvPath
if ($csvData.Count -eq 0) {
    Write-Error "CSV file is empty. Exiting."
    exit
}

# Get headers from the CSV (assumes the CSV has a header row)
$headers = $csvData[0].PSObject.Properties.Name

# Create a hashtable to store SQL type for each column and maximum length for NVARCHAR columns.
$colTypeMapping = @{}
$colMaxLengths = @{}

# Loop through each header to determine the best SQL data type.
foreach ($header in $headers) {
    $maxLength = 0
    $isDate = $true
    $isNumeric = $true
    $isInteger = $true
    $foundValue = $false

    foreach ($row in $csvData) {
        $value = $row.$header
		
        if (![string]::IsNullOrEmpty($value)) {
            $foundValue = $true
            $svalue = $value.ToString().Trim()
            if ($svalue.Length -gt $maxLength) { 
                $maxLength = $svalue.Length 
            }
            # Test if the value can be interpreted as a date.
            # $parsedDate = $null
			[datetime]$parsedDate = [datetime]::MinValue  # Initialize the variable
            if (-not [datetime]::TryParse([string]$svalue, [ref]$parsedDate)) {
                $isDate = $false
            }
            # Test if the value can be interpreted as a number.
            $parsedDouble = 0.0
            if (-not [double]::TryParse([string]$svalue, [ref]$parsedDouble)) {
                $isNumeric = $false
            }
            else {
                # If it is numeric, check if it is an integer.
                if ($parsedDouble -ne [math]::Floor($parsedDouble)) {
                    $isInteger = $false
                }
            }
        }
    }

    # If no non-empty values found, default maxLength to 50.
    if (-not $foundValue) { 
        $maxLength = 50 
    }

    # Decide on the SQL datatype:
    if ($foundValue -and $isDate) {
        $sqlType = "DATETIME"
    }
    elseif ($foundValue -and $isNumeric) {
        if ($isInteger) {
            $sqlType = "INT"
        }
        else {
            $sqlType = "FLOAT"
        }
    }
    else {
        # Use NVARCHAR for text data. If the maximum length is over 4000, then use NVARCHAR(MAX).
        if ($maxLength -gt 4000) {
            $sqlType = "NVARCHAR(MAX)"
        }
        else {
            $sqlType = "NVARCHAR($maxLength)"
        }
    }
    $colTypeMapping[$header] = $sqlType
    $colMaxLengths[$header] = $maxLength
}

# Build the CREATE TABLE SQL statement dynamically.
$tableSQL = "CREATE TABLE [$tableName] ("
foreach ($header in $headers) {
    $dataType = $colTypeMapping[$header]
    $tableSQL += "`n    [$header] $dataType,"
}
# Remove trailing comma and finish statement.
$tableSQL = $tableSQL.TrimEnd(",") + "`n);"

Write-Output "Creating table with SQL:"
Write-Output $tableSQL

# Execute the SQL command to create the table.
Invoke-Sqlcmd -Query $tableSQL -ServerInstance $ServerInstance -Username $ServerUsername -Password $ServerPassword -Database $DatabaseName -TrustServerCertificate

# Build a mapping for DataTable .NET types based on SQL type.
$colDataTypeMapping = @{}
foreach ($header in $headers) {
    $sqlType = $colTypeMapping[$header]
    if ($sqlType -eq "DATETIME") {
        $colDataTypeMapping[$header] = [datetime]
    }
    elseif ($sqlType -eq "INT") {
        $colDataTypeMapping[$header] = [int]
    }
    elseif ($sqlType -eq "FLOAT") {
        $colDataTypeMapping[$header] = [double]
    }
    else {
        # For NVARCHAR, we use string.
        $colDataTypeMapping[$header] = [string]
    }
}

# Create a DataTable with columns using the determined .NET types.
$dt = New-Object System.Data.DataTable
foreach ($header in $headers) {
    $colType = $colDataTypeMapping[$header]
    $col = New-Object System.Data.DataColumn($header, $colType)
    $dt.Columns.Add($col) | Out-Null
}

# Populate the DataTable with CSV rows, converting to the appropriate types.
foreach ($row in $csvData) {
    $dr = $dt.NewRow()
    foreach ($header in $headers) {
        $value = $row.$header
        if ([string]::IsNullOrEmpty($value)) {
            $dr[$header] = $null
        }
        else {
            $svalue = $value.ToString().Trim()
            $targetType = $colDataTypeMapping[$header]
            try {
                if ($targetType -eq [datetime]) {
                    $dr[$header] = [datetime]::Parse($svalue)
                }
                elseif ($targetType -eq [int]) {
                    $dr[$header] = [int]::Parse($svalue)
                }
                elseif ($targetType -eq [double]) {
                    $dr[$header] = [double]::Parse($svalue)
                }
                else {
                    $dr[$header] = $svalue
                }
            }
            catch {
                # If conversion fails, fallback to the raw string value.
                $dr[$header] = $svalue
            }
        }
    }
    $dt.Rows.Add($dr)
}

# Use SqlBulkCopy to import the DataTable into the SQL Server table.
$connectionString = "Server=$ServerInstance;Database=$DatabaseName;User ID=$ServerUsername;Password=$ServerPassword;Integrated Security=False;"
$bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString)
$bulkCopy.DestinationTableName = $tableName


try {
    $bulkCopy.WriteToServer($dt)
    Write-Output "Data imported successfully into table [$tableName]."
}
catch {
    Write-Error "Error during bulk copy: $_"
}
