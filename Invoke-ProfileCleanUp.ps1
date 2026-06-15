<#
.SYNOPSIS
    Invoke-ProfileCleanup.ps1

.DESCRIPTION
    Wipes all local user profiles from C:\Users on Friday (shutdown) 
    and Monday (startup), excluding built-in and administrator accounts.

.NOTES
    - Deploy via GPO Shutdown/Startup script
    - Run as SYSTEM
#>

$exclusionProfiles = @(
    "Administrator",
    "Default",
    "Public"
)

$targetProfilePath = "C:\Users"

function Get-ExecutionFlag {
    $currentDay = (Get-Date).DayOfWeek

    if ($currentDay -eq "Friday" -or $currentDay -eq "Monday") {
        Write-Host "[INFO] Execution flag - Eligible (Day: $currentDay)"
        return $true
    }
    else {
        Write-Host "[INFO] Execution flag - Not eligible (Day: $currentDay)"
        return $false
    }
}

function Get-ProfilesToDelete {
    $profiles = Get-ChildItem -Path $targetProfilePath -Directory |
    Where-Object { $exclusionProfiles -notcontains $_.Name }

    return $profiles
}

function Invoke-ProfileWipe {
    $profiles = Get-ProfilesToDelete

    if ($profiles.Count -eq 0) {
        Write-Host "[INFO] No profiles found to delete."
        return
    }

    Write-Host "[INFO] Profiles targeted for deletion: $($profiles.Count)"

    foreach ($profile in $profiles) {
        try {
            Remove-Item -Path $profile.FullName -Recurse -Force
            Write-Host "[SUCCESS] Deleted: $($profile.FullName)"
        }
        catch {
            Write-Host "[ERROR] Failed to delete: $($profile.FullName)"
            Write-Host "[ERROR] Reason: $($_.Exception.Message)"
        }
    }

    Write-Host "[INFO] Profile wipe complete."
}
