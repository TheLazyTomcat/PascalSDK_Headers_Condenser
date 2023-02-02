@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

DEL ..\Delphi\Release\win_x86\Condenser.exe /S /Q 
 
DEL ..\Lazarus\Release\win_x86\Condenser.exe /S /Q  
DEL ..\Lazarus\Release\win_x64\Condenser.exe /S /Q
DEL ..\Lazarus\Debug\win_x86\Condenser.exe /S /Q 
DEL ..\Lazarus\Debug\win_x64\Condenser.exe /S /Q

DEL ..\Lazarus\Release\lin_x86\Condenser /S /Q 
DEL ..\Lazarus\Release\lin_x64\Condenser /S /Q
DEL ..\Lazarus\Debug\lin_x86\Condenser /S /Q
DEL ..\Lazarus\Debug\lin_x64\Condenser /S /Q

ENDLOCAL