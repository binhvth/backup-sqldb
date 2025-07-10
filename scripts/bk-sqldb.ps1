# Thư mục tạm để lưu file backup
$tmpPath = $PSScriptRoot  #Địa chỉ hiện hành của file

# Đường dẫn tới file data lưu thông tin db, server 
$dataFile = Join-Path -Path $PSScriptRoot -ChildPath "\data.txt"


if (-not (Test-Path $tmpPath)) {
    New-Item -Path $tmpPath -ItemType Directory | Out-Null
}

# Lấy ngày hiện tại định dạng YYYY.MM.DD
$dateStamp = Get-Date -Format "yyyy.MM.dd"

# Đọc từng dòng từ file
Get-Content $dataFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -match "^(.*?),(.*?),(.*?)$") {
        $databaseName = $matches[1]
        $serverName   = $matches[2]
        $netPath      = $matches[3]

        Write-Host "==============================="
        Write-Host "Backup Database: $databaseName"
        Write-Host "Server: $serverName"
        Write-Host "Network Path: $netPath"

        $filePath = Join-Path $tmpPath "$databaseName-$dateStamp.bak"
        Write-Host "Backup File: $filePath"

        # Thực hiện backup
        $backupCommand = "BACKUP DATABASE [$databaseName] TO DISK = N'$filePath' WITH INIT, NAME = N'$databaseName backup', STATS = 10, NOFORMAT"
        sqlcmd -E -S $serverName -d master -Q $backupCommand

        # Copy đến thư mục mạng
        Write-Host "Copying to $netPath..."
        Copy-Item -Path $filePath -Destination $netPath -Force

        # Xoá file backup local
        Remove-Item -Path $filePath -Force

        Write-Host "Hoàn tất cho $databaseName"
    }
    else {
        Write-Warning "Dòng không hợp lệ: $line"
    }
}