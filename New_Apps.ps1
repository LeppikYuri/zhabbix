# Указываем имя журнала, куда Sysmon записывает события
$logName = "Microsoft-Windows-Sysmon/Operational"

# Задаем временной диапазон: последние 2 минуты
$startTime = (Get-Date).AddMinutes(-2)  # Время начала (2 минуты назад)
$endTime = Get-Date                     # Текущее время

# Получаем события из журнала за последние 2 минуты
$events = Get-WinEvent -LogName $logName -FilterXPath "*[System[TimeCreated[@SystemTime >= '$($startTime.ToUniversalTime().ToString("o"))' and @SystemTime <= '$($endTime.ToUniversalTime().ToString("o"))']]]" | Where-Object { $_.Id -eq 12 }

# Фильтруем события, чтобы найти только те, которые связаны с разделом Uninstall
$uninstallEvents = $events | ForEach-Object {
    $eventXml = ([xml]$_.ToXml()).Event.EventData.Data
    $targetObject = ($eventXml | Where-Object { $_.Name -eq "TargetObject" }).'#text'
    $details = ($eventXml | Where-Object { $_.Name -eq "Details" }).'#text'
    $processName = ($eventXml | Where-Object { $_.Name -eq "ProcessName" }).'#text'
    $eventType = ($eventXml | Where-Object { $_.Name -eq "EventType" }).'#text'

    # Проверяем, относится ли событие к разделу Uninstall
    if ($targetObject -match "\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\") {
        [PSCustomObject]@{
            TimeCreated   = $_.TimeCreated
            EventType     = $eventType
            TargetObject  = $targetObject
            Details       = $details
            ProcessName   = $processName
        }
    }
}

# Выводим результаты
if ($uninstallEvents) {
    $uninstallEvents | Format-Table -AutoSize
} else {
    Write-Host "Событий Uninstall за последние 2 минуты не обнаружено."
}
