unit CondenserClass;

{$IFDEF FPC}
  {$MODE ObjFPC}
{$ENDIF}
{$H+}

interface

uses
  Classes;

type
  TCondenserClass = class(TObject)
  protected
    // paramters
    fAddSplitters:        Boolean;
    fDebugRun:            Boolean;
    // lists
    fHeaderFiles:         TStringList;  // as loaded from resources
    fOutTemplate:         TStringList;
    // runtime lists (condensed lines)
    fCondInterface:       TStringList;
    fCondImplementation:  TStringList;
    fCondInitializetion:  TStringList;
    class procedure LoadStringsFromResources(const ResName: String; Strings: TStrings); virtual;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run; virtual;
    property AddSplitters: Boolean read fAddSplitters write fAddSplitters;
    property DebugRun: Boolean read fDebugRun write fDebugRun;
  end;

implementation

{$R 'Resources\condenser.res'}

const
  COND_TAG_START_INTERFACE      = '(*<interface>*)';
  COND_TAG_END_INTERFACE        = '(*</interface>*)';
  COND_TAG_START_IMPLEMENTATION = '(*<implementation>*)';
  COND_TAG_END_IMPLEMENTATION   = '(*</implementation>*)';
  COND_TAG_START_INITIALIZATION = '(*<initialization>*)';
  COND_TAG_END_INITIALIZATION   = '(*</initialization>*)';
  // finalization is not used anywhere atm.

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

procedure TCondenserClass.Initialize;
begin
fAddSplitters := False;
fDebugRun := False;
fHeaderFiles := TStringList.Create;
fOutTemplate := TStringList.Create;
fCondInterface := TStringList.Create;
fCondImplementation := TStringList.Create;
fCondInitializetion := TStringList.Create;
// load stuff from resources
LoadStringsFromResources('header_files',fHeaderFiles);
LoadStringsFromResources('out_template',fOutTemplate);
end;

//------------------------------------------------------------------------------

procedure TCondenserClass.Finalize;
begin
fCondInitializetion.Free;
fCondImplementation.Free;
fCondInterface.Free;
fOutTemplate.Free;
fHeaderFiles.Free;
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

procedure TCondenserClass.Run;
begin
end;

end.
