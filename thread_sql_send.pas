unit thread_sql_send;


interface

uses
  SysUtils, Classes, Data.DB, ActiveX, ZConnection, ZDataset, ZDbcIntfs,
  logging;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSqlSend = class(TThread)
  private
    FThreadSqlSend: TThreadSqlSend;
//    FOraConnect: TZConnection;
//    FOraQuery: TZQuery;
    FSqlMaxLocal: Int64;

    function ConfigOracleSetting(InData: boolean): boolean;
    function ConfigSqliteSetting: boolean;
    procedure SqlSend;
    function SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): boolean;
    procedure SqlReadTableLocal;
    function GetMaxLocalCount: boolean;

  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
    procedure SyncSqlMaxLocal;
  end;

var
  Log: TLog;
  FOraConnect: TZConnection;
  FOraQuery: TZQuery;

//  {$DEFINE DEBUG}


implementation

uses
  settings, sql, main;




//constructor TThreadSqlSend.Create;
constructor TThreadSqlSend.Create(_Log: TLog);
begin
  inherited Create(True);
  Log := _Log;

  // ������� ����� True - �������� ���������, False - �������� �����
  FThreadSqlSend := TThreadSqlSend.Create(True);
  FThreadSqlSend.Priority := tpNormal;
  FThreadSqlSend.FreeOnTerminate := True;

  FSqlMaxLocal := 0;

  ConfigOracleSetting(true);

  ConfigSqliteSetting;
  FThreadSqlSend.Start;
end;


destructor TThreadSqlSend.Destroy;
begin
  if FThreadSqlSend <> nil then begin
    ConfigOracleSetting(false);
    FThreadSqlSend.Terminate;
  end;
  inherited Destroy;
end;


//-- start main
function TThreadSqlSend.ConfigSqliteSetting: boolean;
begin
  try
      SLQuery := TZQuery.Create(nil);
      SLQuery.Connection := SettingsApp.SConnect;

      SLDataSource := TDataSource.Create(nil);
      SLDataSource.DataSet := SLQuery;

  except
      on E : Exception do
        Log.save('e', E.ClassName+'1, � ����������: '+E.Message);
  end;
end;
//-- end main


function TThreadSqlSend.ConfigOracleSetting(InData: boolean): boolean;
var
  ConnectString : String;
begin
  if InData then
  begin
      try
        FOraConnect := TZConnection.Create(nil);
        FOraQuery := TZQuery.Create(nil);
        ConnectString:='(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = '
                +OraSqlSettings.ip+')(PORT = '+'1521'
                +'))) (CONNECT_DATA = (SERVICE_NAME = '+
                OraSqlSettings.db_name+')))';
        FOraConnect.Database := ConnectString;
        FOraConnect.LibraryLocation := '.\oci.dll';// ��������� �� ������ ����� �� ������
        FOraConnect.Protocol := 'oracle';
        FOraConnect.User := OraSqlSettings.user;
        FOraConnect.Password := OraSqlSettings.password;
        FOraConnect.ClientCodepage := 'CL8MSWIN1251';
        FOraConnect.Connect;
        FOraQuery.Connection := FOraConnect;
      except
        on E: Exception do begin
          Log.save('e', E.ClassName+', � ����������: '+E.Message);
        end;
      end;
  end
  else
  begin
        FreeAndNil(FOraQuery);
        FreeAndNil(FOraConnect);
  end;

end;


procedure TThreadSqlSend.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      try
          SqlSend;
          GetMaxLocalCount;
          Synchronize(SyncSqlMaxLocal);
      except
        on E : Exception do
          Log.save('e', E.ClassName+'3, � ����������: '+E.Message);
      end;

      sleep(1000);
   end;
   CoUninitialize;
end;


procedure TThreadSqlSend.SqlSend;
var
  _SQuery: TZQuery;
  i: integer;
  Byffer: array of array of AnsiString;
  send_error: boolean;
begin

  try
      _SQuery := TZQuery.Create(nil);
  if assigned(_SQuery) then
    log.save('d', 'assigned(_SQuery)')
  else
    log.save('d', 'not assigned(_SQuery)');

      _SQuery.Connection := SettingsApp.SConnect;
      _SQuery.Close;
      _SQuery.SQL.Clear;
      _SQuery.SQL.Add('SELECT id_asutp, weight,');
      _SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'' ) as timestamp');
      _SQuery.SQL.Add('FROM weight');
      _SQuery.SQL.Add('where transferred=0');
      _SQuery.SQL.Add('order by id asc limit 10'); //�������� �� 10 ��
      _SQuery.Open;
   except
    on E : Exception do
      Log.save('e', E.ClassName+' sql send select, � ����������: '+E.Message);
  end;

      i := 0;
   try
      while not _SQuery.Eof do
      begin
          if i = Length(Byffer) then SetLength(Byffer, i+1, 3);
          Byffer[i,0] := _SQuery.FieldByName('id_asutp').AsString;
          Byffer[i,1] := _SQuery.FieldByName('weight').AsString;
          Byffer[i,2] := _SQuery.FieldByName('timestamp').AsString;
          inc(i);
          _SQuery.Next;
      end;

  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql send buffer, � ����������: '+E.Message);
  end;

  for i := Low(Byffer) to High(Byffer) do
  begin
  {$IFDEF DEBUG}
    Log.save('d', 'id_asutp | '+Byffer[i,0]);
    Log.save('d', 'weight | '+Byffer[i,1]);
    Log.save('d', 'timestamp | '+Byffer[i,2]);
  {$ENDIF}
      try
//        send_error := SqlSaveToOracle(Byffer[i,0], Byffer[i,1], Byffer[i,2]);
        if Byffer[i,0] <> '' then
          send_error := SqlSaveToOracle(Byffer[i,0], Byffer[i,1], Byffer[i,2]);
//  {$IFDEF DEBUG}
    Log.save('d', 'send_error | '+booltostr(send_error));
//  {$ENDIF}
        if not send_error then begin
            _SQuery.Close;
            _SQuery.SQL.Clear;
            _SQuery.SQL.Add('UPDATE weight SET transferred=1');
            _SQuery.SQL.Add('where id_asutp='+Byffer[i,0]+'');
            _SQuery.ExecSQL;
            //save to Log file
            {Log.save('sql'+#9#9+'write'+#9+'id_asutp -> '+Byffer[i,0]);
            Log.save('sql'+#9#9+'write'+#9+'weight -> '+Byffer[i,1]);
            Log.save('sql'+#9#9+'write'+#9+'timestamp -> '+Byffer[i,2]);}

{            cs.Enter;
              Synchronize(SqlReadTableLocal);//views ���������� ���������
            cs.Leave;}

            //������� ������ ������ ������ 3� ����
            _SQuery.Close;
            _SQuery.SQL.Clear;
            _SQuery.SQL.Add('delete from weight');
            _SQuery.SQL.Add('where timestamp < strftime(''%s'', ''now'') - (86400*3)');
            _SQuery.ExecSQL;
        end;
      except
        on E : Exception do
          Log.save('e', E.ClassName+' sql send update, � ����������: '+E.Message);
      end;
  end;
  FreeAndNil(_SQuery);
end;


function TThreadSqlSend.SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): boolean;
var
  error: boolean;
begin
  error := false;

  try
    //���� �������: EZSQLException, � ����������: SQL Error: OCI_NO_DATA
    if not FOraConnect.Connected then
      FOraConnect.Reconnect;

    FOraQuery.Close;
    FOraQuery.SQL.Clear;
    FOraQuery.SQL.Add('INSERT INTO crop');
    FOraQuery.SQL.Add('(id_asutp, weight_bloom, date_weight_bloom)');
    FOraQuery.SQL.Add('VALUES ('+IdIn+', '+PointReplace(WeightIn)+',');
    FOraQuery.SQL.Add('TO_DATE('''+TimestampIn+''', ''yyyy-mm-dd hh24:mi:ss''))');
    FOraQuery.ExecSQL;
  {$IFDEF DEBUG}
    Log.save('d', 'OraQuery insert | '+FOraQuery.SQL.Text);
  {$ENDIF}
  except
    on E : Exception do begin
      error := true;
      Log.save('e', E.ClassName+'6, � ����������: '+E.Message+' | '+FOraQuery.SQL.Text);
    end;
  end;

  if error then
  begin
    try
        FOraQuery.Close;
        FOraQuery.SQL.Clear;
        FOraQuery.SQL.Add('update crop');
        FOraQuery.SQL.Add('set weight_bloom = '+PointReplace(WeightIn)+',');
        FOraQuery.SQL.Add('date_weight_bloom = TO_DATE('''+TimestampIn+''',');
        FOraQuery.SQL.Add('''yyyy-mm-dd hh24:mi:ss'')');
        FOraQuery.SQL.Add('where id_asutp = '+IdIn+'');
        FOraQuery.ExecSQL;

        error := false;
  {$IFDEF DEBUG}
    Log.save('d', 'OraQuery update | '+OraQuery.SQL.Text);
  {$ENDIF}
    except
      on E : Exception do begin
        error := true;
        Log.save('e', E.ClassName+'7, � ����������: '+E.Message+' | '+FOraQuery.SQL.Text);
      end;
    end;
  end;

  Result := error;

end;


//-- start main
procedure TThreadSqlSend.SqlReadTableLocal;
begin
  try
      SLQuery.Close;
      SLQuery.SQL.Clear;
      SLQuery.SQL.Add('SELECT substr(pkdat,7,1) as shift, num_ingot,');
      SLQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'' ) as timestamp,');
      SLQuery.SQL.Add('heat, weight,');
      SLQuery.SQL.Add('case when transferred = 1 then ''�������'' else ''�� �������'' end as transferred');
      SLQuery.SQL.Add('FROM weight');
      SLQuery.SQL.Add('order by timestamp desc limit 100');
      SLQuery.Open;

{  while not _SLQuery.Eof do
   begin
      Log.save('e', 'shift | '+_SLQuery.FieldByName('shift').AsString);
      Log.save('e', 'weight | '+_SLQuery.FieldByName('weight').AsString);
      Log.save('e', 'heat | '+_SLQuery.FieldByName('heat').AsString);
      _SLQuery.Next;
   end;}

 //     if assigned(Form1.DBGrid2) then begin
//        Form1.DBGrid2.DataSource := SLDataSource;
//        Synchronize(Form1.DBGrid2.Refresh);//views ���������� ���������
 //     end;

      //���������� ����������� ���� � DBGrid -> 20 characters
      TStringField(SLQuery.FieldByName('shift')).DisplayWidth := 3;
      TStringField(SLQuery.FieldByName('timestamp')).DisplayWidth := 20;
      TStringField(SLQuery.FieldByName('transferred')).DisplayWidth := 20;
  except
    on E : Exception do
      Log.save('e', E.ClassName+'8, � ����������: '+E.Message);
  end;
end;
//-- end main


function TThreadSqlSend.GetMaxLocalCount: boolean;
var
  SQueryCount: TZQuery;
  timestamp: int64;
begin
//-- ��������� ������
  try
      SQueryCount := TZQuery.Create(nil);
      SQueryCount.Connection := SettingsApp.SConnect;

      if FSqlMaxLocal = 0 then
      begin
          SQueryCount.Close;
          SQueryCount.SQL.Clear;
          SQueryCount.SQL.Add('select * from sqlite_master');
          SQueryCount.SQL.Add('where type = ''table'' and tbl_name = ''weight''');
          SQueryCount.Open;

          if SQueryCount.FieldByName('tbl_name').IsNull then
          begin
            FreeAndNil(SQueryCount);
            exit;
          end;
      end;

      SQueryCount.Close;
      SQueryCount.SQL.Clear;
      SQueryCount.SQL.Add('SELECT max(timestamp) as timestamp');
      SQueryCount.SQL.Add('FROM weight');
      SQueryCount.Open;
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql max local count, � ����������: '+E.Message);
  end;

  try
      if not SQueryCount.FieldByName('timestamp').IsNull then begin
        timestamp := SQueryCount.FieldByName('timestamp').AsLargeInt;

        FreeAndNil(SQueryCount);

        if FSqlMaxLocal >= timestamp then
          exit;

        FSqlMaxLocal := timestamp;

        if assigned(SLQuery) then
          Synchronize(SqlReadTableLocal);//views ���������� ���������
      end
  except
    on E : Exception do
      Log.save('e', E.ClassName+' sql max local synchronize, � ����������: '+E.Message);
  end;
  //-- ��������� ������
end;


procedure TThreadSqlSend.SyncSqlMaxLocal;
begin
  Form1.SqlMaxLocal := FSqlMaxLocal;
end;




// ��� �������� ��������� ����� ����� �����������
initialization
//ThreadSqlSend := TThreadSqlSend.Create;


// ��� �������� ��������� ������������
finalization
//ThreadSqlSend.Destroy;


end.

