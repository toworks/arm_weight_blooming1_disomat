unit sql;

interface

uses
   SysUtils, ActiveX, Variants, Classes, StrUtils, DB, ZConnection, ZDataset,
   ZDbcIntfs, ZCompatibility, SyncObjs, logging;

var
    time_ingot, pkdat, num, num_ingot, num_heat, name, weight_ingot, steel_group,
    smena: string;
    MarkerNextWait: boolean = false;


    function SqlNextWeightToRecord: boolean;


type
  TSqlite = class
  private
    FSQuery: TZQuery;
    FSConnect: TZConnection;
    Log: TLog;
    function ConfigSettings(InData: boolean): boolean;
    function SqlJournalMode: boolean;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
    property SConnect: TZConnection read FSConnect write FSConnect;
    property SQuery: TZQuery read FSQuery write FSQuery;
  end;


type
  TFsql = class
  private
    FFQuery: TZQuery;
    FFConnect: TZConnection;
    Log: TLog;
    function ConfigSettings(InData: boolean): boolean;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
    property FConnect: TZConnection read FFConnect write FFConnect;
    property FQuery: TZQuery read FFQuery write FFQuery;
  end;


//    {$DEFINE DEBUG}


implementation


uses
    settings, main;



constructor TSqlite.Create(_Log: TLog);
begin
  inherited Create;
  Log := _Log;
  ConfigSettings(true);
end;


destructor TSqlite.Destroy;
begin
  ConfigSettings(false);
  inherited Destroy;
end;


function TSqlite.ConfigSettings(InData: boolean): boolean;
begin
  if InData then
   begin
      try
        SConnect := TZConnection.Create(nil);
        SQuery := TZQuery.Create(nil);
        SConnect.Database := '.\'+SettingsApp.DBFile;
        SConnect.LibraryLocation := '.\sqlite3.dll';
        SConnect.Protocol := 'sqlite-3';
        SConnect.Connect;
        SQuery.Connection := SConnect;
        SqlJournalMode;
      except
        on E : Exception do
          Log.save('e', E.ClassName+' sqlite config settings, с сообщением: '+E.Message);
      end;
   end
  else
   begin
      SQuery.Destroy;
      SConnect.Destroy;
   end;
end;


function TSqlite.SqlJournalMode: boolean;
begin
  try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('PRAGMA journal_mode');
      SQuery.Open;
  except
    on E: Exception do
      Log.save('e', E.ClassName + ' sql get journal_mode, с сообщением: ' + E.Message);
  end;

  if SQuery.FieldByName('journal_mode').AsString <> 'wal' then
  begin
    try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('PRAGMA journal_mode = wal');
      SQuery.ExecSQL;
    except
      on E: Exception do
        Log.save('e', E.ClassName + ' sql set journal_mode wal, с сообщением: ' + E.Message);
    end;
  end;
end;


constructor TFsql.Create(_Log: TLog);
begin
  inherited Create;
  Log := _Log;
  ConfigSettings(true);
end;


destructor TFsql.Destroy;
begin
  ConfigSettings(false);
  inherited Destroy;
end;


function TFsql.ConfigSettings(InData: boolean): boolean;
begin
  if InData then
  begin
      try
        FFConnect := TZConnection.Create(nil);
        FFQuery := TZQuery.Create(nil);
        FFConnect.LibraryLocation := '.\fbclient.dll';// отказался от полных путей не читает
        FFConnect.Protocol := 'firebird-2.5';
        FFConnect.Database := FbSqlSettings.db_name;
        FFConnect.HostName := FbSqlSettings.ip;
        FFConnect.User := FbSqlSettings.user;
        FFConnect.Password := FbSqlSettings.password;
        FFConnect.ReadOnly := True;
        FFConnect.LoginPrompt := false;
        FFConnect.Port := 3050;
        FFConnect.AutoCommit := False;
        FFConnect.TransactIsolationLevel := tiReadCommitted;
        with FFConnect.Properties do
        begin
             Add('Dialect=3');
             Add('isc_tpb_read_committed');
             Add('isc_tpb_concurrency');              // Needed for multiuser environments
             Add('isc_tpb_nowait');                   // Needed for multiuser environments
             Add('timeout=3');
             Add('codepage=win1251');
//             Add('codepage=NONE');
//             Add('controls_cp=CP_UTF8');
//             Add('AutoEncodeStrings=ON');
//             Add('codepage=win1251');
//             Add('client_encoding=UTF8');
        end;
        FFConnect.Connect;
        FFQuery.Connection := FFConnect;
      except
        on E: Exception do begin
          Log.save('e', E.ClassName+', с сообщением: '+E.Message);
        end;
      end;
  end
  else
  begin
        FreeAndNil(FFQuery);
        FreeAndNil(FFConnect);
  end;
end;


function SqlNextWeightToRecord: boolean;
var
  _FSql: TFsql;
  i: integer;
begin

  try
      _FSql := TFsql.Create(Log);
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql create _FSql, с сообщением: '+E.Message);
  end;

  if ( pkdat = '') then
     exit;

  try
      _FSql.FQuery.Close;
      _FSql.FQuery.SQL.Clear;
      _FSql.FQuery.SQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group , sh.smena');
      _FSql.FQuery.SQL.Add('from ingots i, heats h, steels s, shifts sh');
      _FSql.FQuery.SQL.Add('where ((i.pkdat='+ pkdat +'');
      _FSql.FQuery.SQL.Add('and (i.num='+ num +'');
      _FSql.FQuery.SQL.Add('and i.num_ingot>'+ num_ingot +'');
      _FSql.FQuery.SQL.Add('or i.num>'+ num +'))');
      _FSql.FQuery.SQL.Add('or i.pkdat>'+ pkdat +')');
      _FSql.FQuery.SQL.Add('and i.pkdat=h.pkdat and i.num=h.num');
      _FSql.FQuery.SQL.Add('and i.pkdat=sh.pkdat');
      _FSql.FQuery.SQL.Add('and h.steel_grade=s.steel_grade');
      _FSql.FQuery.SQL.Add('order by i.pkdat asc, i.num asc, i.num_ingot asc');
      _FSql.FQuery.Open;
  {$IFDEF DEBUG}
    Log.save('d', 'FQueryNextRecord -> '+_FSql.FQuery.SQL.Text);
  {$ENDIF}
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql read next weight to record, с сообщением: '+E.Message);
  end;

  {$IFDEF DEBUG}
    Log.save('d', 'pkdat empty? -> '+_FSql.FQuery.FieldByName('pkdat').AsString);
  {$ENDIF}

  try
      // маркер следующей заготовки (ожидание)
      if _FSql.FQuery.FieldByName('pkdat').AsString = '' then
      begin
//          form1.SqlMax := 0;
//          form1.l_n_message.Visible := true;
//          form1.l_n_message.Font.Color := $002CB902;//green
//          form1.l_n_message.Caption := ' Ожидание сдедующей заготовки ';
          MarkerNextWait := true;

          EnableViewSelectedIngot(false);
          FreeAndNil(_FSql);
          exit;
      end
      else
      begin
//          form1.l_n_message.Visible := false;
//          MarkerNextWait := false;
          ThreadComPort.NextSave := true;
          EnableViewSelectedIngot(true);
      end;
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql 3, с сообщением: '+E.Message);
  end;

  i:=0;

  try
      while not _FSql.FQuery.Eof do
      begin
          if i = 1 then
            break;

          pkdat := _FSql.FQuery.FieldByName('pkdat').AsString;
          num := _FSql.FQuery.FieldByName('num').AsString;
          num_ingot := _FSql.FQuery.FieldByName('num_ingot').AsString;
          time_ingot := timetostr(_FSql.FQuery.FieldByName('time_ingot').AsDateTime);
          num_heat := _FSql.FQuery.FieldByName('num_heat').AsString;
          name := _FSql.FQuery.FieldByName('name').AsString;
          weight_ingot := _FSql.FQuery.FieldByName('weight_ingot').AsString;
          smena := _FSql.FQuery.FieldByName('smena').AsString;

          Form1.l_number_ingot.Caption := num_ingot;
          Form1.l_datetime.Caption := time_ingot;
          Form1.l_heat.Caption := num_heat;
          Form1.l_grade.Caption := name;
          Form1.l_weight_ingot.Caption := weight_ingot;

          // перезаписываем данные что бы при выборе не проскакивала выбранная запись
          ThreadComPort.Apkdat := pkdat;
          ThreadComPort.Anum := num;
          ThreadComPort.Anum_ingot := num_ingot;
          //-- test
//          Form1.l_next_id.Caption := pkdat+'|'+num+'|'+num_ingot;

          inc(i);
          _FSql.FQuery.Next;
      end;
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql set pkdat | num | num_ingot, с сообщением: '+E.Message);
  end;
  FreeAndNil(_FSql);
end;







end.
