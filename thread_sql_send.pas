unit thread_sql_send;


interface

uses
  SysUtils, Classes, ActiveX, ZDataset;

type
  //����� ���������� ������� ����� TThreadSql:
  TThreadSqlSend = class(TThread)

  private
    procedure SqlSend;
  protected
    procedure Execute; override;
  public
    Constructor Create; overload;
    Destructor Destroy; override;
  end;

var
  ThreadSqlSend: TThreadSqlSend;


//  {$DEFINE DEBUG}


implementation

uses
  main, logging, settings, thread_comport, sql;




constructor TThreadSqlSend.Create;
begin
  inherited;
  // ������� ����� True - �������� ���������, False - �������� �����
  ThreadSqlSend := TThreadSqlSend.Create(True);
  ThreadSqlSend.Priority := tpNormal;
  ThreadSqlSend.FreeOnTerminate := True;
  ThreadSqlSend.Start;
end;


destructor TThreadSqlSend.Destroy;
begin
  if ThreadSqlSend <> nil then begin
    ThreadSqlSend.Terminate;
  end;
  inherited Destroy;
end;


procedure TThreadSqlSend.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      try
          Synchronize(SqlSend);
      except
        on E : Exception do
          Log.save('e', E.ClassName+', � ����������: '+E.Message);
      end;
      sleep(500);
   end;
   CoUninitialize;
end;


procedure TThreadSqlSend.SqlSend;
var
  i: integer;
  Byffer: array of array of AnsiString;
  send_error: boolean;
begin

  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT id_asutp, weight,');
  SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'' ) as timestamp');
  SQuery.SQL.Add('FROM weight');
  SQuery.SQL.Add('where transferred=0');
  SQuery.SQL.Add('order by id asc limit 10'); //�������� �� 10 ��
  SQuery.Open;

  i := 0;
  while not SQuery.Eof do
   begin
      if i = Length(Byffer) then SetLength(Byffer, i+1, 3);
      Byffer[i,0] := SQuery.FieldByName('id_asutp').AsString;
      Byffer[i,1] := SQuery.FieldByName('weight').AsString;
      Byffer[i,2] := SQuery.FieldByName('timestamp').AsString;
      inc(i);
      SQuery.Next;
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
    Log.save('d', 'send_error | '+booltostr(send_error));
  {$ENDIF}
        if not send_error then begin
            SQuery.Close;
            SQuery.SQL.Clear;
            SQuery.SQL.Add('UPDATE weight SET transferred=1');
            SQuery.SQL.Add('where id_asutp='+Byffer[i,0]+'');
            SQuery.ExecSQL;
            //save to log file
            {Log.save('sql'+#9#9+'write'+#9+'id_asutp -> '+Byffer[i,0]);
            Log.save('sql'+#9#9+'write'+#9+'weight -> '+Byffer[i,1]);
            Log.save('sql'+#9#9+'write'+#9+'timestamp -> '+Byffer[i,2]);}

            SqlReadTableLocal;//views ���������� ���������

            //������� ������ ������ ������ 3� ����
            SQuery.Close;
            SQuery.SQL.Clear;
            SQuery.SQL.Add('delete from weight');
            SQuery.SQL.Add('where timestamp < strftime(''%s'', ''now'') - (86400*3)');
            SQuery.ExecSQL;
        end;
      except
        on E : Exception do
          Log.save('e', E.ClassName+', � ����������: '+E.Message);
      end;
   end;
end;




// ��� �������� ��������� ����� ����� �����������
initialization
ThreadSqlSend := TThreadSqlSend.Create;


// ��� �������� ��������� ������������
finalization
ThreadSqlSend.Destroy;


end.

