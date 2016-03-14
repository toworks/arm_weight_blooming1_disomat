unit thread_sql_read;


interface

uses
  SysUtils, Data.DB, Classes, ActiveX, ZDataset, SyncObjs, logging;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSqlRead = class(TThread)

  private
    Log: TLog;
    function SqlReadTable(InData: string): boolean;
    procedure SqlNewRecord;
  protected
    procedure Execute; override;
  public
    Constructor Create; overload;
    Destructor Destroy; override;
  end;

var
  ThreadSqlRead: TThreadSqlRead;
  SqlMax: int64 = 0;
  FutureDate: TDateTime;


//  {$DEFINE DEBUG}


implementation

uses
  main, settings, thread_comport, thread_sql_send, sql;




constructor TThreadSqlRead.Create;
begin
  inherited;
  // ������� ����� True - �������� ���������, False - �������� �����
  ThreadSqlRead := TThreadSqlRead.Create(True);
  ThreadSqlRead.Priority := tpNormal;
  ThreadSqlRead.FreeOnTerminate := True;
  ThreadSqlRead.Start;

  Log := TLog.Create;
end;


destructor TThreadSqlRead.Destroy;
begin
  if ThreadSqlRead <> nil then begin
    ThreadSqlRead.Terminate;
  end;
  inherited Destroy;
end;


procedure TThreadSqlRead.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      try
          Synchronize(SqlNewRecord);
      except
        on E : Exception do
          Log.save('e', E.ClassName+', � ����������: '+E.Message);
      end;

      sleep(1000);
   end;
   CoUninitialize;
end;


procedure TThreadSqlRead.SqlNewRecord;
var
  FQueryNewRecord: TZQuery;
  pkdat_in: string;
  i, timestamp: integer;
  count: int64;
begin
  FQueryNewRecord := TZQuery.Create(nil);
  FQueryNewRecord.Connection := FConnect;

  // ������� �����
  try
      if NOW > FutureDate then
      begin
        FutureDate := Now + 4 / (24 * 60); //+4 minutes
        MouseMoved;//views ���������� ���������
      end;
  {$IFDEF DEBUG}
    Log.save('d', 'NOW -> '+datetimetostr(now));
    Log.save('d', 'FutureDate -> '+datetimetostr(FutureDate));
  {$ENDIF}
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  try
    FQueryNewRecord.Close;
    FQueryNewRecord.SQL.Clear;
    FQueryNewRecord.SQL.Add('select distinct pkdat from ingots');
    FQueryNewRecord.SQL.Add('group by pkdat');
    FQueryNewRecord.SQL.Add('order by pkdat desc rows 3');
    FQueryNewRecord.Open;

    //�������������� ������ ��� ������� � dbgrid
    i:=0;
    while not FQueryNewRecord.Eof do
    begin
      if i = 0 then
        pkdat_in := ''''+FQueryNewRecord.FieldByName('pkdat').AsString+''''
      else
        pkdat_in := pkdat_in+','+''''+FQueryNewRecord.FieldByName('pkdat').AsString+'''';
      inc(i);
      FQueryNewRecord.Next;
    end;

    count := 0;
    FQueryNewRecord.Close;
    FQueryNewRecord.SQL.Clear;
    FQueryNewRecord.SQL.Add('select pkdat||num||num_ingot as c from ingots');
    FQueryNewRecord.SQL.Add('order by pkdat desc, num desc ,num_ingot desc');
    FQueryNewRecord.SQL.Add('rows 1');
    FQueryNewRecord.Open;

    count := FQueryNewRecord.FieldByName('c').AsLargeInt;

    FreeAndNil(FQueryNewRecord);

    if (SqlMax < count) then
    begin
        SqlMax := count;
        //���������� ����������� ���������� ������ ViewDbWeight;
        SqlReadTable(pkdat_in);

        //dbgrid ������� �������� ���������
        if not pkdat.IsEmpty then
          NextWeightToRecordLocation;

  {$IFDEF DEBUG}
    Log.save('d', 'count -> '+inttostr(count));
    Log.save('d', 'SqlMax -> '+inttostr(SqlMax));
    Log.save('d', 'pkdat_in -> '+pkdat_in);
  {$ENDIF}
     end;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  // ������ ��������� ���������
  if MarkerNextWait then
    NextWeightToRecord; //��������� ������ (������) �� ���������
end;


function TThreadSqlRead.SqlReadTable(InData: string): boolean;
begin
  try
      FQuery.Close;
      FQuery.SQL.Clear;
      FQuery.SQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group, sh.smena');
      FQuery.SQL.Add('from ingots i, heats h, steels s, shifts sh');
      FQuery.SQL.Add('where i.pkdat=h.pkdat');
      FQuery.SQL.Add('and i.pkdat=sh.pkdat');
      FQuery.SQL.Add('and i.num=h.num');
      FQuery.SQL.Add('and h.steel_grade=s.steel_grade');
      FQuery.SQL.Add('and i.pkdat in ('+InData+')');
      FQuery.SQL.Add('order by i.pkdat desc, i.num desc, i.num_ingot desc');
      FQuery.Open;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;
  //���������� ����������� ���� � DBGrid -> pFIBDataSet1
  TDateTimeField(FQuery.FieldByName('time_ingot')).DisplayFormat:='hh:nn:ss';
end;


// ��� �������� ��������� ����� ����� �����������
initialization
//ThreadSqlRead := TThreadSqlRead.Create;


// ��� �������� ��������� ������������
finalization
//ThreadSqlRead.Destroy;


end.

