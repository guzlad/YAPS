$ErrorActionPreference = "Stop"

# Palworld server script for Windows
# Requirements: SteamCMD and a valid PalServer install.
# Guide: Edit the .ps1 file to set your SteamCMD ($SteamCMDPath) and PalServer ($PalServerPath) location, this is required. Everything else is optional
# Troubleshooting: If you are getting an error about being unable to run the script, open Powershell in your start menu as admin and run "Set-ExecutionPolicy RemoteSigned", then try again.
#                  If you encounter any crashes contact @gooseman0 on discord with the error message you've received.

# Credits: Argyle for the original script and ideas. Gooseman for the modified script. Microsoft for their great documentation.
#         Gorcon for RCON-CLI: https://github.com/gorcon/rcon-cli
#         Miscord for Palog: https://github.com/miscord-dev/palog

###### MAIN SETTINGS ######
# Set this to true only if you are NOT running PalServer on THIS PC (WIP: Not fully implemented yet)
$UseRCONOnRemotePC = $false

if(!$UseRCONOnRemotePC) {
    # Absolute path to your SteamCMD folder. 
    # Example: $SteamCMDPath = "G:\SteamCMD"
    $SteamCMDPath = "G:\SteamCMD"

    # Location of PalServer.exe (this is here because some SteamCMD users use force_install_dir to change the PalServer install location)
    # Example $PalServerPath ="G:\SteamCMD\steamapps\common\PalServer"
    $PalServerPath = "G:\SteamCMD\steamapps\common\PalServer"
}


# Sets whether SteamCMD should be re-ran every time the server starts or restarts
$UpdateOrVerifyServer = $true

# Whether the server will show up in the server browser or not, adds a launch parameter
$IsCommunityServer = $false

# Server launch parameters. If $IsCommunityServer is set to true EpicApp=PalServer will be added at the start
# 28/2/2024: Temp quick fix for RCON not working on v0.1.5.0, added "-RCONPort=25575". 
$PalServerArguments = "'$(if ($IsCommunityServer) { 'EpicApp=PalServer ' })-useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -RCONPort=25575'"

# Set the palworld server priority to High (gives better performance in exchange for higher CPU usage)
$UseHighPriority = $true

# Use PALOG if available
$UsePalog = $true;

# Backup settings
$BackupsEnabled = $true

# World backup in minutes
$BackupIntervalMinutes = 30

# After how many days backups should be deleted
# Set to 0 to disable backup deletion
$BackupDeleteDays = 3

# Backup directory. By default it creates a folder called 'backup\YOUR_WOLD_GUID\' in your PalServer root. You can change this to whatever you'd like.
# Example: $BackupPath = "G:\SteamCMD\steamapps\common\PalServer\backups"
$BackupPath = $PalServerPath +"\backups"

# Server restart settings
# We NEED to restart the server periodically due to the memory leak experienced on Windows versions of the server (we still need this as of 0.1.4.0)
$ServerRestartEnabled = $true

# Server restart in hours (recommended 6 hours)
$RestartIntervalHours = 3

# Time in seconds between the server shutdown announcement and the actual shutdown
$ShutdownWarningSeconds = 30

# Settings only for people running this script from a remote computer (WIP: Not fully implemented yet)
if ($UseRCONOnRemotePC) {
    $SteamCMDPath = ''
    $PalServerPath = ''
    $ServerAddress = ''
    $RCONPort = ''
    $AdminPassword = ''
}

###### MAIN SETTINGS END ######

############################################################################################################

# !!!!!If you are a casual user do not tinker with the script below unless you know what you are doing!!!!!

# App ID of the game server (this shouldn't change)
$AppID = 2394010

# If it's the users's first time running SteamCMD or PalServer, or both
$FirstRun = $false

# Users running this script remotely will only be using it for RCON, so SteamCMD or .ini checks are not needed. (WIP)
if (!$UseRCONOnRemotePC) {

    # Check if SteamCMD directory exists and remove any trailing backslashes
    if (!(Test-Path ($SteamCMDPath = $SteamCMDPath.TrimEnd("\"))) ) {
        throw "ERROR: NON-EXISTENT SteamCMD path entered"
    }

    # Define the command to update the game server, usually doesn't need changing
    $UpdateCommand = $SteamCMDPath + "\steamcmd.exe +login anonymous +app_update $AppID validate +quit"

}



funCtion UseSteamCMD {
    Write-Host (Get-Date -Format "t") ": Updating game server." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
    Set-Location $SteamCMDPath
    Invoke-Expression $UpdateCommand
    Write-Host (Get-Date -Format "t") ": Server updated!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
}

# If SteamCMD directory exists but steamcmd.exe doesn't, download it. 
#if ($SteamCMDPath -match '\\$') {
if (!$UseRCONOnRemotePC -and !(Test-Path ($SteamCMDPath + "\SteamCMD.exe"))) {
    $userChoice = $null
    while (!($userChoice -eq 'Y') -and !($userChoice -eq 'N')) {
        Write-Host (Get-Date -Format "t") ": SteamCMD not found in the specified directory, but is required for this program." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        Write-Host (Get-Date -Format "t") ": Would you like to download it into your SteamCMD directory?" -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0) -n;
        $userChoice = Read-Host "[Y/N] "
    }

    if ($userChoice -eq 'N') {
        Write-Host (Get-Date -Format "t") ": This script requires SteamCMD, exiting program." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        throw "steamcmd.exe missing, exiting program."
    }

    # Download SteamCMD
    Write-Host (Get-Date -Format "t") ": Downloading SteamCMD by Valve." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
    $tempDir = ([IO.Path]::GetTempPath()) + ([System.Guid]::NewGuid().ToString('n'))
    $null = New-Item $tempDir -ItemType Directory
    Invoke-WebRequest 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile ($tempDir + "\steamcmd.zip")
    if (Test-Path ($tempDir + "\steamcmd.zip")) {
        # Extract archive to temp dir
        Write-Host (Get-Date -Format "t") ": Extracting files." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
        Expand-Archive -LiteralPath ($tempDir + "\steamcmd.zip") -DestinationPath $tempDir
        Copy-Item ($tempDir + "\steamcmd.exe") $SteamCMDPath 

        Remove-Item $tempDir -Recurse -Force -EA Continue 

        Write-Host (Get-Date -Format "t") ": Sucesfully downloaded and copied SteamCMD.exe into your SteamCMD folder!." -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
    }
    $FirstRun = $true
}

# Check if the directory and executable exist and remove any trailing backslashes
if (!$UseRCONOnRemotePC -and (!(Test-Path ($PalServerPath = $PalServerPath.TrimEnd("\"))) -or !(Test-Path ($PalServerPath + "\PalServer.exe")))) {
    throw "ERROR: NON-EXISTENT PalServer path entered or missing PalServer executable."
}

# Don't use this if we're on a remote PC or we'll just get PalogWorldSettings.ini errors
if (!$UseRCONOnRemotePC) {
    # Check if PalWorldSettings.ini exists
    $PalWorldSettingsConfig = $null
    if (Test-Path -Path "$PalServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini") {
        $PalWorldSettingsConfig = Get-Content -Path "$PalServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini" -Raw
    }
    if (!$PalWorldSettingsConfig -or [string]::IsNullOrWhitespace($PalWorldSettingsConfig)) {
        Write-Host (Get-Date -Format "t") ": Your PalWorldSettings.ini is empty. This is either because you have not set it up or it's your first sever start." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        Write-Host (Get-Date -Format "t") ": Please configure PalWorldSettings.ini before you start this script." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        #Write-Host (Get-Date -Format "t") ": YOU MUST LAUNCH THE SERVER AT LEAST ONCE BEFORE RUNNING THIS SCRIPT!" -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        throw "ERROR: PalWorldSettings.ini missing or empty."
    }

    # Configurable in Palserver\Pal\Config\WindowsServer\PalWorldSettings.ini
    # Looks through Palserver\Pal\Config\WindowsServer\PalWorldSettings.ini and automatically extracts the values

    # This is the local IP used for RCON, do NOT change this if you are running the server on this machine
    $ServerAddress = '127.0.0.1' 
    $RCONPort = [regex]::Match($PalWorldSettingsConfig, 'RCONPort=([0-9]*)').Groups[1].Value.ToString()
    $AdminPassword = [regex]::Match($PalWorldSettingsConfig, 'AdminPassword="([0-9A-Za-z!#%^&*()_+/.,;=-]*)",').Groups[1].Value.ToString()

    # Set the admin password in case we 
    if ([string]::IsNullOrWhitespace($AdminPassword)) {
        while (!($userChoice -eq 'Y') -and !($userChoice -eq 'N')) {
            Write-Host (Get-Date -Format "t") ": You don't seem to have an admin password set in PalWorldSettings.ini." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
            Write-Host (Get-Date -Format "t") ": Would you like to set one now?" -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0) -n
            $userChoice = Read-Host "[Y/N] "
        }
    
        if ($userChoice -eq 'N') {
            Write-Host (Get-Date -Format "t") ": RCON and this script require an admin password to be set." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
            throw "rcon.exe missing, exiting program."
        }
    
        $userChoice = $null
        while($null -eq $userChoice) {
            Write-Host (Get-Date -Format "t") ": Please enter an admin password:" -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0) -n
            $userChoice = Read-Host
            if ([string]::IsNullOrWhitespace($userChoice))
            {
                Write-Host (Get-Date -Format "t") ": This password can't be set, please try another one." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
                $userChoice = $null
            }
        }
        
        (Get-Content -Path "$PalServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini") | ForEach-Object { $_ -replace "AdminPassword=`"`",",("AdminPassword=`""+$userChoice+"`",")} | Set-Content -Path "$PalServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini"
        $AdminPassword = $userChoice
    }
}

# Shove them into one variable so that we don't need to keep combining them
$RCONFullAddress = $ServerAddress+':'+$RCONPort

# PathToTools is the path where we'll be storing any 3rd-party programs. Default path is the SteamCMD path, different for remote PCs
$PathToTools = $SteamCMDPath
# If someone's not using this on the machine they're running the server from then they obviously won't have SteamCMD
if ($UseRCONOnRemotePC) {
    $PathToTools = $PSScriptRoot
}

# Check for RCON and Palog (optional). If they don't exist give the user the option to download them.
if (!(Test-Path ($PathToTools + "\rcon.exe"))) {
    $userChoice = $null
    while (!($userChoice -eq 'Y') -and !($userChoice -eq 'N')) {
        Write-Host (Get-Date -Format "t") ": RCON not found, but is required for this program." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        Write-Host (Get-Date -Format "t") ": Would you like to download it from GitHub into your current directory?" -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0) -n;
        $userChoice = Read-Host "[Y/N] "
    }

    if ($userChoice -eq 'N') {
        Write-Host (Get-Date -Format "t") ": This script requires rcon-cli, exiting program." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        throw "rcon.exe missing, exiting program."
    }

    # Download RCON-CLI by Gorcon
    Write-Host (Get-Date -Format "t") ": Downloading RCON-CLI by Gorcon." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
    $tempDir = ([IO.Path]::GetTempPath()) + ([System.Guid]::NewGuid().ToString('n'))
    $null = New-Item $tempDir -ItemType Directory
    Invoke-WebRequest 'https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-win64.zip' -OutFile ($tempDir + "\rcon-0.10.3-win64.zip")
    if (Test-Path ($tempDir + "\rcon-0.10.3-win64.zip")) {
        # Extract archive to temp dir
        Write-Host (Get-Date -Format "t") ": Extracting files." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
        Expand-Archive -LiteralPath ($tempDir + "\rcon-0.10.3-win64.zip") -DestinationPath $tempDir
        Copy-Item ($tempDir + "\rcon-0.10.3-win64\rcon.exe") $PathToTools 

        Remove-Item $tempDir -Recurse -Force -EA Continue 

        Write-Host (Get-Date -Format "t") ": Sucesfully downloaded and copied rcon.exe into your current folder!." -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
    }
    else {
        throw "ERROR: Something went wrong when downloading rcon.exe, exiting program."
    }
}

# Define executables, usually doesn't need changing
$RCONExecutable = $PathToTools + "\rcon.exe"
$PalServerExecutablePath = $PalServerPath + "\PalServer.exe"
$PalogExecutablePath = $PathToTools + "\palog.exe" # This is an optional download, if you don't have it then it will be disabled

# Download palog if not available
if ($UsePalog -and !(Test-Path $PalogExecutablePath)) {
    $userChoice = $null
    while (!($userChoice -eq 'Y') -and !($userChoice -eq 'N')) {
        Write-Host (Get-Date -Format "t") ": PALOG enabled but not found." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        Write-Host (Get-Date -Format "t") ": Would you like to download it from GitHub into your current directory?" -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0) -n;
        $userChoice = Read-Host "[Y/N] "
    }

    if ($userChoice -eq 'Y') {
        # Download RCON-CLI by Gorcon
        Write-Host (Get-Date -Format "t") ": Downloading PALOG by Miscord." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
        $tempDir = ([IO.Path]::GetTempPath()) + ([System.Guid]::NewGuid().ToString('n'))
        $null = New-Item $tempDir -ItemType Directory
        Invoke-WebRequest 'https://github.com/miscord-dev/palog/releases/download/v0.0.5/palog_0.0.5_windows_amd64.tar.gz' -OutFile ($tempDir + "\palog_0.0.5_windows_amd64.tar.gz")
        if (Test-Path ($tempDir + "\palog_0.0.5_windows_amd64.tar.gz")) {
            # Extract archive to temp dir
            Write-Host (Get-Date -Format "t") ": Extracting files." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
            # Fucking tar
            tar -xzf ($tempDir + "\palog_0.0.5_windows_amd64.tar.gz") -C $tempDir
            Copy-Item ($tempDir + "\palog.exe") $SteamCMDPath 
    
            Remove-Item $tempDir -Recurse -Force -EA Continue 
    
            Write-Host (Get-Date -Format "t") ": Sucesfully downloaded and copied palog.exe into your current folder!." -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
        }
    }
    else {
        Write-Host (Get-Date -Format "t") ": PALOG not downloaded, disabling features." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
        $UsePalog = $false
    }
}


# Check if RCON is enabled. -eq is case-insensitive unless we use -ceq
$RCONEnabled = [regex]::Match($PalWorldSettingsConfig, 'RCONEnabled=([A-Za-z]*)').Groups[1].Value.ToString()
if ($RCONEnabled -eq "False") {
    $userChoice = $null
    while (!($userChoice -eq 'Y') -and !($userChoice -eq 'N')) {
        Write-Host (Get-Date -Format "t") ": RCON is not enabled in your PalWorldSettings.ini, but is required for this program." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        Write-Host (Get-Date -Format "t") ": Would you like this script to enable it in your PalWorldSettings.ini file?" -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0) -n;
        $userChoice = Read-Host "[Y/N] "
    }

    if ($userChoice -eq 'N') {
        Write-Host (Get-Date -Format "t") ": RCON will not be enabled and your PalWorldSettings.ini will not be changed, exiting program." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
        throw "ERROR: RCON is not enabled, exiting program."
    }

    # RCON isn't enabled, we're enabling it ourselves
    Write-Host (Get-Date -Format "t") ": RCON is not enabled, editing the .ini to enable it." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
    (Get-Content -Path "$PalServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini") | ForEach-Object { $_ -replace "RCONEnabled=([A-Za-z]*),","RCONEnabled=True," } | Set-Content -Path "$PalServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini"
    Write-Host (Get-Date -Format "t") ": Successfully updated .ini to enable RCON!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
}

# Vars used later
$LoopIntervalSeconds = 300
$LastBackup = $null
$LastRestart = Get-Date

# Backup paths
$WorldPath = $PalServerPath + "\Pal\Saved\SaveGames\0"

# World name in GUID form
# Defined in Palserver\Pal\Config\WindowsServer\GameUserSettings.ini DedicatedServerName
# Automatically extracts it from your config
$WorldGUID = Get-Content -Path "$PalServerPath\Pal\Saved\Config\WindowsServer\GameUserSettings.ini" -Raw
$WorldGUID = [regex]::Match($WorldGUID, 'DedicatedServerName=([0-9A-F]*)').Groups[1].Value.ToString()

# Validate world GUID (prior to backup/creation of backup folder)
if ( [string]::IsNullOrWhitespace($WorldGUID) ) {
  # World GUID is blank
  Write-Host "YOU MUST LAUNCH THE SERVER AT LEAST ONCE BEFORE RUNNING THIS SCRIPT!" -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
  throw "shit's fucked"
  exit
}

function SetPalogEnvVars {
    # Set the required Palog env variables, these are deleted once the script quits.
    $Env:RCON_ENDPOINT = $RCONFullAddress
    $Env:RCON_PASSWORD = $AdminPassword
    $Env:INTERVAL = "5s"
    $Env:TIMEOUT = '1s'
    $Env:UCONV_LATIN = "false" # Useless on Windows
    # Check if the environment variables already exist TODO
    #Get-Member
}

# Ugly PALOG stuff
if ($UsePalog) {
    SetPalogEnvVars
}

# PWSH 7
#$PalServerArguments = ""+ "`'" + ($IsCommunityServer ? 'EpicApp=PalServer' : '') + " -log -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS'"
# PWSH 5 ver at the suggersiton of Argyle (moved up)
#$PalServerArguments = "'$(if ($IsCommunityServer) { 'EpicApp=PalServer ' })-useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS'"

# Define the command to start the game server
$StartServerCommand = "Start-Process $PalServerExecutablePath -ArgumentList $PalServerArguments"
$StartPalogCommand = "Start-Process $PalogExecutablePath -NoNewWindow"
#$ServerPID = $null
#$PalogPID = $null

# Define the command to check if the game server is running
$CheckServerCommand = "Get-Process -ErrorAction SilentlyContinue | ? Path -eq $PalServerExecutablePath"
$CheckPalogCommand = "Get-Process -ErrorAction SilentlyContinue | ? Path -eq $PalogExecutablePath"

# Initial server start time, not changing during restarts. Use this for log file creation dates
$InitialSeverStartTime = Get-Date -Format "yyyyMMddHHmm"

# Check if there's a backup directory, if not then make one for the specified GUID.
if ($BackupsEnabled -and !(Test-Path ($BackupPath + "\" + $WorldGUID))) {
    Write-Host (Get-Date -Format "t") ": Backup folder does not exist, creating one." -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
	New-Item -ItemType Directory -Path ($BackupPath + "\$WorldGUID")
}

$CurrentTime = Get-Date -Format "HH:mm" # Just a defauklt variable in case someone closes the script before it reaches it

# Send RCON commands, saves a lot of space having it as a func
function RCONSend ($RCONCommand) {
    $RCONArguments = " -a '$($RCONFullAddress)' -p '$($AdminPassword)' '$($RCONCommand)'"
    Invoke-Expression ($RCONExecutable + $RCONArguments)
}

# Server (and config backup
function BackupWorld ($CurrentTime) {
    #Move Saves, Backups and backup removals here
    # Start save
    Write-Host (Get-Date -Format "t") ": Saving world." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
    RCONSend("Broadcast $CurrentTime`:_Saving_World")
    RCONSend("Save")
    
    # Wait for the save to finish (we don't actually know so we're just guessing 10 secs)
    Start-Sleep -Seconds 5
    Write-Host (Get-Date -Format "t") ": World saved!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)

    # Make a backup
    Write-Host (Get-Date -Format "t") ": Saving, compressing and copying backup."  -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
    Compress-Archive -Path "$WorldPath\$WorldGUID\*" -DestinationPath ("$BackupPath\$WorldGUID\" + (Get-Date -Format "yyyyMMddHHmm") + ".zip") -Force
    #Copy-Item -Recurse -Path "$WorldPath\$WorldGUID" -Destination ("$BackupPath\$WorldGUID\" + (Get-Date -Format "yyyyMMddHHmm") + "\") -Force
    Write-Host (Get-Date -Format "t") ": Backup archive saved!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
        
    # Remove backups older than $BackupDeleteDays days
    #$items = Get-ChildItem "$BackupPath\*\*" -Directory -Exclude "archive" | Where-Object LastWriteTime -le (Get-Date).AddDays(-$BackupDeleteDays)
    if (!($BackupDeleteDays -eq 0)) {
        $items = Get-ChildItem "$BackupPath\*\*" | Where-Object LastWriteTime -le (Get-Date).AddDays(-$BackupDeleteDays)
        $items | Remove-Item -Force
    }

}

#$DebugStuff = $false # should be FALSE, only used for debugging

#if ($DebugStuff)
#{
#    $job = Start-Job -Scriptblock { 
#        1..100 | ForEach-Object {
#            (Get-Date -Format "t") + "Job iteration $_"
#            Start-Sleep -Seconds 1
#        }
#    }
#}


############## Start an infinite loop
try {
    while($true) {
        #The current time (for messages over RCON)
        $CurrentTime = Get-Date -Format "HH:mm"

        # Update and start the server, either first time or after a restart
        #if (!(Invoke-Expression $CheckServerCommand)) {
        if (!(Get-Process "PalServer-Win64-Test-Cmd" -ErrorAction SilentlyContinue)) {
            if ($UpdateOrVerifyServer) {
                UseSteamCMD
            }
            Write-Host (Get-Date -Format "t") ": Starting game server." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
            Invoke-Expression $StartServerCommand

            # Give the server some time to start, otherwise we will get RCON spam. I don't know how to check when the server has booted up.
            Start-Sleep -Seconds 20

            # Server has probably started by now.
            $CurrentTime = Get-Date -Format "HH:mm"
            Write-Host (Get-Date -Format "t") ": Server started!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
            RCONSend("Broadcast $CurrentTime`:_Server_Started!") #  ':_

            # Set the proccess priority to High for weaker computers   
            if ($UseHighPriority) {
                # We're not using Palserver.exe as that's not the main server process
                $ServerProcess = Get-Process "PalServer-Win64-Test-Cmd" -ErrorAction SilentlyContinue
                if ($ServerProcess) {
                    $ServerProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                    Write-Host (Get-Date -Format "t") ": Server process priority set to High!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
                }
            }

            $LoopIntervalSeconds = 300
        }
        
        # debug stuff ignore
        #if ($DebugStuff -and ($job.HasMoreData -or $job.Status -eq 'Running'))
        #{
        #    $WaitSeconds = Get-Random -Min 1 -Max 5
        #   "Waiting $WaitSeconds Seconds...`n"
        #    Start-Sleep -Seconds $WaitSeconds
        #    
        #    "Receiving job output:`n"
        #    Receive-Job $job | Tee-Object -Append -FilePath "G:\SteamCMD\SHITASS.txt"
        #    "`n"
        #}

        # Check if we're even using palog and start it
        # Palog only gets killed when the script is interrupted, and during server restarts.
        # Do not launch unless PalServer is running or you'll be getting log spam
        if($UsePalog -and !(Get-Process | Where-Object {$_.Path -like $PalogExecutablePath} -ErrorAction SilentlyContinue) -and (Get-Process "PalServer-Win64-Test-Cmd" -ErrorAction SilentlyContinue)) {
            Write-Host (Get-Date -Format "t") ": Starting Palog." -BackgroundColor DarkYellow -ForegroundColor Black -n;   Write-Host ([char]0xA0)
            SetPalogEnvVars
            Invoke-Expression $StartPalogCommand
            #Start-Process $PalogExecutablePath -NoNewWindow -RedirectStandardError ("$BackupPath\$WorldGUID\log-" + $InitialServerStartTime + ".txt") ;Get-Content ("$BackupPath\$WorldGUID\log-" + $InitialServerStartTime + ".txt") -Wait
            if(Get-Process "palog" -ErrorAction SilentlyContinue) {
                Write-Host (Get-Date -Format "t") ": Palog started!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
            }
        }

        # Backup only
        if ($BackupsEnabled) {
            if ((Invoke-Expression $CheckServerCommand) -and (!($LastBackup) -or ((New-TimeSpan -Start $LastBackup -End (Get-Date)).Minutes -ge $BackupIntervalMinutes))) {
                # Start save
                BackupWorld($CurrentTime)
                $LastBackup = Get-Date
            }
        }


        # Save and restart (memory leak)
        if ($ServerRestartEnabled) {
            if ((New-TimeSpan -Start $LastRestart -End (Get-Date)).Hours -ge $RestartIntervalHours) {
                $LastRestart = Get-Date
                BackupWorld($CurrentTime)
                $LastBackup = Get-Date

                # Shutdown/restart
                Write-Host (Get-Date -Format "t") ": Restarting server." -BackgroundColor DarkRed -ForegroundColor Black -n;   Write-Host ([char]0xA0)
                RCONSend("Broadcast $CurrentTime`:_Restarting_Server")
                RCONSend("Shutdown $ShutdownWarningSeconds `"Shutting_Down`"")

                if($UsePalog -and (Invoke-Expression $CheckPalogCommand)) {
                    Write-Host (Get-Date -Format "t") ": Shutting down palog." -BackgroundColor DarkRed -ForegroundColor Black -n;   Write-Host ([char]0xA0)
                    # Stopgap until I get around to saving proccess IDs
                    Get-Process | Where-Object {$_.Path -like $PalogExecutablePath} -ErrorAction SilentlyContinue | Stop-Process -Force
                    #Get-Process "palog" -ErrorAction SilentlyContinue | Stop-Process -PassThru
                }
                $LoopIntervalSeconds = $ShutdownWarningSeconds + 5
            }
        }

        # Wait before the next iteration
        Start-Sleep -Seconds $LoopIntervalSeconds
    }
} 
finally {
    # Start save
    BackupWorld($CurrentTime)

    # Shutdown/restart
    Write-Host (Get-Date -Format "t") ": Shutting down server." -BackgroundColor DarkRed -ForegroundColor Black -n;   Write-Host ([char]0xA0)
    RCONSend("Broadcast $CurrentTime`:_SHUTTING_DOWN_IMMEDIATELY")
    RCONSend("Shutdown $ShutdownWarningSeconds SHUTTING_DOWN_IMMEDIATELY") #  `"SHUTTING_DOWN_IMMEDIATELY`"

    # Wait for the server to shutdown
    Start-Sleep -Seconds $ShutdownWarningSeconds + 5
    
    # Kill SteamCMD if it's still running for whatever reason
    if ($UpdateOrVerifyServer -and (Get-Process -ErrorAction SilentlyContinue | Where-Object Path -eq ($SteamCMDPath + "\steamcmd.exe"))) {
        Write-Host (Get-Date -Format "t") ": Shutting down SteamCMD." -BackgroundColor DarkRed -ForegroundColor Black -n;   Write-Host ([char]0xA0)
        Get-Process | Where-Object {$_.Path -like ($SteamCMDPath + "\steamcmd.exe")} -ErrorAction SilentlyContinue | Stop-Process -Force
    }

    # Kill RCON if it's still running
    if (Get-Process -ErrorAction SilentlyContinue | Where-Object Path -eq ($SteamCMDPath + "\rcon.exe")) {
        Write-Host (Get-Date -Format "t") ": Shutting down RCON." -BackgroundColor DarkRed -ForegroundColor Black -n;   Write-Host ([char]0xA0)
        Get-Process | Where-Object {$_.Path -like ($SteamCMDPath + "\rcon.exe")} -ErrorAction SilentlyContinue | Stop-Process -Force
    }

    # Kill palog.
    if ($UsePalog -and (Invoke-Expression $CheckPalogCommand)) {
        # Checks if it's running and kills it.
        Write-Host (Get-Date -Format "t") ": Shutting down palog." -BackgroundColor DarkRed -ForegroundColor Black -n;   Write-Host ([char]0xA0)
        # Stopgap until I get around to saving proccess IDs
        Get-Process | Where-Object {$_.Path -like $PalogExecutablePath} -ErrorAction SilentlyContinue | Stop-Process -Force
        #Get-Process "palog" -ErrorAction SilentlyContinue | Stop-Process -PassThru
        # Remove the env variables
        Remove-Item -Path Env:\RCON_ENDPOINT #-Verbose
        Remove-Item -Path Env:\RCON_PASSWORD #-Verbose
        Remove-Item -Path Env:\INTERVAL #-Verbose
        Remove-Item -Path Env:\TIMEOUT #-Verbose
        Remove-Item -Path Env:\UCONV_LATIN #-Verbose
    }
    # TODO: Add checks to see if the server or palog are still running.
    if (!(Get-Process "palog" -ErrorAction SilentlyContinue) -and !(Get-Process "PalServer" -ErrorAction SilentlyContinue)) {
        Write-Host (Get-Date -Format "t") ": Script has quit succesfully!" -BackgroundColor DarkGreen -ForegroundColor White -n;   Write-Host ([char]0xA0)
    }
    else {
        Write-Host (Get-Date -Format "t") ": Script has quit but some processes are still running!" -BackgroundColor DarkRed -ForegroundColor White -n;   Write-Host ([char]0xA0)
    }
}