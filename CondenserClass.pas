unit CondenserClass;

{$IFDEF FPC}
  {$MODE ObjFPC}
{$ENDIF}  
{$H+}

interface

uses
  SysUtils, Classes;

type
  TCONDException = class(Exception);

  TCONDInvalidUnitName = class(TCONDException);

  TCONDInvalidParsingStage = class(TCONDException);
  TCONDInvalidParsingTag   = class(TCONDException);

type
  TCondenserClass = class(TObject)
  protected
    // paramters
    fAddSplitters:        Boolean;
    fAddUnitDescription:  Boolean;
    fDebugRun:            Boolean;
    // lists
    fSourceFiles:         TStringList;  // as loaded from resources
    fDefinesFiles:        TStringList;
    fOutTemplate:         TStringList;
    // runtime variables
    fUnitName:            String;
    // runtime lists (condensed lines)
    fCondDescription:     TStringList;
    fCondDefines:         TStringList;
    fCondInterface:       TStringList;
    fCondImplementation:  TStringList;
    fCondInitialization:  TStringList;
    class procedure LoadStringsFromResources(const ResName: String; Strings: TStrings); virtual;
    class Function CheckUnitName(const UnitName: String): Boolean; virtual;
    procedure ParseDefinesFile(Lines: TStrings); virtual;
    procedure ParseFile(const FileName: String; Lines: TStrings; IsFirst: Boolean); virtual;
    procedure ConstructOutput(OutLines: TStrings); virtual;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run(const UnitName: String); virtual;
    property AddSplitters: Boolean read fAddSplitters write fAddSplitters;
    property AddUnitDescription: Boolean read fAddUnitDescription write fAddUnitDescription;
    property DebugRun: Boolean read fDebugRun write fDebugRun;
  end;

implementation

{$R 'Resources\condenser.res'}

Function CharInSet(C: Char; S: TSysCharSet): Boolean;
begin
{$IF SizeOf(Char) <> 1}
If Ord(C) > 255 then
  Result := False
else
{$IFEND}
  Result := AnsiChar(C) in S;
end;

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

procedure AppendLines(ToLines,FromLines: TStrings; Spacing: Boolean);
var
  i:  Integer;
begin
If FromLines.Count > 0 then
  begin
    If Spacing and (ToLines.Count > 0) then
      ToLines.Add('');
    For i := 0 to Pred(FromLines.Count) do
      ToLines.Add(FromLines[i]);
  end;
end;

//------------------------------------------------------------------------------

class procedure TCondenserClass.LoadStringsFromResources(const ResName: String; Strings: TStrings);
var
  ResStream:  TResourceStream;
begin
ResStream := TResourceStream.Create(hInstance,ResName,PChar(10){RT_RCDATA});
try
  ResStream.Seek(0,soBeginning);
  Strings.LoadFromStream(ResStream);
finally
  ResStream.Free;
end;
end;

//------------------------------------------------------------------------------

class Function TCondenserClass.CheckUnitName(const UnitName: String): Boolean;
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

//------------------------------------------------------------------------------

procedure TCondenserClass.ParseDefinesFile(Lines: TStrings);
const
  COND_DEFTAG_BODY_START = '(*<body>*)';
  COND_DEFTAG_BODY_END   = '(*</body>*)';
var
  TempLines:  TStringList;
  Line:       Integer;
  InBody:     Boolean;
begin
TempLines := TStringList.Create;
try
  InBody := False;
  For Line := 0 to Pred(Lines.Count) do
    begin
      If AnsiSameText(Trim(Lines[Line]),COND_DEFTAG_BODY_START) then
        begin
          If not InBody then
            InBody := True
          else
            raise TCONDInvalidParsingTag.Create('TCondenserClass.ParseDefinesFile: Body-start tag is not allowed here.');
        end
      else If AnsiSameText(Trim(Lines[Line]),COND_DEFTAG_BODY_END) then
        begin
          If InBody then
            Inbody := False
          else
            raise TCONDInvalidParsingTag.Create('TCondenserClass.ParseDefinesFile: Body-end tag is not allowed here.');
        end
      else If InBody then
        TempLines.Add(Lines[Line]);
    end;
  TrimLines(TempLines);
  AppendLines(fCondDefines,TempLines,True);
finally
  TempLines.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.ParseFile(const FileName: String; Lines: TStrings; IsFirst: Boolean);
const
  COND_SRCTAG_START_UNIT           = '(*<unit>*)';
  COND_SRCTAG_END_UNIT             = '(*</unit>*)';
  COND_SRCTAG_START_INTERFACE      = '(*<interface>*)';
  COND_SRCTAG_END_INTERFACE        = '(*</interface>*)';
  COND_SRCTAG_START_IMPLEMENTATION = '(*<implementation>*)';
  COND_SRCTAG_END_IMPLEMENTATION   = '(*</implementation>*)';
  COND_SRCTAG_START_INITIALIZATION = '(*<initialization>*)';
  COND_SRCTAG_END_INITIALIZATION   = '(*</initialization>*)';

  BAD_TAG_ERR = 'TCondenserClass.ParseFile: This tag (%d) is not allowed here (%d).';

type
  TCONDParsingStage = (psInitial,psUnit,psInterface,psImplementation,psInitialization);
  TCONDParsingTag = (ptNone,ptUnitStart,ptUnitEnd,ptInterfaceStart,ptInterfaceEnd,
                     ptImplementationStart,ptImplementationEnd,ptInitializationStart,
                     ptInitializationEnd);

  Function GetLineTag(Line: Integer): TCONDParsingTag;
  begin
    If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_START_UNIT) then
      Result := ptUnitStart
    else If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_END_UNIT) then
      Result := ptUnitEnd
    else If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_START_INTERFACE) then
      Result := ptInterfaceStart
    else If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_END_INTERFACE) then
      Result := ptInterfaceEnd
    else If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_START_IMPLEMENTATION) then
      Result := ptImplementationStart
    else If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_END_IMPLEMENTATION) then
      Result := ptImplementationEnd
    else If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_START_INITIALIZATION) then
      Result := ptInitializationStart
    else If AnsiSameText(Trim(Lines[Line]),COND_SRCTAG_END_INITIALIZATION) then
      Result := ptInitializationEnd
    else
      Result := ptNone;
  end;

var
  CurrentStage:         TCONDParsingStage;
  CurrentTag:           TCONDParsingTag;
  Line:                 Integer;
  DescriptionLocal:     TStringList;
  InterfaceLocal:       TStringList;
  ImplementationLocal:  TStringList;
  InitializationLocal:  TStringList;

  procedure InitLocalLists;
  begin
    DescriptionLocal := nil;
    InterfaceLocal := nil;
    ImplementationLocal := nil;
    InitializationLocal := nil;
    DescriptionLocal := TStringList.Create;
    InterfaceLocal := TStringList.Create;
    ImplementationLocal := TStringList.Create;
    InitializationLocal := TStringList.Create;
  end;

  procedure FinalLocalLists;
  begin
    InitializationLocal.Free;
    ImplementationLocal.Free;
    InterfaceLocal.Free;
    DescriptionLocal.Free;
  end;

begin
InitLocalLists;
try
  CurrentStage := psInitial;
  For Line := 0 to Pred(Lines.Count) do
    begin
      case CurrentStage of
      //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        psInitial:
          begin
            CurrentTag := GetLineTag(Line);
            case GetLineTag(Line) of
              ptNone:       If IsFirst then
                              DescriptionLocal.Add(Lines[Line]);
              ptUnitStart:  CurrentStage := psUnit;
            else
              raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
            end;
          end;
      //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        psUnit:
          begin
            CurrentTag := GetLineTag(Line);
            case CurrentTag of
              ptNone:                 {do nothing};
              ptUnitEnd:              Break{For Line};
              ptInterfaceStart:       CurrentStage := psInterface;
              ptImplementationStart:  CurrentStage := psImplementation;
              ptInitializationStart:  CurrentStage := psInitialization;
            else
              raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
            end;
          end;
      //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        psInterface:
          begin
            CurrentTag := GetLineTag(Line);
            case CurrentTag of
              ptNone:         InterfaceLocal.Add(Lines[Line]);
              ptInterfaceEnd: CurrentStage := psUnit;
            else
              raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
            end;
          end;
      //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        psImplementation:
          begin
            CurrentTag := GetLineTag(Line);
            case CurrentTag of
              ptNone:               ImplementationLocal.Add(Lines[Line]);
              ptImplementationEnd:  CurrentStage := psUnit;
            else
              raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
            end;
          end;
      //  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        psInitialization:
          begin
            CurrentTag := GetLineTag(Line);
            case CurrentTag of
              ptNone:               InitializationLocal.Add(Lines[Line]);
              ptInitializationEnd:  CurrentStage := psUnit;
            else
              raise TCONDInvalidParsingTag.CreateFmt(BAD_TAG_ERR,[Ord(CurrentTag),Ord(CurrentStage)]);
            end;
          end;
      else
        raise TCONDInvalidParsingStage.CreateFmt('TCondenserClass.ParseFile: Invalid parsing stage (%d).',[Ord(CurrentStage)]);
      end;
    end;
  TrimLines(DescriptionLocal);
  TrimLines(InterfaceLocal);
  TrimLines(ImplementationLocal);
  TrimLines(InitializationLocal);
  If InterfaceLocal.Count > 0 then
    begin
      If fCondInterface.Count > 0 then
        fCondInterface.Add(''); 
      If fAddSplitters then
        fCondInterface.Add(Format('{%s  %s%s}%s',[StringOfChar('-',79) + sLineBreak,
          FileName,sLineBreak + StringOfChar('-',79),sLineBreak]));
    end;
  If ImplementationLocal.Count > 0 then
    begin
      If fCondImplementation.Count > 0 then
        fCondImplementation.Add('');
      If fAddSplitters then
        fCondImplementation.Add(Format('{%s  %s%s}%s',[StringOfChar('-',79) + sLineBreak,
          FileName,sLineBreak + StringOfChar('-',79),sLineBreak]));
    end;
  If InitializationLocal.Count > 0 then
    fCondInitialization.Add('  //- ' + FileName + ' ' + StringOfChar('-',73 - Length(FileName)));
  If IsFirst then
    fCondDescription.Assign(DescriptionLocal);
  AppendLines(fCondInterface,InterfaceLocal,False);
  AppendLines(fCondImplementation,ImplementationLocal,False);
  AppendLines(fCondInitialization,InitializationLocal,False);
finally
  FinalLocalLists;
end;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.ConstructOutput(OutLines: TStrings);
const
  // template tags
  COND_TPLTAG_DESCRIPTION    = ('<description>');
  COND_TPLTAG_UNITNAME       = ('<unit_name>');
  COND_TPLTAG_DEFINES        = ('<defines>');
  COND_TPLTAG_INTERFACE      = ('<interface>');
  COND_TPLTAG_IMPLEMENTATION = ('<implementation>');
  COND_TPLTAG_INITIALIZATION = ('<initialization>');
var
  Line: Integer;
begin
For Line := 0 to Pred(fOutTemplate.Count) do
  begin
    If AnsiSameText(fOutTemplate[Line],COND_TPLTAG_DESCRIPTION) then
      AppendLines(OutLines,fCondDescription,False)
    else If AnsiSameText(fOutTemplate[Line],COND_TPLTAG_UNITNAME) then
      OutLines.Add(Format('unit %s',[fUnitName]))
    else If AnsiSameText(fOutTemplate[Line],COND_TPLTAG_DEFINES) then
      AppendLines(OutLines,fCondDefines,False)
    else If AnsiSameText(fOutTemplate[Line],COND_TPLTAG_INTERFACE) then
      AppendLines(OutLines,fCondInterface,False)
    else If AnsiSameText(fOutTemplate[Line],COND_TPLTAG_IMPLEMENTATION) then
      AppendLines(OutLines,fCondImplementation,False)
    else If AnsiSameText(fOutTemplate[Line],COND_TPLTAG_INITIALIZATION) then
      AppendLines(OutLines,fCondInitialization,False)
    else
      OutLines.Add(fOutTemplate[Line]);
  end;
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.Initialize;
begin
fAddSplitters := False;
fDebugRun := False;
fSourceFiles := TStringList.Create;
fDefinesFiles := TStringList.Create;
fOutTemplate := TStringList.Create;
fCondDefines := TStringList.Create;
fCondDescription := TStringList.Create;
fCondInterface := TStringList.Create;
fCondImplementation := TStringList.Create;
fCondInitialization := TStringList.Create;
// load stuff from resources
LoadStringsFromResources('source_files',fSourceFiles);
LoadStringsFromResources('defines_files',fDefinesFiles);
LoadStringsFromResources('out_template',fOutTemplate);
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.Finalize;
begin
fCondInitialization.Free;
fCondImplementation.Free;
fCondInterface.Free;
fCondDescription.Free;
fCondDefines.Free;
fOutTemplate.Free;
fDefinesFiles.Free;
fSourceFiles.Free;
end;

//------------------------------------------------------------------------------

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

procedure TCondenserClass.Run(const UnitName: String);
var
  i:      Integer;
  Input:  TStringList;
  Output: TStringList;
begin
If CheckUnitName(UnitName) then
  begin
    fUnitName := UnitName;
    fCondDefines.Clear;    
    fCondDescription.Clear;
    fCondInterface.Clear;
    fCondImplementation.Clear;
    fCondInitialization.Clear;
    Input := TStringList.Create;
    try
      // traverse defines files and join them
      For i := 0 to Pred(fDefinesFiles.Count) do
        begin
          Input.Clear;  // not really needed, but to be sure
          Input.LoadFromFile(fDefinesFiles[i]);
          ParseDefinesFile(Input);
        end;
      // traverse source files, load and parse their content
      For i := 0 to Pred(fSourceFiles.Count) do
        begin
          Input.Clear;
          Input.LoadFromFile(fSourceFiles[i]);
          ParseFile(ExtractFileName(fSourceFiles[i]),Input,i <= 0);
        end;
    finally
      Input.Free;
    end;
    // construct and save the output
    Output := TStringList.Create;
    try
      ConstructOutput(Output);
      If not fDebugRun then
        Output.SaveToFile(UnitName + '.pas');
    finally
      Output.Free;
    end;
  end
else TCONDInvalidUnitName.CreateFmt('TCondenserClass.Run: Invalid unit name "%s".',[UnitName]);
end;

end.

