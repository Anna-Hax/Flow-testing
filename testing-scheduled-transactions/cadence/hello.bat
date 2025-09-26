@echo off
setlocal enabledelayedexpansion

:: Check if user provided a start block
if "%~1"=="" (
    echo Usage: %~nx0 START_BLOCK
    exit /b 1
)

:: Input start block from command-line
set START=%1
set /a END=%START%+200

:: Contract address and network
set CONTRACT=A.ac5b1841720e845a.SimpleScheduledMarketplace
set NETWORK=testnet

:: List of events
set EVENTS=Listed BidPlaced BidReplaced AuctionCompleted Cancelled FundsTransferred RandomEvent Randomevent2 Randomevent3 Randomevent4 Randomevent5 Randomevent6 Randomevent7 Randomevent8 Randomevent9 Randomevent10

:: Loop through each event
for %%E in (%EVENTS%) do (
    echo ==============================
    echo Checking event: %%E
    echo ==============================
    flow events get %CONTRACT%.%%E --start %START% --end %END% -n %NETWORK%
    echo.
)

endlocal
