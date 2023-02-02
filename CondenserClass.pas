{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit CondenserClass;

{$IFDEF FPC}
  {$MODE ObjFPC}
{$ENDIF}  
{$H+}

interface

uses
  SysUtils, Classes;

{===============================================================================
    Project-specific exceptions
===============================================================================}
type
  TCONDException = class(Exception);

  TCONDMissingParameter = class(TCONDException);
  TCONDInvalidParameter = class(TCONDException);

  TCONDInvalidParsingStage = class(TCONDException);
  TCONDInvalidParsingTag   = class(TCONDException);

{===============================================================================
--------------------------------------------------------------------------------
                                 TCondenserClass
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TCondenserClass - class declaration
===============================================================================}
type
  TCondenserClass = class(TObject)
  protected
    // input parameters
    fSourceFiles:         TStringList;
    fOutTemplate:         TStringList;
    fOutFileName:         String;
    fUnitName:            String;
    fAddSplitters:        Boolean;
    fDebugRun:            Boolean;
    fDefinesFiles:        TStringList;
    fDescriptionFile:     String;
    // runtime variables
    fCanRun:              Boolean; 
    // runtime lists (condensed lines)
    fCondDescription:     TStringList;
    fCondDefines:         TStringList;
    fCondInterface:       TStringList;
    fCondImplementation:  TStringList;
    fCondInitialization:  TStringList;
    fCondFinalization:    TStringList;
    procedure ParseDescriptionFile; virtual;
    procedure ParseDefinesFiles; virtual;
    procedure ParseSourceFiles; virtual;
    procedure ConstructOutput(OutLines: TStrings); virtual;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run; virtual;
    property AddSplitters: Boolean read fAddSplitters write fAddSplitters;
    property DebugRun: Boolean read fDebugRun write fDebugRun;
    property CanRun: Boolean read fCanRun;
  end;

implementation

uses
  StrRect, SimpleCmdLineParser;

{===============================================================================
--------------------------------------------------------------------------------
                                 TCondenserClass
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TCondenserClass - implementation constants
===============================================================================}
const
  // source tags
  COND_SRCTAG_START_UNIT           = '(*<unit>*)';
  COND_SRCTAG_END_UNIT             = '(*</unit>*)';
  COND_SRCTAG_START_INTERFACE      = '(*<interface>*)';
  COND_SRCTAG_END_INTERFACE        = '(*</interface>*)';
  COND_SRCTAG_START_IMPLEMENTATION = '(*<implementation>*)';
  COND_SRCTAG_END_IMPLEMENTATION   = '(*</implementation>*)';
  COND_SRCTAG_START_INITIALIZATION = '(*<initialization>*)';
  COND_SRCTAG_END_INITIALIZATION   = '(*</initialization>*)';
  COND_SRCTAG_START_FINALIZATION   = '(*<finalization>*)';
  COND_SRCTAG_END_FINALIZATION     = '(*</finalization>*)';

  // template tags
  COND_TPLTAG_DESCRIPTION    = ('<description>');
  COND_TPLTAG_UNITNAME       = ('<unit_name>');
  COND_TPLTAG_DEFINES        = ('<defines>');
  COND_TPLTAG_INTERFACE      = ('<interface>');
  COND_TPLTAG_IMPLEMENTATION = ('<implementation>');
  COND_TPLTAG_INITIALIZATION = ('<initialization>');
  COND_TPLTAG_FINALIZATION   = ('<finalization>');

  // defines tags
  COND_DEFTAG_BODY_START = '(*<body>*)';
  COND_DEFTAG_BODY_END   = '(*</body>*)';

{===============================================================================
    TCondenserClass - auxiliary functions
===============================================================================}

procedure TrimLines(Lines: TStrings);
var
  i:  Integer;
begin
// first trim from the back
For i := Pred(Lines.Count) downto 0 do
  If Length(Trim(Lines.Strings[i])) <= 0 then
    Lines.Delete(i)
  else
    Break{For i};
// now trim from the front
while Lines.Count > 0 do
  If Length(Trim(Lines[0])) <= 0 then
    Lines.Delete(0)
  else
    Break{while};
end;

//------------------------------------------------------------------------------

procedure AppendLines(ToLines,FromLines: TStrings);
var
  i:  Integer;
begin
If FromLines.Count > 0 then
  For i := 0 to Pred(FromLines.Count) do
    ToLines.Add(FromLines[i]);
end;

{===============================================================================
    TCondenserClass - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TCondenserClass - protected methods
-------------------------------------------------------------------------------}

procedure TCondenserClass.ParseDescriptionFile;
var
  InLines:  TStringList;
  Line:     Integer;
begin
InLines := TStringList.Create;
try
  InLines.LoadFromFile(StrToRTL(fDescriptionFile));
  TrimLines(InLines);
  For Line := 0 to Pred(InLines.Count) do
    If not AnsiSameText(Trim(InLines[Line]),COND_SRCTAG_START_UNIT) then
      fCondDescription.Add(InLines[Line])
    else
      Break{For Line};
finally
  InLines.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.ParseDefinesFiles;
var
  InLines:    TStringList;
  TempLines:  TStringList;
  i,Line:     Integer;
  InBody:     Boolean;
begin
InLines := TStringList.Create;
try
  TempLines := TStringList.Create;
  try
    For i := 0 to Pred(fDefinesFiles.Count) do
      begin
        InLines.LoadFromFile(StrToRTL(fDefinesFiles[i]));
        TempLines.Clear;
        InBody := False;
        For Line := 0 to Pred(InLines.Count) do
          begin
            If AnsiSameText(Trim(InLines[Line]),COND_DEFTAG_BODY_START) then
              begin
                If not InBody then
                  InBody := True
                else
                  raise TCONDInvalidParsingTag.Create('TCondenserClass.ParseDefinesFiles: Body-start tag is not allowed here.');
              end
            else If AnsiSameText(Trim(InLines[Line]),COND_DEFTAG_BODY_END) then
              begin
                If InBody then
                  Inbody := False
                else
                  raise TCONDInvalidParsingTag.Create('TCondenserClass.ParseDefinesFiles: Body-end tag is not allowed here.');
              end
            else If InBody then
              TempLines.Add(InLines[Line]);
          end;
        TrimLines(TempLines);
        If TempLines.Count > 0 then
          begin
            fCondDefines.Add('');
            AppendLines(fCondDefines,TempLines);
          end;
      end;
  finally
    TempLines.Free;
  end;
finally
  InLines.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.ParseSourceFiles;
const
  BAD_TAG_ERR = 'TCondenserClass.ParseSourceFiles: This tag (%d) is not allowed here (%d).';
type
  TCONDParsingStage = (psInitial,psUnit,psInterface,psImplementation,psInitialization,psFinalization);
  TCONDParsingTag = (ptNone,ptUnitStart,ptUnitEnd,ptInterfaceStart,ptInterfaceEnd,
                     ptImplementationStart,ptImplementationEnd,ptInitializationStart,
                     ptInitializationEnd,ptFinalizationStart,ptFinalizationEnd);

  Function GetLineTag(const LineText: String): TCONDParsingTag;
  begin
    If AnsiSameText(LineText,COND_SRCTAG_START_UNIT) then
      Result := ptUnitStart
    else If AnsiSameText(LineText,COND_SRCTAG_END_UNIT) then
      Result := ptUnitEnd
    else If AnsiSameText(LineText,COND_SRCTAG_START_INTERFACE) then
      Result := ptInterfaceStart
    else If AnsiSameText(LineText,COND_SRCTAG_END_INTERFACE) then
      Result := ptInterfaceEnd
    else If AnsiSameText(LineText,COND_SRCTAG_START_IMPLEMENTATION) then
      Result := ptImplementationStart
    else If AnsiSameText(LineText,COND_SRCTAG_END_IMPLEMENTATION) then
      Result := ptImplementationEnd
    else If AnsiSameText(LineText,COND_SRCTAG_START_INITIALIZATION) then
      Result := ptInitializationStart
    else If AnsiSameText(LineText,COND_SRCTAG_END_INITIALIZATION) then
      Result := ptInitializationEnd
    else If AnsiSameText(LineText,COND_SRCTAG_START_FINALIZATION) then
      Result := ptFinalizationStart
    else If AnsiSameText(LineText,COND_SRCTAG_END_FINALIZATION) then
      Result := ptFinalizationEnd
    else
      Result := ptNone;
  end;

var
  i:                    Integer;
  CurrentStage:         TCONDParsingStage;
  CurrentTag:           TCONDParsingTag;
  Line:                 Integer;
  InLines:              TStringList;
  InterfaceLocal:       TStringList;
  ImplementationLocal:  TStringList;
  InitializationLocal:  TStringList;
  FinalizationLocal:    TStringList;

  procedure CreateLocalLists;
  begin
    InterfaceLocal := nil;
    ImplementationLocal := nil;
    InitializationLocal := nil;
    FinalizationLocal := nil;
    InterfaceLocal := TStringList.Create;
    ImplementationLocal := TStringList.Create;
    InitializationLocal := TStringList.Create;
    FinalizationLocal := TStringList.Create;
  end;

  procedure ClearLocalLists;
  begin
    InterfaceLocal.Clear;
    ImplementationLocal.Clear;
    InitializationLocal.Clear;
    FinalizationLocal.Clear;
  end;

  procedure DestroyLocalLists;
  begin
    FinalizationLocal.Free;
    InitializationLocal.Free;
    ImplementationLocal.Free;
    InterfaceLocal.Free;
  end;

  procedure AppendSplitter(Lines: TStrings; const FileName: String; SmallSplitter: Boolean);
  begin
    If not SmallSplitter then
      begin
        Lines.Add('{' + StringOfChar('-',79));
        Lines.Add('  ' + FileName);
        Lines.Add(StringOfChar('-',79) + '}');
        Lines.Add('');
      end
    else Lines.Add('  //- ' + FileName + ' ' + StringOfChar('-',73 - Length(FileName)));
  end;

begin
InLines := TStringList.Create;
try
  CreateLocalLists;
  try
    For i := 0 to Pred(fSourceFiles.Count) do
      begin
        InLines.LoadFromFile(StrToRTL(fSourceFiles[i]));
        ClearLocalLists;
        CurrentStage := psInitial;
        For Line := 0 to Pred(InLines.Count) do
          case CurrentStage of
          //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
            psInitial:
              begin
                CurrentTag := GetLineTag(Trim(InLines[Line]));
                case CurrentTag of
                  ptNone:       {do nothing};
                  ptUnitStart:  CurrentStage := psUnit;
                else
                  raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
                end;
              end;
          //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
            psUnit:
              begin
                CurrentTag := GetLineTag(Trim(InLines[Line]));
                case CurrentTag of
                  ptNone:                 {do nothing};
                  ptUnitEnd:              Break{For Line};
                  ptInterfaceStart:       CurrentStage := psInterface;
                  ptImplementationStart:  CurrentStage := psImplementation;
                  ptInitializationStart:  CurrentStage := psInitialization;
                  ptFinalizationStart:    CurrentStage := psFinalization;
                else
                  raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
                end;
              end;
          //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
            psInterface:
              begin
                CurrentTag := GetLineTag(Trim(InLines[Line]));
                case CurrentTag of
                  ptNone:         InterfaceLocal.Add(InLines[Line]);
                  ptInterfaceEnd: CurrentStage := psUnit;
                else
                  raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
                end;
              end;
          //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
            psImplementation:
              begin
                CurrentTag := GetLineTag(Trim(InLines[Line]));
                case CurrentTag of
                  ptNone:               ImplementationLocal.Add(InLines[Line]);
                  ptImplementationEnd:  CurrentStage := psUnit;
                else
                  raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
                end;
              end;
          //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
            psInitialization:
              begin
                CurrentTag := GetLineTag(Trim(InLines[Line]));
                case CurrentTag of
                  ptNone:               InitializationLocal.Add(InLines[Line]);
                  ptInitializationEnd:  CurrentStage := psUnit;
                else
                  raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
                end;
              end;
          //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
            psFinalization:
              begin
                CurrentTag := GetLineTag(Trim(InLines[Line]));
                case CurrentTag of
                  ptNone:             FinalizationLocal.Add(InLines[Line]);
                  ptFinalizationEnd:  CurrentStage := psUnit;
                else
                  raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
                end;
              end;
          //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
          else
            raise TCONDInvalidParsingStage.CreateFmt('TCondenserClass.ParseFile: Invalid parsing stage (%d).',[Ord(CurrentStage)]);
          end;
        // trim the obtained lines
        TrimLines(InterfaceLocal);
        TrimLines(ImplementationLocal);
        TrimLines(InitializationLocal);
        TrimLines(FinalizationLocal);
        // append the lines to global line lists, add splitters if allowed
        If InterfaceLocal.Count > 0 then
          begin
            fCondInterface.Add('');
            If fAddSplitters then
              AppendSplitter(fCondInterface,fSourceFiles[i],False);
            AppendLines(fCondInterface,InterfaceLocal);
          end;
        If ImplementationLocal.Count > 0 then
          begin
            fCondImplementation.Add('');
            If fAddSplitters then
              AppendSplitter(fCondImplementation,fSourceFiles[i],False);
            AppendLines(fCondImplementation,ImplementationLocal);
          end;
        If InitializationLocal.Count > 0 then
          begin
            If fAddSplitters then
              AppendSplitter(fCondInitialization,fSourceFiles[i],True);
            AppendLines(fCondInitialization,InitializationLocal);
          end;
        If FinalizationLocal.Count > 0 then
          begin
            If fAddSplitters then
              AppendSplitter(fCondFinalization,fSourceFiles[i],True);
            AppendLines(fCondFinalization,FinalizationLocal);
          end;
      end;
  finally
    DestroyLocalLists;
  end;
finally
  InLines.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.ConstructOutput(OutLines: TStrings);
var
  Line: Integer;
begin
For Line := 0 to Pred(fOutTemplate.Count) do
  begin
    If AnsiSameText(Trim(fOutTemplate[Line]),COND_TPLTAG_DESCRIPTION) then
      AppendLines(OutLines,fCondDescription)
    else If AnsiSameText(Trim(fOutTemplate[Line]),COND_TPLTAG_UNITNAME) then
      OutLines.Add(Format('unit %s;',[fUnitName]))
    else If AnsiSameText(Trim(fOutTemplate[Line]),COND_TPLTAG_DEFINES) then
      AppendLines(OutLines,fCondDefines)
    else If AnsiSameText(Trim(fOutTemplate[Line]),COND_TPLTAG_INTERFACE) then
      AppendLines(OutLines,fCondInterface)
    else If AnsiSameText(Trim(fOutTemplate[Line]),COND_TPLTAG_IMPLEMENTATION) then
      AppendLines(OutLines,fCondImplementation)
    else If AnsiSameText(Trim(fOutTemplate[Line]),COND_TPLTAG_INITIALIZATION) then
      begin
        If fCondInitialization.Count > 0 then
          begin
            OutLines.Add(''); // spacing (there is always something before this section)
            OutLines.Add('initialization');
            AppendLines(OutLines,fCondInitialization)
          end;
      end
    else If AnsiSameText(Trim(fOutTemplate[Line]),COND_TPLTAG_FINALIZATION) then
      begin
        If fCondFinalization.Count > 0 then
          begin
            OutLines.Add('');
            OutLines.Add('finalization');
            AppendLines(OutLines,fCondFinalization)
          end;
      end
    else OutLines.Add(fOutTemplate[Line]);
  end;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.Initialize;

  Function CheckUnitName(const UnitName: String): Boolean;

    Function CharInSet(C: Char; S: TSysCharSet): Boolean;
    begin
      {$IF SizeOf(Char) <> 1}
      If Ord(C) > 255 then
        Result := False
      else
      {$IFEND}
        Result := AnsiChar(C) in S;
    end;
    
  var
    i:  Integer;
  begin
    Result := False;
    If (Length(UnitName) > 0) and (Length(UnitName) <= 128) then
      If CharInSet(UnitName[1],['a'..'b','A'..'B','_']) then
        For i := 1 to Length(UnitName) do
          If not CharInSet(UnitName[i],['a'..'b','A'..'B','0'..'9','_']) then
            Exit{with result being false};
    Result := True;
  end;

var
  CmdLine:  TSCLPParser;
  CmdData:  TSCLPParameter;
  i:        Integer;
begin
// create lists
fSourceFiles := TStringList.Create;
fOutTemplate := TStringList.Create;
fDefinesFiles := TStringList.Create;
// runtime lists
fCondDescription := TStringList.Create;
fCondDefines := TStringList.Create;
fCondInterface := TStringList.Create;
fCondImplementation := TStringList.Create;
fCondInitialization := TStringList.Create;
fCondFinalization := TStringList.Create;
// init parameters from command line
CmdLine := TSCLPParser.Create;
try
  fCanRun := False;
  If not CmdLine.CommandPresent('h','help') then
    begin
      // load and check mandatory parameters...
      // source files
      If not CmdLine.CommandDataShort('s',CmdData) then
        raise TCONDMissingParameter.Create('TCondenserClass.Initialize: Missing mandatory parameter -s (source files).')
      else If Length(CmdData.Arguments) <= 0 then
        raise TCONDInvalidParameter.Create('TCondenserClass.Initialize: Invalid mandatory parameter -s (no source file).')
      else
        begin
          For i := Low(CmdData.Arguments) to High(CmdData.Arguments) do
            If FileExists(StrToRTL(CmdData.Arguments[i])) then
              fSourceFiles.Add(CmdData.Arguments[i])
            else
              raise TCONDInvalidParameter.CreateFmt('TCondenserClass.Initialize: Source file "%s" does not exist.',[CmdData.Arguments[i]]);
        end;
      // output template file
      If not CmdLine.CommandDataShort('t',CmdData) then
        raise TCONDMissingParameter.Create('TCondenserClass.Initialize: Missing mandatory parameter -t (output template).')
      else If Length(CmdData.Arguments) <> 1 then
        raise TCONDInvalidParameter.CreateFmt('TCondenserClass.Initialize: Invalid mandatory parameter -t (invalid file count (%d)).',[Length(CmdData.Arguments)])
      else If FileExists(StrToRTL(CmdData.Arguments[0])) then
        fOutTemplate.LoadFromFile(StrToRTL(CmdData.Arguments[0]))
      else
        raise TCONDInvalidParameter.CreateFmt('TCondenserClass.Initialize: Template file "%s" does not exist.',[CmdData.Arguments[0]]);
      // output file name
      If not CmdLine.CommandDataShort('o',CmdData) then
        raise TCONDMissingParameter.Create('TCondenserClass.Initialize: Missing mandatory parameter -o (output file name).')
      else If Length(CmdData.Arguments) <> 1 then
        raise TCONDInvalidParameter.CreateFmt('TCondenserClass.Initialize: Invalid mandatory parameter -o (invalid file count (%d)).',[Length(CmdData.Arguments)])
      else
        begin
          fOutFileName := CmdData.Arguments[0];
          fUnitName := RTLToStr(ChangeFileExt(ExtractFileName(StrToRTL(fOutFileName)),''));
          If not CheckUnitName(fUnitName) then
            raise TCONDInvalidParameter.CreateFmt('TCondenserClass.Initialize: Invalid unit name "%s",',[fUnitName]);
        end;
      // load and check optional parameters...
      fAddSplitters := CmdLine.CommandPresentLong('split');
      fDebugRun := CmdLine.CommandPresentLong('debug');
      // defines files
      If CmdLine.CommandDataShort('d',CmdData) then
        begin
          For i := Low(CmdData.Arguments) to High(CmdData.Arguments) do
            If FileExists(StrToRTL(CmdData.Arguments[i])) then
              fDefinesFiles.Add(CmdData.Arguments[i])
            else
              raise TCONDInvalidParameter.CreateFmt('TCondenserClass.Initialize: Defines file "%s" does not exist.',[CmdData.Arguments[i]]);
        end;
      // desription file
      If CmdLine.CommandDataShort('c',CmdData) then
        begin
          If FileExists(StrToRTL(CmdData.Arguments[0])) then
            fDescriptionFile := CmdData.Arguments[0]
          else
            raise TCONDInvalidParameter.CreateFmt('TCondenserClass.Initialize: Description file "%s" does not exist.',[CmdData.Arguments[0]]);
        end
      else fDescriptionFile := '';
      fCanRun := True;
    end;
finally
  CmdLine.Free;
end;  
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.Finalize;
begin
fCondFinalization.Free;
fCondInitialization.Free;
fCondImplementation.Free;
fCondInterface.Free;
fCondDefines.Free;
fCondDescription.Free;
fDefinesFiles.Free;
fOutTemplate.Free;
fSourceFiles.Free;
end;

{-------------------------------------------------------------------------------
    TCondenserClass - public methods
-------------------------------------------------------------------------------}

constructor TCondenserClass.Create;
begin
inherited;
Initialize;
end;

//------------------------------------------------------------------------------

destructor TCondenserClass.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.Run;
var
  Output: TStringList;
begin
// prepare lines lists
fCondDescription.Clear;
fCondDefines.Clear;
fCondInterface.Clear;
fCondImplementation.Clear;
fCondInitialization.Clear;
fCondFinalization.Clear;
// parsing
If Length(fDescriptionFile) > 0 then
  ParseDescriptionFile;
If fDefinesFiles.Count > 0 then
  ParseDefinesFiles;
ParseSourceFiles;
// construct and save the output
Output := TStringList.Create;
try
  ConstructOutput(Output);
  If not fDebugRun then
    Output.SaveToFile(StrToRTL(fOutFileName));
finally
  Output.Free;
end;
end;

end.

