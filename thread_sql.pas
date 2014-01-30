unit thread_sql;


interface

uses
  SysUtils, Classes, Windows, ActiveX, Graphics, Forms;

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
  main, logging, settings, module, sql;





procedure TThreadSql.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      Synchronize(WrapperSql);
      sleep(5000);
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
  pkdat_in: string;
  i, count: integer;
begin

  //��������� ���������
  if pkdat.IsEmpty then
    ShowTrayMessage('��������', '��� ������ ������ ������������ ���������', 2);

  try
    Module1.pFIBQuery1.Close;
    Module1.pFIBQuery1.SQL.Clear;
    Module1.pFIBQuery1.SQL.Add('select distinct pkdat, count(pkdat) as c from ingots');
    Module1.pFIBQuery1.SQL.Add('group by pkdat');
    Module1.pFIBQuery1.SQL.Add('order by pkdat desc rows 3');
    Module1.pFIBQuery1.ExecQuery;

    //�������������� ������ ��� ������� � dbgrid
    i:=0;
    count:=i;
    while not Module1.pFIBQuery1.Eof do
    begin
      if i = 0 then
        pkdat_in := ''''+Module1.pFIBQuery1.FieldByName('pkdat').AsString+''''
      else
        pkdat_in := pkdat_in+','+''''+Module1.pFIBQuery1.FieldByName('pkdat').AsString+'''';

      count := count + Module1.pFIBQuery1.FieldByName('c').AsInt64;
      inc(i);
      Module1.pFIBQuery1.Next;
    end;

    if SqlMax < count then
     begin
        SqlMax := count;
        //���������� ����������� ���������� ������ ViewDbWeight;
        SqlReadTable(pkdat_in);

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

  try
      SqlReadTableLocal;//views ���������� ���������
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'SLQuery.RecordCount -> '+inttostr(SLQuery.RecordCount));
  {$ENDIF}
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  // ������� �����
  try
      if NOW > FutureDate then
      begin
        FutureDate := Now + 3 / (24 * 60); //+3 minutes
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

end;



end.

