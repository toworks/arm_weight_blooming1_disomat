unit thread_sql_send;


interface

uses
  SysUtils, Classes, Data.DB, ActiveX, ZConnection, ZDataset, ZDbcIntfs,
  logging, sql;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSqlSend = class(TThread)
  private
    FThreadSqlSend: TThreadSqlSend;
    FSqlMaxLocal: Int64;

    function ConfigOracleSetting(InData: boolean): boolean;
    procedure SqlSend;
    function SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): boolean;
    function GetMaxLocalCount: boolean;

  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
    procedure SyncSqlMaxLocal;
  end;

var
  lLog: TLog;
  FOraConnect: TZConnection;
  FOraQuery: TZQuery;
  TSSsqlite: TSqlite;


//  {$DEFINE DEBUG}


implementation

uses
  settings, main;




//constructor TThreadSqlSend.Create;
constructor TThreadSqlSend.Create(_Log: TLog);
begin
  inherited Create(True);

  lLog := _Log;
  TSSsqlite := TSqlite.Create(lLog);
  // ������� ����� True - �������� ���������, False - �������� �����
  FThreadSqlSend := TThreadSqlSend.Create(True);
  FThreadSqlSend.Priority := tpNormal;
  FThreadSqlSend.FreeOnTerminate := True;

  FSqlMaxLocal := 0;

  ConfigOracleSetting(true);

  FThreadSqlSend.Start;
end;


destructor TThreadSqlSend.Destroy;
begin
  if FThreadSqlSend <> nil then begin
    ConfigOracleSetting(false);
    FThreadSqlSend.Terminate;
  end;
  TSSsqlite.Destroy;
  inherited Destroy;
end;




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
          lLog.save('e', E.ClassName+', � ����������: '+E.Message);
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
          lLog.save('e', E.ClassName+'3, � ����������: '+E.Message);
      end;

      sleep(1000);
   end;
   CoUninitialize;
end;


procedure TThreadSqlSend.SqlSend;
var
  i: integer;
  Byffer: array of array of AnsiString;
  send_error: boolean;
begin

  try
      TSSsqlite.SQuery.Close;
      TSSsqlite.SQuery.SQL.Clear;
      TSSsqlite.SQuery.SQL.Add('SELECT id_asutp, weight,');
      TSSsqlite.SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'' ) as timestamp');
      TSSsqlite.SQuery.SQL.Add('FROM weight');
      TSSsqlite.SQuery.SQL.Add('where transferred=0');
      TSSsqlite.SQuery.SQL.Add('order by id asc limit 10'); //�������� �� 10 ��
      TSSsqlite.SQuery.Open;
   except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql send select, � ����������: '+E.Message);
  end;

      i := 0;
   try
      while not TSSsqlite.SQuery.Eof do
      begin
          if i = Length(Byffer) then SetLength(Byffer, i+1, 3);
          Byffer[i,0] := TSSsqlite.SQuery.FieldByName('id_asutp').AsString;
          Byffer[i,1] := TSSsqlite.SQuery.FieldByName('weight').AsString;
          Byffer[i,2] := TSSsqlite.SQuery.FieldByName('timestamp').AsString;
          inc(i);
          TSSsqlite.SQuery.Next;
      end;

  except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql send buffer, � ����������: '+E.Message);
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
  {$IFDEF DEBUG}
    lLog.save('d', 'send_error | '+booltostr(send_error));
  {$ENDIF}
        if not send_error then begin
            TSSsqlite.SQuery.Close;
            TSSsqlite.SQuery.SQL.Clear;
            TSSsqlite.SQuery.SQL.Add('UPDATE weight SET transferred=1');
            TSSsqlite.SQuery.SQL.Add('where id_asutp='+Byffer[i,0]+'');
            TSSsqlite.SQuery.ExecSQL;
            //save to Log file
            {Log.save('sql'+#9#9+'write'+#9+'id_asutp -> '+Byffer[i,0]);
            Log.save('sql'+#9#9+'write'+#9+'weight -> '+Byffer[i,1]);
            Log.save('sql'+#9#9+'write'+#9+'timestamp -> '+Byffer[i,2]);}

            //������� ������ ������ ������ 3� ����
            TSSsqlite.SQuery.Close;
            TSSsqlite.SQuery.SQL.Clear;
            TSSsqlite.SQuery.SQL.Add('delete from weight');
            TSSsqlite.SQuery.SQL.Add('where timestamp < strftime(''%s'', ''now'') - (86400*3)');
            TSSsqlite.SQuery.ExecSQL;
        end;
      except
        on E : Exception do
          lLog.save('e', E.ClassName+' sql send update, � ����������: '+E.Message);
      end;
  end;
end;


function TThreadSqlSend.SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): boolean;
var
  error: boolean;
begin
  error := false;

  try
    //���� �������: EZSQLException, � ����������: SQL Error: OCI_NO_DATA
//    if not FOraConnect.Connected then
      lLog.save('e', 'ServerVersion | '+inttostr(FOraConnect.ServerVersion));
//      FOraConnect.Reconnect;

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
      lLog.save('e', E.ClassName+' sql save to oracle, � ����������: '+E.Message+' | '+FOraQuery.SQL.Text);
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
        lLog.save('e', E.ClassName+'7, � ����������: '+E.Message+' | '+FOraQuery.SQL.Text);
      end;
    end;
  end;

  Result := error;

end;


//-- start main
{procedure TThreadSqlSend.SqlReadTableLocal;
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
{      TStringField(SLQuery.FieldByName('shift')).DisplayWidth := 3;
      TStringField(SLQuery.FieldByName('timestamp')).DisplayWidth := 20;
      TStringField(SLQuery.FieldByName('transferred')).DisplayWidth := 20;
  except
    on E : Exception do
      Log.save('e', E.ClassName+'8, � ����������: '+E.Message);
  end;
end;}
//-- end main


function TThreadSqlSend.GetMaxLocalCount: boolean;
var
  timestamp: int64;
begin
//-- ��������� ������
  try
      if FSqlMaxLocal = 0 then
      begin
          TSSsqlite.SQuery.Close;
          TSSsqlite.SQuery.SQL.Clear;
          TSSsqlite.SQuery.SQL.Add('select * from sqlite_master');
          TSSsqlite.SQuery.SQL.Add('where type = ''table'' and tbl_name = ''weight''');
          TSSsqlite.SQuery.Open;

          if TSSsqlite.SQuery.FieldByName('tbl_name').IsNull then
          begin
            exit;
          end;
      end;

      TSSsqlite.SQuery.Close;
      TSSsqlite.SQuery.SQL.Clear;
      TSSsqlite.SQuery.SQL.Add('SELECT max(timestamp) as timestamp');
      TSSsqlite.SQuery.SQL.Add('FROM weight');
      TSSsqlite.SQuery.Open;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql max local count, � ����������: '+E.Message);
  end;

  try
      if not TSSsqlite.SQuery.FieldByName('timestamp').IsNull then begin
        timestamp := TSSsqlite.SQuery.FieldByName('timestamp').AsLargeInt;

        if FSqlMaxLocal >= timestamp then
          exit;

        FSqlMaxLocal := timestamp;

        if assigned(MainSqlite.SQuery) then
          Synchronize(SqlReadTableLocal);//views ���������� ���������
      end
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql max local synchronize, � ����������: '+E.Message);
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

