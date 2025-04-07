<#

 Robocopy Auto Backup  (*The  best one)

 Description:
   This script monitors a set of folders defined in the backup
   configuration and synchronizes them to corresponding destination
   folders using Robocopy. It supports filters, and can optionally
   work in mirror mode (deleting files not in the source) if desired.
   
   -----------------------------------------------------------------------------------------------------------
   Recommend scheduling with Task Scheduler to automatically run in the background on login.    Example:
   
	Start a program:    powershell.exe

	Add arguments:     -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\Scripts\Auto_Backup.ps1"

	Start in:           D:\Scripts
	----------------------------------------------------------------------------------------------------------

 Global Flags:
   $debugEnabled     - Enables/disables verbose debug output.
   $throttleInterval - Time in seconds to wait between sync operations.

 Pair Flags:
   Filters			 - Folder names to always exclude from copy operations (at any depth)
   Mirror            - Enables/disables /MIR (mirrored syncing vs. additive syncing)
   Junctions		 - Enables/disables copying junctions (i.e Documents --> Pictures)

#>

# ========================
# Global Settings
# ========================
$host.UI.RawUI.WindowTitle = "Robocopy Auto Backup"
$debugEnabled     = $true    # Set to $false to disable detailed debug output.
$throttleInterval = 10       # Throttle interval in seconds between sync operations.

# ========================
# Folder Backup Config
# ========================
$backupPairs = @(
    @{ 
        Source      = "C:\Program Files (x86)\Steam\steamapps\common\SourceFilmmaker\game"; 
        Destination = "B:\SourceFilmmaker\game";
        Filters     = @("blackmesa", "csgo", "hl2", "left4dead", "tf", "tf_movies");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "D:\+3D WORK"; 
        Destination = "B:\+3D WORK"; 
        Filters     = @("");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "D:\+DESKTOP WORK"; 
        Destination = "B:\+DESKTOP WORK"; 
        Filters     = @("");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "D:\Emulator Files"; 
        Destination = "B:\Emulator Files"; 
        Filters     = @("");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "D:\Game Settings"; 
        Destination = "B:\Game Settings"; 
        Filters     = @("");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "D:\Important Stuff"; 
        Destination = "B:\Important Stuff"; 
        Filters     = @("Cinema");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "D:\Minecraft Servers"; 
        Destination = "B:\Minecraft Servers"; 
        Filters     = @("");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "D:\TF2 Server"; 
        Destination = "B:\TF2 Server"; 
        Filters     = @("");
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "C:\Users\Matt\Pictures"; 
        Destination = "B:\Matt\Pictures"; 
        Filters     = @(); 
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "C:\Users\Matt\Documents"; 
        Destination = "B:\Matt\Documents"; 
        Filters     = @(); 
        Mirror      = $false;
        Junctions   = $false
    },
    @{ 
        Source      = "C:\Users\Matt\Desktop"; 
        Destination = "B:\Matt\Desktop"; 
        Filters     = @(); 
        Mirror      = $false;
        Junctions   = $false
    }
)

# ========================
# Core Backup Mechanism
# ========================
$watchers = @()
$lastRuns = @{}

foreach ($pair in $backupPairs) {
    $src     = $pair.Source
    $dst     = $pair.Destination
    $filters = $pair.Filters
    $mirror  = $pair.Mirror
    $junctions = $pair.Junctions

    # Ensure the destination directory exists.
    if (!(Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst | Out-Null
    }
    
    # Create a FileSystemWatcher for the specified Source.
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $src
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    # Initialize the throttling timestamp for this configured source.
    $lastRuns[$src] = Get-Date

    # Create a script block with closure to capture the current pair's values.
    $action = {
        param($source, $eventArgs)
        $now = Get-Date
        $timestamp = $now.ToString("yyyy-MM-dd HH:mm:ss")
        
        # Retrieve the captured values from MessageData.
        $watcherPath = $event.MessageData.WatcherPath
        $destination = $event.MessageData.Destination
        $filters = $event.MessageData.Filters
        $mirror = $event.MessageData.Mirror
        $junctions = $event.MessageData.Junctions
        
        # Log event info for debugging.
        $eventType = $eventArgs.ChangeType
        $changedPath = $eventArgs.FullPath
        Write-Host "+++ EVENT DETECTED +++" -ForegroundColor Green
        Write-Host "Time        : $timestamp" -ForegroundColor Cyan
        Write-Host "Event Type  : $eventType" -ForegroundColor Cyan
        Write-Host "Changed Path: $changedPath" -ForegroundColor Cyan
        Write-Host "Watching    : $watcherPath" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor Cyan
        
        if (($now - $lastRuns[$watcherPath]).TotalSeconds -gt $throttleInterval) {
            $lastRuns[$watcherPath] = $now
            $modeDesc = if ($mirror) { "Mirror Mode (deletions synced)" } else { "Additive Mode (deletions ignored)" }
            $robocopyMode = if ($mirror) { "/MIR" } else { "/E" }
            
            # Determine junction handling: If Junctions is $false, add /XJD /XJF; if $true, allow junctions (i.e., do nothing).
			$junctionParam = ""
			if (-not $junctions) {
				$junctionParam = " /XJD /XJF"
			}
			# Always exclude the Recycle Bin
			$recycleExclusion = " /XD `"$watcherPath\`$Recycle.Bin`""
            # Build list of excluded subfolders based on the configured filters.
            $excludePaths = @()
            foreach ($filter in $filters) {
                if ($filter -ne "") {
                    $excludePaths += Get-ChildItem -Path $watcherPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -ieq $filter } |
                        Select-Object -ExpandProperty FullName
                }
            }
            $xdParams = ""
            foreach ($path in $excludePaths) {
                $xdParams += " /XD `"$path`""
            }
            
            $cmd = "robocopy `"$watcherPath`" `"$destination`" $robocopyMode /R:1 /W:1 /NFL /NDL /NP /LOG:NUL$xdParams$junctionParam$recycleExclusion"
            Write-Host "DEBUG: Running command: $cmd" -ForegroundColor Green
            Start-Process -WindowStyle Hidden -FilePath "cmd.exe" -ArgumentList "/c $cmd"
            
            Write-Host "------------------------------------------------------------"
            Write-Host "SYNC TRIGGERED   : $timestamp"
            Write-Host "SOURCE           : $watcherPath"
            Write-Host "DESTINATION      : $destination"
            if ($filters.Count -gt 0) {
                Write-Host "EXCLUDED FOLDERS : $($filters -join ', ')"
            }
            else {
                Write-Host "EXCLUDED FOLDERS : None"
            }
            Write-Host "MODE             : $modeDesc"
            Write-Host "COMMAND RUN      : $cmd"
            Write-Host "------------------------------------------------------------`n"
        }
    }.GetNewClosure()  # This captures the current variable values.
    
    # Store the pair's values in the event's MessageData.
    $messageData = @{
        WatcherPath = $src
        Destination = $dst
        Filters     = $filters
        Mirror      = $mirror
        Junctions   = $junctions
    }
    
    # Register events with the proper context.
    Register-ObjectEvent $watcher -EventName Changed -Action $action -MessageData $messageData -SourceIdentifier "$src-Changed" | Out-Null
    Register-ObjectEvent $watcher -EventName Created -Action $action -MessageData $messageData -SourceIdentifier "$src-Created" | Out-Null
    Register-ObjectEvent $watcher -EventName Deleted -Action $action -MessageData $messageData -SourceIdentifier "$src-Deleted" | Out-Null
    Register-ObjectEvent $watcher -EventName Renamed -Action $action -MessageData $messageData -SourceIdentifier "$src-Renamed" | Out-Null
    
    $watchers += $watcher
    
    Write-Host "------------------------------------------------------------"
    Write-Host "WATCHING SOURCE  : $src"
    Write-Host "DESTINATION      : $dst"
    if ($filters.Count -gt 0) {
        Write-Host "EXCLUDED FOLDERS : $($filters -join ', ')"
    }
    else {
        Write-Host "EXCLUDED FOLDERS : None"
    }
    Write-Host "MODE             : $(if ($mirror) { 'Mirror Mode (deletions synced)' } else { 'Additive Mode (deletions ignored)' })"
    Write-Host "USE JUNCTIONS    : $(if ($junctions) { 'Yes' } else { 'No' })"
    Write-Host "STATUS           : ACTIVE"
    Write-Host "------------------------------------------------------------`n"
}

Write-Host "`nAll folder watchers initialized.`n"

# Cleanup on exit: unregister events and dispose watchers.
Register-EngineEvent PowerShell.Exiting -Action {
    Write-Host "`nCleaning up resources..."
    foreach ($w in $watchers) {
        $w.EnableRaisingEvents = $false
        $w.Dispose()
    }
    Unregister-Event -SourceIdentifier "*"
    Write-Host "Cleanup complete."
} | Out-Null

while ($true) { Start-Sleep 10 }

<#

*Note: Not the best one

>#
