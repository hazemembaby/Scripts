# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
param(
    [ValidateScript({
            if (-Not ($_ | Test-Path)) {
                throw "The specified folder location $ExportPath is not existing, please re-run the script and ensure to enter a valid path or leave the ExportPath unassigned"
            }
            return $true
        })]
    [Parameter(Mandatory = $false)]
    [String]$ExportPath = $PWD.Path,
    [Parameter(Mandatory = $true)]
    [String]$PublicFolder,
    [Parameter(Mandatory = $false)]
    [String]$AffectedUser)

$Script:ReportName = "CheckMePfREPORT.txt"
$ts = Get-Date -Format yyyyMMdd_HHmmss
$Script:Path = $ExportPath +"\CheckEXOMePf\CheckEXOMePf_$ts"
New-Item $Script:Path -Force -ItemType Directory | Out-Null
New-Item $Script:Path\CheckMePfREPORT.txt -Force -ItemType File | Out-Null
New-Item $Script:Path\CheckMePfREPORTChecksLogging.csv -Force -ItemType File | Out-Null

#Requires -Modules @{ModuleName="ExchangeOnlineManagement"; ModuleVersion="3.0.0" }
function LogError {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentStatus,

        [Parameter(Mandatory = $true)]
        [string]$Function,

        [Parameter(Mandatory = $true)]
        [string]$CurrentDescription

    )
    [PSCustomObject]@{
        Function    = $Function
        Description = $CurrentDescription
        Status      = $CurrentStatus
    } | Export-Csv $Script:Path\CheckMePfREPORTChecksLogging.csv -NoTypeInformation -Append
}

function WriteToScreenAndLog {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Issue,

        [Parameter(Mandatory = $true)]
        [String]$Fix
    )
    Write-Host $Issue -ForegroundColor Red
    $Issue | Out-File $Script:Path\$Script:ReportName -Append
    Write-Host $Fix -ForegroundColor Green
    $Fix+"`n" | Out-File $Script:Path\$Script:ReportName -Append
    Write-Host
}

function Connect2EXO {
    try {

        Write-Host "Connecting to EXO, please enter Global administrator credentials when prompted!" -ForegroundColor Yellow
        Connect-ExchangeOnline -ErrorAction Stop
        $CurrentDescription= "Connecting to EXO"
        $CurrentStatus = "Success"
        LogError -CurrentStatus $CurrentStatus -Function "Connecting to EXO" -CurrentDescription $CurrentDescription
        Write-Host "Connected to EXO successfully" -ForegroundColor Cyan
    } catch {
        #$ErrorEncountered=$Global:error[0].Exception
        $CurrentDescription = "Connecting to EXO"
        $CurrentStatus = "Failure"
        LogError -CurrentStatus $CurrentStatus -Function "Connecting to EXO" -CurrentDescription $CurrentDescription
        Write-Host "Error encountered during executing the script!"-ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
        Write-Host "`nOutput was exported in the following location: $Script:Path" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        break
    }
}
function QuitEXOSession {
    if ($null -eq $SessionCheck) {
        try {
            Write-Host "Quitting EXO PowerShell session..." -ForegroundColor Yellow
            Disconnect-ExchangeOnline -ErrorAction Stop -Confirm:$false
            $CurrentDescription= "Disconnecting from EXO"
            $CurrentStatus = "Success"
            LogError -CurrentStatus $CurrentStatus -Function "Disconnecting from EXO" -CurrentDescription $CurrentDescription
            Write-Host "`nOutput was exported in the following location: $Script:Path" -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            break
        } catch {
            #$ErrorEncountered=$Global:error[0].Exception
            $CurrentDescription = "Disconnecting from EXO"
            $CurrentStatus = "Failure"
            LogError -CurrentStatus $CurrentStatus -Function "Disconnecting from EXO" -CurrentDescription $CurrentDescription
            Write-Host "Error encountered during executing the script!"-ForegroundColor Red
            Write-Host $_ -ForegroundColor Red
            Write-Host "`nOutput was exported in the following location: $Script:Path" -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            break
        }
    }
}
function AskForFeedback {
    Write-Host "Please rate the script experience & tell us what you liked or what we can do better over https://aka.ms/MePfHealthFeedback" -ForegroundColor Cyan
    "Please rate the script experience & tell us what you liked or what we can do better over https://aka.ms/MePfHealthFeedback" | Out-File $Script:Path\$Script:ReportName -Append
}
