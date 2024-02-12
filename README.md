# YAPS: Yet Another Palworld Script
An all-in-one Palworld powershell script for Windows dedicated server hosting.

## Requirements

- **[SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD#Downloading_SteamCMD)**
- A valid PalServer install

## Guide

> [!IMPORTANT]
> Edit the .ps1 file to set the directories for SteamCMD ```$SteamCMDPath``` and PalServer ```$PalServerPath```, these are one of the only 2 variables that require for this script to function.

- You can also change other variables in the .ps1 file under **MAIN SETTINGS**
 * You **MUST** run the server at least once before running this script (will be automated in a future update).

## Features

- Automatically update and validate server via SteamCMD every start and restart if ```$UpdateOrVerifyServer``` is enabled
- Automatic PalServer launch params ```$PalServerArguments``` 
- Automatic PalServer restart on crash
- Set server as community server if ```$IsCommunityServer``` is enabled
- Automatically sets the server process as "High" priority, giving you a little bit better poerformance at the cost of CPU usage if ```$UseHighPriority``` is enabled
- Backups every 30 ```$BackupIntervalMinutes``` minutes if ```$BackupsEnabled``` is enabled, backups are stored as .zip files
- Backup deletion after 3 ```$BackupDeleteDay``` days, if set to 0 backup deletion will be disabled
- Set where backups are stored ```$BackupPath```
- Automatic save, backup and restarts every 3 ```$RestartIntervalHours``` hours if ```$ServerRestartEnabled``` is enabled. This is mainly due to the current memory leak (still present in version ```0.1.4.1```)
- **[PALOG](https://github.com/miscord-dev/palog)** support if ```$UsePalog``` is enabled
- Automatically edits ```PalWorldSettings.ini``` if RCON is disabled. **You will be asked to agree to this change first.**
- Automatically download SteamCMD if the folder exists but doesn't have ```steamcmd.exe``` (this will not be a requirement in a future update for people that run the script from a remote machine)
- Automatically download **[RCON-CLI](https://github.com/gorcon/rcon-cli)** to your SteamCMD directory. **You will be asked to agree to this first.**
- Automatically download **[PALOG](https://github.com/miscord-dev/palog)** to your SteamCMD directory. **You will be asked to agree to this first.**
- Automatically extracts the RCON port from your ```PalWorldSettings.ini```
- Automatically extracts the Admin password required for RCON from your ```PalWorldSettings.ini```
- * If you don't have an Admin password set, you will be asked to create one

## Modifiable variables

|var name|default|description|
|----|---------|---------|
|```$UseRCONOnRemotePC```|\$false|Sets if the script is ran on a computer different than the one the server is ran on|
|```$SteamCMDPath```|string|Sets the SteamCMD location|
|```$PalServerPath```|string|Sets the PalServer location|
|```$UpdateOrVerifyServer```|\$true|Update and verify server through SteamCMD on every launch and re-launch|
|```$IsCommunityServer```|$false|Whether the server wil show up in the the server browser|
|```$PalServerArguments```|string|Arguments that the server is launched with, set by default for better performance|
|```$UseHighPriority```|$true|Sets the PalServer process to "High Priority" for slightly better performance|
|```$UsePalog```|$true|Whether to use PALOG|
|```$BackupsEnabled```|$true|Enable periodic backups|
|```$BackupIntervalMinutes```|30|Minutes between backups|
|```$BackupDeleteDays```|3|Automaticaly delete backups after the set number of days|
|```$BackupPath```|string|Path to where the backups are stored|
|```$ServerRestartEnabled```|$true|Restart server after a certain amount of time|
|```$RestartIntervalHours```|3|Hours between server restarts|
|```$ShutdownWarningSeconds```|30|Time between the shutdown/restart announcement and the actual shutdown/restart|

## Troubleshooting

If you are getting an error about being unable to run scripts on this machine please follow these steps:

- Open Powershell **as admin**  
- Type in ``` Set-ExecutionPolicy RemoteSigned ```, press enter and then try again

If you encounter any other errors or crashes contact @gooseman0 on discord with the error message you've received.

## TODO
- [ ] Expose more variables to users
- [ ] Finish WIP support for remote PCs
- [ ] Add support for "dry runs", servers that start and are set up for the first time through the script
- [ ] Move from RCON-CLI to Lysec's RCON client
- [ ] Add PALOG features natively
- [ ] Clean up unused things from the code

## Credits

- **Argyle** for the original script and ideas.
- **Gooseman** for the modified script.
- Microsoft for their great documentation.
- **Gorcon** for **[RCON-CLI](https://github.com/gorcon/rcon-cli)**
- **Miscord** for **[PALOG](https://github.com/miscord-dev/palog)**
- **Lysec** for a future RCON and PALOG replacement.
- **Makito** for README.md improvement suggestions.