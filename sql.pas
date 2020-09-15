unit sql;

interface

uses
   SysUtils, ActiveX, Variants, Classes, StrUtils, Data.DB, ZConnection, ZDataset,
   ZDbcIntfs, SyncObjs, logging;

var
    time_ingot, pkdat, num, num_ingot, num_heat, name, weight_ingot, steel_group,
    smena: string;
    MarkerNextWait: boolean = false;


//    {$DEFINE DEBUG}


//    function ConfigFirebirdSetting(InData: boolean): boolean;
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
          Log.save('e', E.ClassName+' sqlite config settings, � ����������: '+E.Message);
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
      Log.save('e', E.ClassName + ' sql get journal_mode, � ����������: ' + E.Message);
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
        Log.save('e', E.ClassName + ' sql set journal_mode wal, � ����������: ' + E.Message);
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
        FFConnect.LibraryLocation := '.\fbclient.dll';// ��������� �� ������ ����� �� ������
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
          Log.save('e', E.ClassName+', � ����������: '+E.Message);
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
  _SSql: TZQuery;
  _FSql: TFsql;
  i: integer;
begin

  try
      _FSql := TFsql.Create(Log);
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql create _FSql, � ����������: '+E.Message);
  end;

  i:=0;

  try
      _SSql := TZQuery.Create(nil);
      _SSql.Connection := MainSqlite.SConnect;
      _SSql.Close;
      _SSql.SQL.Clear;
      _SSql.SQL.Add('SELECT pkdat, num, num_ingot FROM weight');
      _SSql.SQL.Add('order by id desc limit 1');
      _SSql.Open;
  except
    on E : Exception do begin
      Log.save('e', E.ClassName+' sql next weight to record, � ����������: '+E.Message);
      exit;
    end;
  end;

  try
      _FSql.FQuery.Close;
      _FSql.FQuery.SQL.Clear;
      _FSql.FQuery.SQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group , sh.smena');
      _FSql.FQuery.SQL.Add('from ingots i, heats h, steels s, shifts sh');
      _FSql.FQuery.SQL.Add('where ((i.pkdat='+ _SSql.FieldByName('pkdat').AsString +'');
      _FSql.FQuery.SQL.Add('and (i.num='+ _SSql.FieldByName('num').AsString +'');
      _FSql.FQuery.SQL.Add('and i.num_ingot>'+ _SSql.FieldByName('num_ingot').AsString +'');
      _FSql.FQuery.SQL.Add('or i.num>'+ _SSql.FieldByName('num').AsString +'))');
      _FSql.FQuery.SQL.Add('or i.pkdat>'+ _SSql.FieldByName('pkdat').AsString +')');
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
      Log.save('e', E.ClassName+' sql read next weight to record, � ����������: '+E.Message);
  end;

  {$IFDEF DEBUG}
    Log.save('d', 'pkdat empty? -> '+_FSql.FQuery.FieldByName('pkdat').AsString);
  {$ENDIF}

  try
      // ������ ��������� ��������� (��������)
      if _FSql.FQuery.FieldByName('pkdat').AsString = '' then
      begin
          form1.SqlMax := 0;
          form1.l_n_message.Visible := true;
          form1.l_n_message.Font.Color := $002CB902;//green
          form1.l_n_message.Caption := ' �������� ��������� ��������� ';
          MarkerNextWait := true;

          form1.l_weight_ingot.Visible := false;
          form1.l_grade.Visible := false;
          form1.l_heat.Visible := false;
          form1.l_datetime.Visible := false;
          form1.l_number_ingot.Visible := false;
          FreeAndNil(_FSql);
          exit;
      end
      else
      begin
          form1.l_n_message.Visible := false;
          MarkerNextWait := false;
          form1.l_weight_ingot.Visible := true;
          form1.l_grade.Visible := true;
          form1.l_heat.Visible := true;
          form1.l_datetime.Visible := true;
          form1.l_number_ingot.Visible := true;
      end;
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql 3, � ����������: '+E.Message);
  end;

  try
      while not MainFSql.FQuery.Eof do
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

          //-- test
          Form1.l_next_id.Caption:=pkdat+'|'+num+'|'+num_ingot;

          inc(i);
          _FSql.FQuery.Next;
      end;
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql 4, � ����������: '+E.Message);
  end;
  FreeAndNil(_FSql);
end;







end.
