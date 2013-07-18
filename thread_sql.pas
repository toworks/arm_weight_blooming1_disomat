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
begin

  //��������� ���������
  if pkdat = '' then
    ShowTrayMessage('��������', '��� ������ ������ ������������ ���������', 2);

  try
    Module1.pFIBQuery1.Close;
    Module1.pFIBQuery1.SQL.Clear;
    Module1.pFIBQuery1.SQL.Add('select max(pkdat), count(pkdat) from ingots');
    Module1.pFIBQuery1.SQL.Add('order by pkdat desc');
    Module1.pFIBQuery1.ExecQuery;

    //�������������� ���� ��� ������� dbgrid
    pkdat_in := copy(Module1.pFIBQuery1.FieldByName('max').AsString, 1, 6);
    
    if SqlMax < Module1.pFIBQuery1.FieldByName('count').AsInt64 then
     begin
        SqlMax := Module1.pFIBQuery1.FieldByName('count').AsInt64;
        //���������� ����������� ���������� ������ ViewDbWeight;
        SqlReadTable(''''+pkdat_in+'1'','''+pkdat_in+'2'','''+pkdat_in+'3'','''+ManipulationWithDate(pkdat_in, 1)+'3''');

        //test
        Form1.b_test.Click;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'count -> '+Module1.pFIBQuery1.FieldByName('count').AsString);
    SaveLog('debug'+#9#9+'pkdat_in -> '+''''+pkdat_in+'1'','''+pkdat_in+'2'','''+pkdat_in+'3'','''+ManipulationWithDate(pkdat_in, 1)+'3''');
  {$ENDIF}
     end;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;



end.
