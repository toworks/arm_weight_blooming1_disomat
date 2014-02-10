unit thread_sql;


interface

uses
  SysUtils, Classes, Windows, ActiveX, Graphics, Forms, pFIBQuery, ZDataset;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSql = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadSql: TThreadSql;
  SqlMax: integer = 0;
  FutureDate: TDateTime;


  function ThreadSqlInit: bool;
  function SqlNewRecord: bool;
  procedure WrapperSql;//������� ��� ������������� � ���������� � ������ �������


//  {$DEFINE DEBUG}


implementation

uses
  main, logging, settings, module, thread_comport, sql;





procedure TThreadSql.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      Synchronize(WrapperSql);
      sleep(1000);
   end;
   CoUninitialize;
end;


function ThreadSqlInit: bool;
begin
  //������� �����
  ThreadSql := TThreadSql.Create(False);
  ThreadSql.Priority := tpNormal;
  ThreadSql.FreeOnTerminate := True;
end;


procedure WrapperSql;
begin
  try
      Application.ProcessMessages;//��������� �������� �� �������� ���������
      SqlNewRecord;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function SqlNewRecord: bool;
var
  FQueryNewRecord: TpFIBQuery;
  SQueryCount: TZQuery;
  pkdat_in: string;
  i, count, timestamp: integer;
begin
  FQueryNewRecord := TpFIBQuery.Create(nil);
  FQueryNewRecord.Database := Module1.pFIBDatabase1;
  FQueryNewRecord.Transaction := Module1.pFIBTransaction1;

  SQueryCount := TZQuery.Create(nil);
  SQueryCount.Connection := SConnect;

  Status;

  // ������� �����
  try
      if NOW > FutureDate then
      begin
        FutureDate := Now + 4 / (24 * 60); //+4 minutes
        MouseMoved;//views ���������� ���������
      end;
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'NOW -> '+datetimetostr(now));
    SaveLog('debug'+#9#9+'FutureDate -> '+datetimetostr(FutureDate));
  {$ENDIF}
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  try
    FQueryNewRecord.Close;
    FQueryNewRecord.SQL.Clear;
    FQueryNewRecord.SQL.Add('select distinct pkdat from ingots');
    FQueryNewRecord.SQL.Add('group by pkdat');
    FQueryNewRecord.SQL.Add('order by pkdat desc rows 3');
    Application.ProcessMessages;//��������� �������� �� �������� ���������
    FQueryNewRecord.ExecQuery;

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

    count:=0;
    FQueryNewRecord.Close;
    FQueryNewRecord.SQL.Clear;
    FQueryNewRecord.SQL.Add('select pkdat||num||num_ingot as c from ingots');
//    FQueryNewRecord.SQL.Add('select cast(pkdat||num||num_ingot as integer) as c from ingots');
    FQueryNewRecord.SQL.Add('order by pkdat desc, num desc ,num_ingot desc');
    FQueryNewRecord.SQL.Add('rows 1');
    Application.ProcessMessages;//��������� �������� �� �������� ���������
    FQueryNewRecord.ExecQuery;

    count := FQueryNewRecord.FieldByName('c').AsInt64;

    FreeAndNil(FQueryNewRecord);

    if SqlMax < count then
     begin
        SqlMax := count;
        //���������� ����������� ���������� ������ ViewDbWeight;
        SqlReadTable(pkdat_in);

        //dbgrid ������� �������� ���������
        if not pkdat.IsEmpty then
          NextWeightToRecordLocation;

        //-- test -> ��� ���������� DBGrid ������������ ����� ���������
        //-- Form1.b_test.Click;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'count -> '+inttostr(count));
    SaveLog('debug'+#9#9+'pkdat_in -> '+pkdat_in);
  {$ENDIF}
     end;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  // ������ ��������� ���������
  if MarkerNextWait then
    SqlNextWeightToRecord;

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
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
  //-- ��������� ������
end;




end.

