unit thread_sql_read;


interface

uses
  SysUtils, Classes, ActiveX, Forms, ZDataset;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSqlRead = class(TThread)

  private
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
  main, logging, settings, thread_comport, sql;




constructor TThreadSqlRead.Create;
begin
  inherited;
  // ������� ����� True - �������� ���������, False - �������� �����
  ThreadSqlRead := TThreadSqlRead.Create(True);
  ThreadSqlRead.Priority := tpNormal;
  ThreadSqlRead.FreeOnTerminate := True;
  ThreadSqlRead.Start;
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
      sleep(5000);
   end;
   CoUninitialize;
end;


procedure TThreadSqlRead.SqlNewRecord;
var
  FQueryNewRecord: TZQuery;
  SQueryCount: TZQuery;
  pkdat_in: string;
  i, timestamp: integer;
  count: int64;
begin
  FQueryNewRecord := TZQuery.Create(nil);
  FQueryNewRecord.Connection := FConnect;

  SQueryCount := TZQuery.Create(nil);
  SQueryCount.Connection := SConnect;

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
    Application.ProcessMessages;//��������� �������� �� �������� ���������
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
    Application.ProcessMessages;//��������� �������� �� �������� ���������
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

  //-- ��������� ������
  try
      if SqlMaxLocal = 0 then
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
      SQueryCount.SQL.Add('SELECT timestamp');
      SQueryCount.SQL.Add('FROM weight');
      SQueryCount.SQL.Add('order by timestamp desc limit 1');
      SQueryCount.Open;

      timestamp := SQueryCount.FieldByName('timestamp').AsInteger;
      FreeAndNil(SQueryCount);

      if SqlMaxLocal >= timestamp then
        exit;

      SqlMaxLocal := timestamp;
      //views ���������� ���������
      SqlReadTableLocal;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;
  //-- ��������� ������
end;


// ��� �������� ��������� ����� ����� �����������
initialization
ThreadSqlRead := TThreadSqlRead.Create;


// ��� �������� ��������� ������������
finalization
ThreadSqlRead.Destroy;


end.

