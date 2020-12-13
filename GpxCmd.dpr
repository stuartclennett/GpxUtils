{$SCOPEDENUMS ON}
program GpxCmd;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  FunctionsCommandLine in '..\SharedCode\FunctionsCommandLine.pas',
  classGPXUtils in 'classGPXUtils.pas';

procedure WriteHelp;
begin
  WriteLn('Usage');
  WriteLn('-----');
  WriteLn('To rename a folder of GPX files /f<pathspec>');
  WriteLn('To specify rename options:');
  WriteLn('  /id - include activity date (on by default)');
  WriteLn('  /in - include activity name (on by default)');
  WriteLn('  /ic - include creator app (off by default)');
  WriteLn('  /io - include original filename (off by default). For Strava this is the activty reference.');
  WriteLn('');
  WriteLn('e.g.  GpxCmd /fD:\GPXFiles /id /in /io');
end;

procedure HandleError(const E:Exception);
begin
  writeLn(E.Message);
end;

var
  L : Integer;
  Flag : string;
  Param: string;
  functions: TGPXFunctions;
  FolderName: string;
  fRenameOptions: TGPXFileOptions;
  Renamer: TGPXFolderRenamer;
  res: boolean;
begin
  try
    WriteLn('GPX Utils');
    WriteLn('');
    if GetParamCount = 0 then
      WriteHelp
    else
    begin
      // default set of options if nothing specified
      fRenameOptions := [];
      for L := 0 to GetParamCount do
      begin
        Param := GetParamStr(L);
        if (Param <> EmptyStr) and (Copy(Param, 1, 1) = '/') then
        begin
          Flag := Copy(Param, 2, 1);  // e.g. "F"
          Param := Copy(Param, 3, Length(Param));

          if SameText(Flag, 'F') then
          begin
            Include(Functions, TGPXFunction.rename);
            FolderName := Param;
          end;

          if SameText(Flag, 'i') then
          begin
            if SameText(Param,'d') then
              include(fRenameOptions, TGPXFileOption.incDate);
            if SameText(Param,'n') then
              include(fRenameOptions, TGPXFileOption.incName);
            if SameText(Param,'c') then
              include(fRenameOptions, TGPXFileOption.incCreator);
            if SameText(Param,'o') then
              include(fRenameOptions, TGPXFileOption.incOriginalName);
          end;

        end;
      end;
      // Do Work

      if (TGPXFunction.rename in Functions) then
      begin
        if fRenameOptions = [] then
          fRenameOptions := [TGPXFileOption.incDate, TGPXFileOption.incName];
        WriteLn('Folder rename option specified for');
        WriteLn(FolderName);

        Renamer := TGPXFolderRenamer.Create;
        try
          Renamer.PathSpec := FolderName;

          res := Renamer.Execute(fRenameOptions,

            procedure(S: string)
            begin
              WriteLn(S);
            end,

            procedure(E: Exception)
            begin
              WriteLn(E.Message);
            end

          );
          if res then
            WriteLn(Format('All files in %s renamed', [Renamer.PathSpec]))
          else
            WriteLn('Folder Rename was unsuccessful');

        finally
          Renamer.free;
        end;


      end;

    end;
    readLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
