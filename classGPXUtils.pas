{$SCOPEDENUMS ON}
unit classGPXUtils;

interface

uses
  System.SysUtils;

type
  TStringNotifyEvent = procedure (Sender: TObject; aMessage: string);

  TGPXFunction = (rename);
  TGPXFunctions = set of TGPXFunction;

  TGPXFileOption = (incDate, incName, incCreator, incOriginalName);
  TGPXFileOptions = set of TGPXFileOption;

  TExceptionProc = reference to procedure(E: Exception);
  TStringProc    = reference to procedure(S : string);

  TGPXFileRenamer = class
  private
    fOptions : TGPXFileOptions;
    fOnMessage: TStringNotifyEvent;
    fCreator: string;
    fActivityName: string;
    fActivityDate: TDateTime;
    fTargetFolder: string;
    function GetIncCreator: boolean;
    function GetIncDate: boolean;
    function GetIncName: boolean;
    function GetIncOriginalName: boolean;
    procedure SetIncCreator(const Value: boolean);
    procedure SetIncDate(const Value: boolean);
    procedure SetIncName(const Value: boolean);
    procedure SetIncOriginalName(const Value: boolean);
  public
    property TargetFolder: string read fTargetFolder write fTargetFolder;
    property OnMessage: TStringNotifyEvent read fOnMessage write fOnMessage;
    property Options: TGPXFileOptions read fOptions write fOptions;
    property incDate: boolean read GetIncDate write SetIncDate;
    property incName: boolean read GetIncName write SetIncName;
    property IncCreator: boolean read GetIncCreator write SetIncCreator;
    property IncOriginalName: boolean read GetIncOriginalName write SetIncOriginalName;
    function GetNewName(const aInputFileName: string; const aTargetFolder: string): string;
    function RenameGPXFile(const aInputFileName: string; const aTargetFolder: string): string;
    function CopyGPXFile(const aInputFileName: string; const aTargetFolder: string; Options: TGPXFileOptions): boolean;
    property ActivityDate: TDateTime read fActivityDate;
    property ActivityName: string read fActivityName;
    property Creator: string read fCreator;
  end;

  TGPXFolderRenamer = class
  private
    fFolderPath: string;
  public
    property FolderPath: string read fFolderPath write fFolderPath;
    function Execute(aFolderPath: string; const aTargetFolderPath: string; Options: TGPXFileOptions; onLog: TStringProc; onError: TExceptionProc; OnMessage: TStringNotifyEvent): boolean;
  end;

implementation

uses
  System.IOUtils,
  OmniXML,
  OmniXMLUtils, System.DateUtils
  ;

const
  FILE_MASK = '*.gpx';
  CHAR_SEP  = '_';

{ TGPXFolderRenamer }

function TGPXFolderRenamer.Execute(aFolderPath: string; const aTargetFolderPath: string; Options: TGPXFileOptions; onLog: TStringProc; onError: TExceptionProc; OnMessage: TStringNotifyEvent): boolean;
var
  R : Integer;
  SR : TSearchRec;
  FileRenamer: TGPXFileRenamer;
  aFilename, NewFilename, aTargetFolder: string;
begin
  try
    if aFolderPath <> EmptyStr then
      fFolderPath := aFolderPath;
    if aTargetFolderPath <> EmptyStr then
      aTargetFolder := aTargetFolderPath
    else
      aTargetFolder := fFolderPath;

    if not TDirectory.Exists(fFolderPath) then EXIT(False);

    FileRenamer := TGPXFileRenamer.Create;
    try
      FileRenamer.Options := Options;
      FileRenamer.OnMessage := OnMessage;
      R := System.SysUtils.FindFirst(TPath.Combine(fFolderPath, '*.gpx'), faAnyFile, SR);
      try
        if R = 0 then
        repeat
          aFilename := TPath.Combine(fFolderPath, SR.Name);

          NewFilename := FileRenamer.RenameGPXFile(aFileName, aTargetFolder);

          // logging
          if assigned(onLog) then
          begin
            if NewFileName = aFileName then
              onLog(Format('%s not renamed', [aFileName]))
            else
              onLog(Format('%s => %s', [aFilename, NewFilename]));
          end;

        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
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

function TGPXFileRenamer.CopyGPXFile(const aInputFileName: string; const aTargetFolder: string; Options: TGPXFileOptions): boolean;
var
  aNewName: string;
begin
  aNewName := GetNewName(aInputFilename, aTargetFolder);
  if aNewName <> aInputFileName then
  begin
    TFile.Copy(aInputFileName, aNewName);
    // set the date of the file to the date of the activity
    if (TGPXFileOption.incDate in fOptions) then
      FileSetDate(aNewName, DateTimeToFileDate(fActivityDate));
    result := TRUE;
  end else
    result := FALSE;
end;

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

function TGPXFileRenamer.GetNewName(const aInputFileName: string; const aTargetFolder: string): string;
var
  xmlDoc: IXMLDocument;
  Root: IXMLElement;
  Creator: IXMLAttr;
  Meta, Time, Trk, aName: IXMLNode;
  HasTime, HasName, HasCreator: boolean;
begin
  try
    result := aInputFileName;
    HasTime := false;
    HasName := false;
    HasCreator := false;
    fTargetFolder := aTargetFolder;
    if fTargetFolder = EmptyStr then
      fTargetFolder := TPath.GetDirectoryName(aInputFilename);
    fCreator := '';
    fActivityDate := FileDateToDateTime(FileAge(aInputFileName));
    fActivityName := '';
    result := '';

    // this is where we crack open the file and get the relevant node values
    // and then construct the new filename
    xmlDoc := CreateXMLDoc;
    try
      xmlDoc.Load(aInputFilename);

      if not assigned(xmlDoc.DocumentElement) then
        raise Exception.Create('XML document is empty');

      if not assigned(xmlDoc.DocumentElement) then
        raise Exception.Create('XML document is empty');

      if assigned(fOnMessage) then
        fOnMessage(Self, 'Root tag: ' + xmlDoc.DocumentElement.NodeName);

      Root := xmlDoc.DocumentElement;
      Creator := Root.GetAttributeNode('creator');
      if assigned(Creator) then
      begin
        if assigned(fOnMessage) then
          fOnMessage(self, 'Creator = ' + Creator.Value);
        HasCreator := True;
      end;

      Meta := Root.SelectSingleNode('metadata');
      if assigned(Meta) then
      begin

        Time := Meta.SelectSingleNode('time');
        if assigned(Time) then
        begin
          HasTime := True;
          if assigned(fOnMessage) then
            fOnMessage(self, Time.NodeName + ' = ' + Time.Text.ToLower + ' (' + Time.XML + ')');

        end else
        if assigned(fOnMessage) then
          fOnMessage(self, 'Time node not found');
      end else
      if assigned(fOnMessage) then
        fOnMessage(self, 'Metadata node not found');

      Trk := Root.SelectSingleNode('trk');
      if assigned(Trk) then
      begin

        aName := Trk.SelectSingleNode('name');
        if assigned(aName) then
        begin
          HasName := True;
          if assigned(fOnMessage) then
            fOnMessage(self, aName.NodeName + ' = ' + aName.Text + ' (' + aName.XML + ')');
        end else
        if assigned(fOnMessage) then
          fOnMessage(Self, 'Name node not found');

      end else
      if assigned(fOnMessage) then
        fOnMessage(Self, 'Trk not found');
    finally
      xmlDoc := nil;
    end;

    if HasTime and (TGPXFileOption.incDate in FOptions) then
    begin
      result := result + Time.Text.ToLower;
      fActivityDate := ISO8601ToDate(Time.text);
    end;

    if HasName and (TGPXFileOption.incName in fOptions) then
    begin
      fActivityName := aName.Text;
      if result <> EmptyStr then
        result := result + CHAR_SEP;
      result := result + aName.Text;
    end;

    if HasCreator and (TGPXFileOption.incCreator in fOptions) then
    begin
      fCreator := Creator.Value;
      if result <> EmptyStr then
        result := result + CHAR_SEP;
      result := result + Creator.Value;
    end;

    if (TGPXFileOption.incOriginalName in fOptions) then
    begin
      if result <> EmptyStr then
        result := result + CHAR_SEP;
      result := result + TPath.GetFileNameWithoutExtension(aInputFileName); // is Strava's activity ID I think
    end;

    // add the path and the .gpx extension


    result := TPath.Combine(fTargetFolder, TPath.ChangeExtension(result, '.gpx'));

    if assigned(fOnMessage) then
      fOnMessage(self, 'New Filename = ' + result);

  except
    on e:Exception do
    begin
      result := aInputFileName;
      if assigned(fOnMessage) then
        fOnMessage(self, Format('Error %s getting new name for %s', [e.Message, aInputFileName]));
    end;

  end;
end;

function TGPXFileRenamer.RenameGPXFile(const aInputFileName: string; const aTargetFolder: string): string;
begin
  result := GetNewName(aInputFilename, aTargetFolder);
  if not RenameFile(aInputFilename, result) then
    result := aInputFilename;
  // set the date of the file to the date of the activity
  if (TGPXFileOption.incDate in fOptions) then
    FileSetDate(result, DateTimeToFileDate(fActivityDate));
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
