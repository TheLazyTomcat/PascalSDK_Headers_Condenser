{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit CondenserMain;

{$IFDEF FPC}
  {$MODE ObjFPC}
{$ENDIF}
{$H+}

interface

procedure Main;

implementation

uses
  SysUtils,
  SimpleCmdLineParser, StrRect,
  CondenserClass;

procedure ShowProgramHead;
begin
WriteLn('*************************************');
WriteLn('*                                   *');
WriteLn('*  PascalSDK Headers Condenser 1.0  *');
WriteLn('*                                   *');
WriteLn('*      (c)2023 Frantisek Milt       *');
WriteLn('*                                   *');
WriteLn('*************************************');
end;

//------------------------------------------------------------------------------

procedure ShowProgramHelp;
begin
WriteLn;
WriteLn('usage:');
WriteLn;
WriteLn('  condenser [opt_params] -s source_files -t template_file -o output_file');
WriteLn;
WriteLn('    mandatory parameters:');
WriteLn;
WriteLn('      -s source_files      list of source files (headers) to be condensed');
WriteLn('      -t template_file     file containing template for the output');
WriteLn('      -o output_file       file to which the condensed headers will be saved');
WriteLn;
WriteLn('    optional parameters (opt_params):');
WriteLn;
WriteLn('      -h  --help      shows this help text (supresses processing if present)');
WriteLn('          --split     add splitters (code decoration) to output');
WriteLn('          --debug     debug run only (full processing, but nothing is saved)');
WriteLn;
WriteLn('      -d define_files     files from which defines will be loaded');
WriteLn('      -c source_file      source file from which to load a description');
WriteLn;
WriteLn('For more details, consult readme.txt file distributed with this program.');
WriteLn;
Write('Press enter to continue...'); ReadLn;
end;

//------------------------------------------------------------------------------

procedure Main;
var
  CmdParams:  TSCLPParser;
  Condenser:  TCondenserClass;
begin
try
  ShowProgramHead;
  CmdParams := TSCLPParser.Create;
  try
    If CmdParams.CommandCount > 0 then
      begin
        Condenser := TCondenserClass.Create;
        try
          If Condenser.CanRun then
            begin
              WriteLn;
              WriteLn('running condenser...');
              Condenser.Run;
              ExitCode := 0;
            end
          else ShowProgramHelp;
        finally
          Condenser.Free;
        end;
      end
    else ShowProgramHelp;
  finally
    CmdParams.Free;
  end;
except
  on E: Exception do
    begin
      ExitCode := -1;
      WriteLn;
      WriteLn(' Error - ',E.ClassName,': ',StrToCSL(E.Message));
      WriteLn;
      Write('Press enter to continue...'); ReadLn;
    end;
end;
end;

end.

