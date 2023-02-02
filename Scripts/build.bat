@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

CD ..\Delphi
dcc32.exe -Q -B Condenser.dpr

CD ..\Lazarus
lazbuild -B --no-write-project --bm=Release_win_x86 Condenser.lpi
lazbuild -B --no-write-project --bm=Release_win_x64 Condenser.lpi
lazbuild -B --no-write-project --bm=Debug_win_x86 Condenser.lpi
lazbuild -B --no-write-project --bm=Debug_win_x64 Condenser.lpi

lazbuild -B --no-write-project --bm=Release_lin_x86 Condenser.lpi
lazbuild -B --no-write-project --bm=Release_lin_x64 Condenser.lpi
lazbuild -B --no-write-project --bm=Debug_lin_x86 Condenser.lpi
lazbuild -B --no-write-project --bm=Debug_lin_x64 Condenser.lpi

ENDLOCAL