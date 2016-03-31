unit thread_sql_read;


interface

uses
  SysUtils, DB, Classes, ActiveX, ZDataset, Variants, logging, sql;

type
  //Здесь необходимо описать класс TThreadSql:
  TThreadSqlRead = class(TThread)
  private
    FThreadSqlRead: TThreadSqlRead;
    FSqlMax: int64;
    Fpkdat_in: string;

    procedure SyncSqlReadTable;
    procedure SqlNewRecord;
    procedure NextWeightToRecordLocation;
  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
    procedure SyncSqlMax;
  end;

var
  FutureDate: TDateTime;
  lLog: TLog;
  Fsql: TFsql;


//  {$DEFINE DEBUG}


implementation

uses
  main;




constructor TThreadSqlRead.Create(_Log: TLog);
begin
  inherited Create(True);

  lLog := _Log;
  Fsql := TFsql.Create(lLog);
  FSqlMax := 0;

  // создаем поток True - создание остановка, False - создание старт
  FThreadSqlRead := TThreadSqlRead.Create(True);
  FThreadSqlRead.Priority := tpNormal;
  FThreadSqlRead.FreeOnTerminate := True;
  FThreadSqlRead.Start;
end;


destructor TThreadSqlRead.Destroy;
begin
  if FThreadSqlRead <> nil then begin
    FThreadSqlRead.Terminate;
  end;
  inherited Destroy;
end;


procedure TThreadSqlRead.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      try
          Synchronize(@SyncSqlMax);
          SqlNewRecord;
      except
        on E : Exception do
          lLog.save('e', E.ClassName+', с сообщением: '+E.Message);
      end;

      sleep(1000);
   end;
   CoUninitialize;
end;


procedure TThreadSqlRead.SqlNewRecord;
var
  i, timestamp: integer;
  count: int64;
begin
  // двигаем мышку
  try
      if NOW > FutureDate then
      begin
        FutureDate := Now + 4 / (24 * 60); //+4 minutes
//        MouseMoved;//двигаем мышку
      end;
  {$IFDEF DEBUG}
    lLog.save('d', 'NOW -> '+datetimetostr(now));
    lLog.save('d', 'FutureDate -> '+datetimetostr(FutureDate));
  {$ENDIF}
  except
    on E : Exception do
      lLog.save('e', E.ClassName+', с сообщением: '+E.Message);
  end;

  try
    Fsql.FQuery.Close;
    Fsql.FQuery.SQL.Clear;
    Fsql.FQuery.SQL.Add('select distinct pkdat from ingots');
    Fsql.FQuery.SQL.Add('group by pkdat');
    Fsql.FQuery.SQL.Add('order by pkdat desc rows 3');
    Fsql.FQuery.Open;

    //подготавливаем данные для выборки в dbgrid
    i:=0;
    while not Fsql.FQuery.Eof do
    begin
      if i = 0 then
        Fpkdat_in := ''''+Fsql.FQuery.FieldByName('pkdat').AsString+''''
      else
        Fpkdat_in := Fpkdat_in+','+''''+Fsql.FQuery.FieldByName('pkdat').AsString+'''';
      inc(i);
      Fsql.FQuery.Next;
    end;

    count := 0;
    Fsql.FQuery.Close;
    Fsql.FQuery.SQL.Clear;
    Fsql.FQuery.SQL.Add('select pkdat||num||num_ingot as c from ingots');
    Fsql.FQuery.SQL.Add('order by pkdat desc, num desc ,num_ingot desc');
    Fsql.FQuery.SQL.Add('rows 1');
    Fsql.FQuery.Open;

    count := Fsql.FQuery.FieldByName('c').AsLargeInt;

    if (FSqlMax < count) then
    begin
        FSqlMax := count;
        //обновление отображение записанных данных ViewDbWeight;
        Synchronize(@SyncSqlReadTable);

        //dbgrid текущая выбраная заготовка
        if Fpkdat_in <> '' then
          Synchronize(@NextWeightToRecordLocation);

  {$IFDEF DEBUG}
    lLog.save('d', 'count -> '+inttostr(count));
    lLog.save('d', 'SqlMax -> '+inttostr(SqlMax));
    lLog.save('d', 'pkdat_in -> '+pkdat_in);
  {$ENDIF}
     end;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+', с сообщением: '+E.Message);
  end;

  // маркер следующей заготовки
  if MarkerNextWait then
//    Synchronize(@NextWeightToRecord); //следующая запись (слиток) от записаной
end;


procedure TThreadSqlRead.SyncSqlReadTable;
begin
  try
      MainFSql.FQuery.Close;
      MainFSql.FQuery.SQL.Clear;
      MainFSql.FQuery.SQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group, sh.smena');
      MainFSql.FQuery.SQL.Add('from ingots i, heats h, steels s, shifts sh');
      MainFSql.FQuery.SQL.Add('where i.pkdat=h.pkdat');
      MainFSql.FQuery.SQL.Add('and i.pkdat=sh.pkdat');
      MainFSql.FQuery.SQL.Add('and i.num=h.num');
      MainFSql.FQuery.SQL.Add('and h.steel_grade=s.steel_grade');
      MainFSql.FQuery.SQL.Add('and i.pkdat in ('+Fpkdat_in+')');
      MainFSql.FQuery.SQL.Add('order by i.pkdat desc, i.num desc, i.num_ingot desc');
      MainFSql.FQuery.Open;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+', с сообщением: '+E.Message);
  end;
  //исправляем отображение даты в DBGrid -> pFIBDataSet1
  TDateTimeField(MainFSql.FQuery.FieldByName('time_ingot')).DisplayFormat:='hh:nn:ss';
end;


procedure TThreadSqlRead.SyncSqlMax;
begin
//  Form1.SqlMax := FSqlMax;
end;


procedure TThreadSqlRead.NextWeightToRecordLocation;
var
  KeyValues : Variant;
begin
  try
      //отключаем управление
      form1.DBGrid1.DataSource.DataSet.DisableControls;
      //переменные по которым будет производиться поиск
      KeyValues := VarArrayOf([pkdat,num,num_ingot]);
      //поиск по ключивым полям
      form1.DBGrid1.DataSource.DataSet.Locate('pkdat;num;num_ingot', KeyValues, []);
  finally
      //включаем управление
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;
  //-- test
  //Form1.l_next_id.Caption:=pkdat+'|'+num+'|'+num_ingot;
end;


// При загрузке программы класс будет создаваться
initialization
//ThreadSqlRead := TThreadSqlRead.Create;


// При закрытии программы уничтожаться
finalization
//ThreadSqlRead.Destroy;


end.

