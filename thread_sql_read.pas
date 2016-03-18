unit thread_sql_read;


interface

uses
  SysUtils, Data.DB, Classes, ActiveX, ZDataset, SyncObjs, logging;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSqlRead = class(TThread)
  private
    FThreadSqlRead: TThreadSqlRead;
    FSqlMax: int64;
    Fpkdat_in: string;

    procedure SyncSqlReadTable;
    procedure SqlNewRecord;
  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
    procedure SyncSqlMax;
  end;

var
//  SqlMax: int64 = 0;
  FutureDate: TDateTime;
  Log: TLog;


//  {$DEFINE DEBUG}


implementation

uses
  main, settings, thread_comport, thread_sql_send, sql;




constructor TThreadSqlRead.Create(_Log: TLog);
begin
  inherited Create(True);

  Log := _Log;

  FSqlMax := 0;

  // ������� ����� True - �������� ���������, False - �������� �����
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
          Synchronize(SyncSqlMax);
          SqlNewRecord;
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
        Fpkdat_in := ''''+FQueryNewRecord.FieldByName('pkdat').AsString+''''
      else
        Fpkdat_in := Fpkdat_in+','+''''+FQueryNewRecord.FieldByName('pkdat').AsString+'''';
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

    if (FSqlMax < count) then
    begin
        FSqlMax := count;
        //���������� ����������� ���������� ������ ViewDbWeight;
        Synchronize(SyncSqlReadTable);

        //dbgrid ������� �������� ���������
        if not Fpkdat_in.IsEmpty then
          Synchronize(NextWeightToRecordLocation);

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


procedure TThreadSqlRead.SyncSqlReadTable;
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
      FQuery.SQL.Add('and i.pkdat in ('+Fpkdat_in+')');
      FQuery.SQL.Add('order by i.pkdat desc, i.num desc, i.num_ingot desc');
      FQuery.Open;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;
  //���������� ����������� ���� � DBGrid -> pFIBDataSet1
  TDateTimeField(FQuery.FieldByName('time_ingot')).DisplayFormat:='hh:nn:ss';
end;


procedure TThreadSqlRead.SyncSqlMax;
begin
  Form1.SqlMax := FSqlMax;
end;





// ��� �������� ��������� ����� ����� �����������
initialization
//ThreadSqlRead := TThreadSqlRead.Create;


// ��� �������� ��������� ������������
finalization
//ThreadSqlRead.Destroy;


end.

