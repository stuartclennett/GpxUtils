{$SCOPEDENUMS ON}
unit classGPXUtils;

interface

uses
  System.SysUtils;

type
  TGPXFunction = (rename);
  TGPXFunctions = set of TGPXFunction;

  TGPXFileOption = (incDate, incName, incCreator, incOriginalName);
  TGPXFileOptions = set of TGPXFileOption;

  TExceptionProc = reference to procedure(E: Exception);
  TStringProc    = reference to procedure(S : string);

  TGPXFileRenamer = class
  private
    fOptions : TGPXFileOptions;
    function GetIncCreator: boolean;
    function GetIncDate: boolean;
    function GetIncName: boolean;
    function GetIncOriginalName: boolean;
    procedure SetIncCreator(const Value: boolean);
    procedure SetIncDate(const Value: boolean);
    procedure SetIncName(const Value: boolean);
    procedure SetIncOriginalName(const Value: boolean);
  public
    property incDate: boolean read GetIncDate write SetIncDate;
    property incName: boolean read GetIncName write SetIncName;
    property IncCreator: boolean read GetIncCreator write SetIncCreator;
    property IncOriginalName: boolean read GetIncOriginalName write SetIncOriginalName;
    function GetNewName(const aInputFileName: string): string;
    function RenameGPXFile(const aInputFileName: string): string;
  end;

  TGPXFolderRenamer = class
  private
    fPathSpec: string;
  public
    property PathSpec: string read fPathSpec write fPathSpec;
    function Execute(Options: TGPXFileOptions; onLog: TStringProc; onError: TExceptionProc): boolean;
  end;

implementation

uses
  System.IOUtils
  ;

const
  FILE_MASK = '*.gpx';

{ TGPXFolderRenamer }

function TGPXFolderRenamer.Execute(Options: TGPXFileOptions; onLog: TStringProc; onError: TExceptionProc): boolean;
var
  SR : TSearchRec;
  FileRenamer: TGPXFileRenamer;
  aFilename, NewFilename: string;
begin
  // this is where we use the TSearchRec to find all *.gpx files
  try
    FileRenamer := TGPXFileRenamer.Create;
    try
      // hmm, why are these external properties, why can't we pass these in as Options like we do in this method
      FileRenamer.incDate := TGPXFileOption.incDate in Options;
      FileRenamer.incName := TGPXFileOption.incName in Options;
      FileRenamer.IncCreator := TGPXFileOption.incCreator in Options;
      FileRenamer.IncOriginalName := TGPXFileOption.incOriginalName in Options;

      NewFilename := FileRenamer.RenameGPXFile(aFileName);

      // logging
      if assigned(onLog) then
      begin
        if NewFileName = aFileName then
          onLog(Format('%s not renamed', [aFileName]))
        else
          onLog(Format('%s => %s', [aFilename, NewFilename]));
      end;

    finally
      FileRenamer.Free;
    end;
  except
    on e:Exception do
      if assigned(onError) then
        onError(E)
      else
        raise;
  end;
end;

{ TGPXFileRenamer }

function TGPXFileRenamer.GetIncCreator: boolean;
begin
  result := TGPXFileOption.incCreator in fOptions;
end;

function TGPXFileRenamer.GetIncDate: boolean;
begin
  result := TGPXFileOption.incDate in fOptions;
end;

function TGPXFileRenamer.GetIncName: boolean;
begin
  result := TGPXFileOption.incName in fOptions;
end;

function TGPXFileRenamer.GetIncOriginalName: boolean;
begin
  result := TGPXFileOption.incOriginalName in fOptions;
end;

function TGPXFileRenamer.GetNewName(const aInputFileName: string): string;
begin
  // this is where we crack open the file and get the relevant node values
  // and then construct the new filename




end;

function TGPXFileRenamer.RenameGPXFile(const aInputFileName: string): string;
begin
  result := GetNewName(aInputFilename);
  if not RenameFile(aInputFilename, result) then
    result := aInputFilename;
end;

procedure TGPXFileRenamer.SetIncCreator(const Value: boolean);
begin
  if Value then
    Include(fOptions, TGPXFileOption.incCreator)
  else
    Exclude(fOptions, TGPXFileOption.incCreator);
end;

procedure TGPXFileRenamer.SetIncDate(const Value: boolean);
begin
  if Value then
    Include(fOptions, TGPXFileOption.incDate)
  else
    Exclude(fOptions, TGPXFileOption.incDate);

end;

procedure TGPXFileRenamer.SetIncName(const Value: boolean);
begin
  if Value then
    Include(fOptions, TGPXFileOption.incName)
  else
    Exclude(fOptions, TGPXFileOption.incName);
end;

procedure TGPXFileRenamer.SetIncOriginalName(const Value: boolean);
begin
  if Value then
    Include(fOptions, TGPXFileOption.incOriginalName)
  else
    Exclude(fOptions, TGPXFileOption.incOriginalName);
end;

end.
