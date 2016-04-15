unit thread_sql_send;


interface

uses
  SysUtils, Classes, DB, ActiveX, ZConnection, ZDataset, ZDbcIntfs,
   {$ifdef windows} Windows, Forms, {$endif} logging, sql;

type
  //Здесь необходимо описать класс TThreadSql:
  TThreadSqlSend = class(TThread)
  private
    FThreadSqlSend: TThreadSqlSend;

    function ConfigOracleSetting(InData: boolean): boolean;
    procedure SqlSend;
    function SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): boolean;
    function SyncViewLocal: boolean;
    procedure SqlReadTableLocal;
  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
  end;

var
  lLog: TLog;
  FOraConnect: TZConnection;
  FOraQuery: TZQuery;
  TSSsqlite: TSqlite;
  FSendCount: Int64;

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

  ConfigOracleSetting(true);

  FSendCount := 1;//first run

  // создаем поток True - создание остановка, False - создание старт
  FThreadSqlSend := TThreadSqlSend.Create(True);
  FThreadSqlSend.Priority := tpNormal;
  FThreadSqlSend.FreeOnTerminate := True;
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
        FOraConnect.LibraryLocation := '.\oci.dll';// отказался от полных путей не читает
        FOraConnect.Protocol := 'oracle';
        FOraConnect.User := OraSqlSettings.user;
        FOraConnect.Password := OraSqlSettings.password;
        FOraConnect.ClientCodepage := 'CL8MSWIN1251';
        FOraConnect.Connect;
        FOraQuery.Connection := FOraConnect;
      except
        on E: Exception do begin
          lLog.save('e', E.ClassName+', с сообщением: '+E.Message);
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

      // при выбор заготовки останавливаем чтение
      if not ThreadStop then begin
          try
              SqlSend;
              SyncViewLocal;
          except
            on E : Exception do
              lLog.save('e', E.ClassName+' TThreadSqlSend, с сообщением: '+E.Message);
          end;
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
      TSSsqlite.SQuery.SQL.Add('and timestamp > strftime(''%s'', ''now'') - (86400*3)'); //за 3 дня от текущей даты
      TSSsqlite.SQuery.SQL.Add('order by id asc limit 100'); //порциями по 100 шт
      TSSsqlite.SQuery.Open;
   except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql send select, с сообщением: '+E.Message);
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
      lLog.save('e', E.ClassName+' sql send buffer, с сообщением: '+E.Message);
  end;

  for i := Low(Byffer) to High(Byffer) do
  begin
 {$IFDEF DEBUG}
    Log.save('d', 'id_asutp | '+Byffer[i,0]);
    Log.save('d', 'weight | '+Byffer[i,1]);
    Log.save('d', 'timestamp | '+Byffer[i,2]);
  {$ENDIF}
      try
        send_error := SqlSaveToOracle(Byffer[i,0], Byffer[i,1], Byffer[i,2]);
  {$IFDEF DEBUG}
    lLog.save('d', 'send_error | '+booltostr(send_error));
  {$ENDIF}
      except
        on E : Exception do
          lLog.save('e', E.ClassName+' sql save oracle return error, с сообщением: '+E.Message);
      end;

      try
        inc(FSendCount);// если есть данные для запись увеличиваем
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

            //удаляем старые записи старше 3х дней
            TSSsqlite.SQuery.Close;
            TSSsqlite.SQuery.SQL.Clear;
            TSSsqlite.SQuery.SQL.Add('delete from weight');
            TSSsqlite.SQuery.SQL.Add('where timestamp < strftime(''%s'', ''now'') - (86400*3)');
            TSSsqlite.SQuery.ExecSQL;
        end;
      except
        on E : Exception do
          lLog.save('e', E.ClassName+' sql send update, с сообщением: '+E.Message);
      end;
  end;
end;


function TThreadSqlSend.SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): boolean;
var
  error: boolean;
  err_oci_no_data: integer;
begin
  { если небыло commit из любого места ExecSQL ломает поток
    и не обрабатывается try и при вызове ExecSQL ломает поток }
  try
    //была ошибака: EZSQLException, с сообщением: SQL Error: OCI_NO_DATA
    if not FOraConnect.Ping then
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
     error := false;
    except
      on E : Exception do begin
        error := true;
        err_oci_no_data := AnsiPos('OCI_NO_DATA', E.Message);
        lLog.save('e', E.ClassName+' sql save to oracle, с сообщением: '+E.Message+' | '+FOraQuery.SQL.Text);
    end;
  end;
{$IFDEF DEBUG}
  Log.save('d', 'position | '+inttostr(err_oci_no_data));
{$ENDIF}

  if error and (err_oci_no_data = 0) then
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
        lLog.save('e', E.ClassName+' sql update to oracle, с сообщением: '+E.Message+' | '+FOraQuery.SQL.Text);
      end;
    end;
  end;

  Result := error;
end;


//-- start main
procedure TThreadSqlSend.SqlReadTableLocal;
begin
  try
      { Operation cannot be performed on an inactive dataset - при  включении управлением
        появляется данная ошибка }

      //отключаем управление
//      form1.DBGrid2.DataSource.DataSet.DisableControls;
//      MainSqlite.SQuery.DisableControls;
      try
          MainSqlite.SQuery.Close;
          MainSqlite.SQuery.SQL.Clear;
          MainSqlite.SQuery.SQL.Add('SELECT substr(pkdat,7,1) as shift, num_ingot,');
          MainSqlite.SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'' ) as timestamp,');
          MainSqlite.SQuery.SQL.Add('heat, weight,');
          MainSqlite.SQuery.SQL.Add('case when transferred = 1 then ''передан'' else ''не передан'' end as transferred');
          MainSqlite.SQuery.SQL.Add('FROM weight');
          MainSqlite.SQuery.SQL.Add('order by timestamp desc limit 100');
          Application.ProcessMessages; // следующая операция не тормозит интерфейс
          MainSqlite.SQuery.Open;

          //исправляем отображение даты в DBGrid -> 20 characters
          TStringField(MainSqlite.SQuery.FieldByName('shift')).DisplayWidth := 3;
          TStringField(MainSqlite.SQuery.FieldByName('timestamp')).DisplayWidth := 20;
          TStringField(MainSqlite.SQuery.FieldByName('transferred')).DisplayWidth := 20;
      except
        on E : Exception do
          Log.save('e', E.ClassName+' sql read table local, с сообщением: '+E.Message);
      end;

    finally
      //включаем управление
//      form1.DBGrid2.DataSource.DataSet.EnableControls;
//      MainSqlite.SQuery.EnableControls;
    end;
end;
//-- end main


function TThreadSqlSend.SyncViewLocal: boolean;
begin
//-- локальные данные
  try
      if FSendCount <> 0 then
      begin
         FSendCount := 0;
//         if assigned(MainSqlite.SQuery) then
          if assigned(SDataSource) then
            Synchronize(@SqlReadTableLocal);//views взвешенные заготовки
      end;
  except
  on E : Exception do
    lLog.save('e', E.ClassName+' sql max local synchronize, с сообщением: '+E.Message);
  end;
  //-- локальные данные
end;




// При загрузке программы класс будет создаваться
initialization
//ThreadSqlSend := TThreadSqlSend.Create;


// При закрытии программы уничтожаться
finalization
//ThreadSqlSend.Destroy;


end.

