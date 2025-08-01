@echo off
:: Skyblock21 AutoUpdater Deleter Script, Used with Skyblock21's AutoUpdater (https://github.com/sme6en/Skyblock21/blob/main/src/main/java/com/skyblock21/util/AutoUpdater.java)
:: NOTE: This is a workaround for Windows, which doesn't work well with File.deleteOnExit()
:: Instead, we create a batch file that will delete the old mod file on game shutdown.
:: I know it looks very sus, but it's the only way to ensure the file is deleted properly
:: or else your game won't start next time you launch it.
:TestFile
REN "C:\Users\User\Documents\MultiMC\instances\1.21.5 (Fabric) Skyblock\.minecraft\mods\skyblock21-1.2.2.1.jar" "skyblock21-1.2.2.1.jar" 2>nul
IF not ERRORLEVEL 1 GOTO Continue
GOTO TestFile
:Continue
ECHO Deleting "C:\Users\User\Documents\MultiMC\instances\1.21.5 (Fabric) Skyblock\.minecraft\mods\skyblock21-1.2.2.1.jar"
DEL /F "C:\Users\User\Documents\MultiMC\instances\1.21.5 (Fabric) Skyblock\.minecraft\mods\skyblock21-1.2.2.1.jar"
EXIT

