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
  SimpleCmdLineParser,
  CondenserClass;

procedure ShowProgramHead;
begin
WriteLn('****************************************');
WriteLn('*                                      *');
WriteLn('*  TelemetrySDK Headers Condenser 1.0  *');
WriteLn('*                                      *');
WriteLn('*        (c)2023 Frantisek Milt        *');
WriteLn('*                                      *');
WriteLn('****************************************');
end;

//------------------------------------------------------------------------------

procedure ShowHelp;
begin
WriteLn;
WriteLn('Usage:');
WriteLn;
WriteLn('  condenser [parameters] outfile');
Writeln;
WriteLn('    parameters (all are optional):');
WriteLn;
WriteLn('      -h, --help  ... shows this help text (supresses processing if present)');
WriteLn('      -s, --split ... add splitters (code decoration) to output');
WriteLn('          --debug ... debug run only (full processing, but nothing is saved)');
WriteLn;
WriteLn('    outfile - name of a file to which the condesed headers will be stored');
WriteLn('              (created in current directory)');
WriteLn;
WriteLn;
Write('Press enter to exit...'); ReadLn;
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
    If not CmdParams.CommandPresent('h','help') and ((CmdParams.Count > 1) and (CmdParams.Last.ParamType = ptGeneral)) then
      begin
        WriteLn;
        WriteLn('Preparing condenser...');
        Condenser := TCondenserClass.Create;
        try
          // set condenser parameters from command line
          Condenser.AddSplitters := CmdParams.CommandPresent('s','split');
          Condenser.DebugRun := CmdParams.CommandPresentLong('debug');
          WriteLn;
          WriteLn('Condensing files...');
          Condenser.Run;
          readln;
        finally
          Condenser.Free;
        end;
      end
    else ShowHelp;
  finally
    CmdParams.Free;
  end;
except
  on E: Exception do
    begin
      WriteLn;
      WriteLn(' Error - ',E.ClassName,': ',E.Message);
      WriteLn;
      Write('Press enter to continue...'); ReadLn;
    end;
end;
end;

end.
