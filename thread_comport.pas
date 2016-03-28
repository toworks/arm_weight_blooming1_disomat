unit thread_comport;


interface

uses
  SysUtils, Classes, ActiveX, synaser, SyncObjs, logging, Messages, ZDataset, sql;

type
  //����� ���������� ������� ����� TThreadComPort:
  TThreadComPort = class(TThread)

  private
    Fcount: integer;
    Fno_save: boolean;
    FThreadComPort: TThreadComPort;
    FMessageData: AnsiString;

    function CPortParity(InData: String): Char;
    function SendReadToSerial(InData: AnsiString): AnsiString;
    function hash_bcc(InChar: string): Char;
    function ReceiveData(Data: AnsiString): string;

    procedure ReadToMessage;
    procedure SyncMemoTesting;
    procedure SyncStatus;
    procedure SyncCalibration;
    function SqlSaveInBuffer(DataIn: AnsiString): boolean;
  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
    function SendAttribute: boolean;
  end;

var
  lLog: TLog;
  TCsqlite: TSqlite;



//  {$DEFINE DEBUG}


implementation

uses
  settings, main, testing, calibration;




constructor TThreadComPort.Create(_Log: TLog);
begin
  inherited Create(True);

  lLog := _Log;
  TCsqlite := TSqlite.Create(lLog);
  // ������� ����� True - �������� ���������, False - �������� �����
  FThreadComPort := TThreadComPort.Create(True);
  FThreadComPort.Priority := tpNormal;
  FThreadComPort.FreeOnTerminate := True;
  FThreadComPort.Start;

  Fno_save := false;
  Fcount := 10;
end;


destructor TThreadComPort.Destroy;
begin
  if FThreadComPort <> nil then begin
    FThreadComPort.Terminate;
  end;
  inherited Destroy;
end;


procedure TThreadComPort.Execute;
begin
  CoInitialize(nil);
  while True do
  begin
      try
          ReadToMessage;
      except
        on E : Exception do
          lLog.save('e', E.ClassName+' serial execute, � ����������: '+E.Message);
      end;

      sleep(1000);
   end;
   CoUninitialize;
end;


function TThreadComPort.SendReadToSerial(InData: AnsiString): AnsiString;
var
  serial_port: TBlockserial;
begin
    //status ������ � ������������
    if Fcount > 10 then begin
      Synchronize(SyncStatus);
      Synchronize(Status);
      Fcount := 0;
    end
    else
      inc(Fcount);

    try
        serial_port := TBlockserial.Create;
        serial_port.RaiseExcept := false; //false ������������ ������ �����
        serial_port.Connect('COM'+SerialPortSettings.serial_port_number);
        if serial_port.InstanceActive then begin
//          serial_port.Config(19200,8,'E',SB2,false,false);
          serial_port.Config( strtoint(SerialPortSettings.baud),
                              strtoint(SerialPortSettings.data_bits),
                              CPortParity(SerialPortSettings.parity),
                              strtoint(SerialPortSettings.stop_bits),false,false);
          serial_port.SendString(InData);
          sleep(200);
          FMessageData := serial_port.RecvBufferStr(serial_port.WaitingData, 200);
       end;
    finally
          FreeAndNil(serial_port);
    end;
end;


procedure TThreadComPort.ReadToMessage;
begin
  try
      SendReadToSerial(#2'00#TK#'#16#3+hash_bcc('00#TK#'#16#3));
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' serial send/read, � ����������: '+E.Message);
  end;

  try
      ReceiveData(FMessageData);
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' serial recive, � ����������: '+E.Message);
  end;

  if Fno_save then
    SendAttribute;

  {$IFDEF DEBUG}
    lLog.save('d', 'no_save | '+booltostr(Fno_save));
  {$ENDIF}
end;


function TThreadComPort.hash_bcc(InChar: string): char;
var
    i: byte;
begin
  result := InChar[1];
  for i := 2 to length(InChar) do
  result := char(ord(result) xor ord(InChar[i]));
end;


function TThreadComPort.ReceiveData(Data: AnsiString): string;
begin

  FMessageData := Data;

  if (copy(Data, 2, 6) = '00#EK#') and (copy(Data, 8, 1) = '0') then
  begin
      Fno_save := false;//��������� �������� ������������� � ���������� -> ����� � SqlSaveInBuffer
  end;
//{ test }  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 26, 1) = '1') and (no_save = false) then
  if ( copy(Data, 2, 6) = '00#TK#' ) and (copy(Data, 28, 1) = '1')
      and (Fno_save = false) then
  begin
      if ( trim(copy(Data, 40, 6)) <> '' ) then begin //�� ���������� ������ ��������
          if pkdat <> '' then
    //{ test }      SqlSaveInBuffer(trim(copy(Data, 60, 6)))
            SqlSaveInBuffer(trim(copy(Data, 40, 6)))
          else
            lLog.save('w', '��������� �� �������'+#9+'weight -> '+trim(copy(Data, 40, 6)));
        //copy(Data, 2, 6);          //����� �� ����
        //copy(Data, 28, 1);         //�������
        //trim(copy(Data, 40, 6));   //��� ������ ����� �����
      end;
  end;

  //������������
  if assigned(MemoTesting) then
    //MemoTestingAdd('receive Com'+SerialPortSettings.serial_port_number+' | '+Data));
    Synchronize(SyncMemoTesting);

  //����������
  if assigned(CalibrationForm) then
    Synchronize(SyncCalibration);
end;


function TThreadComPort.SendAttribute: boolean;
var
    msg: AnsiString;
begin
  try
    //�������� ��� ����1-4 ���������� 1|0|0|0
    msg := SendReadToSerial(#2'00#EK#1#0#0#0#'#16#3+hash_bcc('00#EK#1#0#0#0#'#16#3));
    ReceiveData(msg);
  except
    on E : Exception do
      lLog.save('e', E.ClassName+#9'com m2, � ����������: '+E.Message);
  end;
end;


function TThreadComPort.CPortParity(InData: String): Char;
{
pNone=0
pOdd=1
pEven=2
pMark=3
pSpace=4
}
begin
  if InData = 'none' then
     result := 'N';
  if InData = 'odd' then
     result := 'O';
  if InData = 'even' then
     result := 'E';
  if InData = 'mark' then
     result := 'M';
  if InData = 'space' then
     result := 'S';
end;


procedure TThreadComPort.SyncMemoTesting;
begin
  MemoTestingAdd('receive Com'+SerialPortSettings.serial_port_number+' | '+FMessageData)
end;


procedure TThreadComPort.SyncStatus;
begin
  form1.no_save := Fno_save;
end;


procedure TThreadComPort.SyncCalibration;
begin
      CalibrationForm.l_calibration.caption := trim(copy(FMessageData, 40, 6));
end;


function TThreadComPort.SqlSaveInBuffer(DataIn: AnsiString): boolean;
var
  num_correct, num_ingot_correct, pkdat_correct: string;
begin

  // ������ ��������� ��������� (��������)
  if MarkerNextWait then
    exit;

  pkdat_correct := ManipulationWithDate(pkdat);
  num_correct := '';
  num_ingot_correct := num_correct;

  if Length(num) = 1 then
    num_correct := '00'+num;
  if Length(num) = 2 then
    num_correct := '0'+num;
  if Length(num) = 3 then
    num_correct := num;
  if Length(num_ingot) = 1 then
    num_ingot_correct := '0'+num_ingot;
  if Length(num_ingot) = 2 then
    num_ingot_correct := num_ingot;

  {$IFDEF DEBUG}
    lLog.save('d', 'pkdat_correct -> '+pkdat_correct);
    lLog.save('d', 'num_correct -> '+num_correct);
    lLog.save('d', 'num_ingot_correct -> '+num_ingot_correct);
  {$ENDIF}

{ id_asutp ������� �� ����� pkdat+num+num_ingot, ��� � ����� pkdat �������
  ��� ����� ����,num �����, num_ingot ����� ������.
  � IT pkdat ������� ���� ����� ���,num ����� (3� ������� ����� ��������� ����� ������
  2 ����), num_ingot (2� ������� ����� ��������� ����� ������ 1 ����)) ����� ������.
}
  try
      TCsqlite.SQuery.Close;
      TCsqlite.SQuery.SQL.Clear;
      TCsqlite.SQuery.SQL.Add('INSERT INTO weight');
      TCsqlite.SQuery.SQL.Add('(pkdat, num, num_ingot, id_asutp, heat, timestamp, weight)');
      TCsqlite.SQuery.SQL.Add('VALUES('+pkdat+', '+num+', '+num_ingot+',');
      TCsqlite.SQuery.SQL.Add(''+pkdat_correct+num_correct+num_ingot_correct+',');
      TCsqlite.SQuery.SQL.Add(''+num_heat+', strftime(''%s'',''now''), '+PointReplace(DataIn)+')');
      TCsqlite.SQuery.ExecSQL;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql save in buffer, � ����������: '+E.Message+' | '+TCsqlite.SQuery.SQL.Text);
  end;

  //ThreadComPort.no_save := true;//��������� �������� ������������� � ����������
  form1.no_save := true;//��������� �������� ������������� � ����������

  try
      TCsqlite.SQuery.Close;
      TCsqlite.SQuery.SQL.Clear;
      TCsqlite.SQuery.SQL.Add('SELECT pkdat, num, num_ingot, id_asutp,');
      TCsqlite.SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'') as timestamp, weight FROM weight');
      TCsqlite.SQuery.SQL.Add('where id_asutp='+pkdat_correct+num_correct+num_ingot_correct+'');
      TCsqlite.SQuery.Open;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql select in buffer, � ����������: '+E.Message+' | '+TCsqlite.SQuery.SQL.Text);
  end;
  //save to log file
  {lLog.save('sql'+#9#9+'write'+#9+'id_asutp -> '+SQuery.FieldByName('id_asutp').AsString);
  lLog.save('sql'+#9#9+'write'+#9+'weight -> '+SQuery.FieldByName('weight').AsString);}

  //��������� ���������
  ShowTrayMessage('���������', '�: '+num_ingot+#9+'���: '+TCsqlite.SQuery.FieldByName('weight').AsString, 1);

  {$IFDEF DEBUG}
    lLog.save('d', 'pkdat_correct -> '+ TCsqlite.SQuery.FieldByName('id_asutp').AsString);
  {$ENDIF}

  //��������� ������ (������) �� ���������
  Synchronize(NextWeightToRecord);
end;




// ��� �������� ��������� ����� ����� �����������
initialization
//ThreadComPort := TThreadComPort.Create;


// ��� �������� ��������� ������������
finalization
//ThreadComPort.Destroy;


end.

