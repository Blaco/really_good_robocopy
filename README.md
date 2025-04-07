# really good robocopy auto backup script

###### I couldnt't find a robocopy backup script that supported filters and wasn't bloated with unneccesary functions so I just made my own.
This script monitors a set of folders defined in the backup configuration and synchronizes them to corresponding destination folders using Robocopy. It supports filters, and can optionally work in mirror mode (deleting files not in the source) if desired. That's all it does.
   
# Global Flags

- **`$debugEnabled`**: Enables/disables verbose debug output.
- **`$throttleInterval`**: Time in seconds to wait between sync operations.

# Pair Flags

- **Filters**: Folder names to always exclude from copy operations (at any depth).
- **Mirror**: Enables/disables `/MIR` (mirrored syncing vs. additive syncing).
- **Junctions**: Enables/disables copying junctions `/XJ` (i.e. Documents → Pictures).

# Examples
- Essentially backs up the usermod/workshop folder of Source Filmmaker, skips the game resource files
```
$backupPairs = @(    
    @{         
        Source      = "C:\Program Files (x86)\Steam\steamapps\common\SourceFilmmaker\game";         
        Destination = "B:\SourceFilmmaker\game";         
        Filters     = @("blackmesa", "csgo", "hl2", "left4dead", "tf", "tf_movies");         
        Mirror      = $false;         
        Junctions   = $false    
    },
```
- Maintains an active clone of Documents, Pictures, and Videos, since /MIR and junctions are both enabled
- Skips the "My Games" folder inside Documents (case doesn't matter)
```
    @{         
        Source      = "C:\Users\DanteFromDMC\Documents";         
        Destination = "B:\Clone_of_My_Documents_and_Media";         
        Filters     = @(my games);         
        Mirror      = $true;         
        Junctions   = $true    
    }
)
```


_**Warning:**    Doesn't work if source is set to a drive's root directory, so don't do that._

### Schedule this with Task Scheduler to automatically run in the background on login.   Example:
```
-----------------------------------------------------------------------------------------------------------
Start a program:    powershell.exe

Add arguments:     -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\Scripts\Auto_Backup.ps1"

Start in:           D:\Scripts
----------------------------------------------------------------------------------------------------------
```
