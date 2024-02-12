# YAPS: Yet Another Palworld Script 
A Palworld powershell script for Windows dedicated server hosting.

## Features

* Automatically update and validate server via SteamCMD every start and restart if ($UpdateOrVerifyServer) is enabled
* Automatic PalServer launch params (**$PalServerArguments**) 
* Automatic PalServer restart on crash
* Set server as community server if (**$IsCommunityServer**) is enabled
* Automatically sets the server process as "High" priority, giving you a little bit better poerformance at the cost of CPU usage if (**UseHighPriority**) is enabled
* Backups every 30 (**$BackupIntervalMinutes**) minutes if (**$BackupsEnabled**) is enabled, backups are stored as .zip files
* Backup deletion after 3 (**$BackupDeleteDay**) days, if set to 0 backup deletion will be disabled
* Set where backups are stored (**$BackupPath**)
* Automatic save, backup and restarts every 3 (**$RestartIntervalHours**) hours if (**$ServerRestartEnabled**) is enabled. This is mainly due to the current memory leak (still present in 0.1.4.1)
* **PALOG** support if (**$UsePalog**) is enabled
* Automatically edits your PalWorldSettings.ini if RCON is disabled (**You must agree to this change first**)
* Automatically download SteamCMD if the folder exists but doesn't have steamcmd.exe (this evemtually won't be a requirement if the script is ran on a remote machine)
* Automatically download **RCON-CLI** to your SteamCMD directory (**You must agree to this first**)
* Automatically download **PALOG** to your SteamCMD directory (**You must agree to this first**)
* Automatically extracts the RCON port from your PalWorldSettings.ini
* Automatically extracts the Admin password required for RCON from your PalWorldSettings.ini
* * If you don't have an Admin password set, it will ask you if you'd like to create one

## Requirements

* SteamCMD
* A valid PalServer install

## Guide
Edit the .ps1 file to set your SteamCMD ($SteamCMDPath) and PalServer ($PalServerPath) location, this is required.
* You can also change other variables in the .ps1 file under **MAIN SETTINGS**
 * You **MUST** run the server at least once before running this script (will be removed in a future update).

## Credits
* **Argyle** for the original script and ideas. 
* **Gooseman** for the modified script.
* Microsoft for their great documentation.
* **Gorcon** for **RCON-CLI**: https://github.com/gorcon/rcon-cli
* **Miscord** for **PALOG**: https://github.com/miscord-dev/palog

## Troubleshooting

If you are getting an error about being unable to run the script please follow these steps:
* Open Powershell **as an admin**  
* Type in **Set-ExecutionPolicy RemoteSigned** and then try again

If you encounter any other errors or crashes contact @gooseman0 on discord with the error message you've received.

## TODO
- [ ] Expose more variables to users
- [ ] Finish WIP support for remote PCs
- [ ] Add support for "dry runs", servers that start and are set up for the first time through the script
- [ ] Move from RCON-CLI to Lysec's RCON client
- [ ] Add PALOG features natively
- [ ] Clean up unused things from the code