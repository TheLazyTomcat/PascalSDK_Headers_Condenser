@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

IF EXIST ..\Release ( 
  RD ..\Release /s /q
)

MKDIR ..\Release

COPY ..\readme.txt ..\Release\readme.txt

COPY ..\license.txt ..\Release\license.txt

COPY "..\Delphi\Release\win_x86\Condenser.exe" "..\Release\Condenser.exe"
COPY "..\Lazarus\Release\lin_x86\Condenser" "..\Release\condenser_lin32"
COPY "..\Lazarus\Release\lin_x64\Condenser" "..\Release\condenser_lin64"

ENDLOCAL