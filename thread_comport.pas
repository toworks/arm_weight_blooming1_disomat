unit thread_comport;


interface

uses
  SysUtils, Classes, ActiveX, synaser, SyncObjs, logging, Messages;

type
  //����� ���������� ������� ����� TThreadComPort:
  TThreadComPort = class(TThread)

  private
    Fcount: integer;
    Fno_save: boolean;
    FThreadComPort: TThreadComPort;
    FMessageData: AnsiString;

    procedure ReadToMessage;
    procedure SyncMemoTesting;
    procedure SyncStatus;
  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;

    function CPortParity(InData: String): Char;
    function SendReadToSerial(InData: AnsiString): AnsiString;
    function SendAttribute: boolean;
    function hash_bcc(InChar: string): Char;
    function ReceiveData(Data: AnsiString): string;
  end;

var

  Log: TLog;
//    function SendAttribute: boolean;


//  {$DEFINE DEBUG}


implementation

uses
  settings, main, sql, testing, calibration;




constructor TThreadComPort.Create(_Log: TLog);
begin
  inherited Create(True);

  Log := _Log;
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
          Log.save('e', E.ClassName+#9'com m1, � ����������: '+E.Message);
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
          Result := serial_port.RecvBufferStr(serial_port.WaitingData, 200);
       end;
    finally
          FreeAndNil(serial_port);
    end;
end;


procedure TThreadComPort.ReadToMessage;
var
    msg: AnsiString;
begin
  msg := SendReadToSerial(#2'00#TK#'#16#3+hash_bcc('00#TK#'#16#3));

  ReceiveData(msg);

  if Fno_save then
    SendAttribute;

  {$IFDEF DEBUG}
    Log.save('d', 'no_save | '+booltostr(no_save));
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
            Log.save('w', '��������� �� �������'+#9+'weight -> '+trim(copy(Data, 40, 6)));
        //copy(Data, 2, 6);          //����� �� ����
        //copy(Data, 28, 1);         //�������
        //trim(copy(Data, 40, 6));   //��� ������ ����� �����
      end;
  end;

  //������������
  if assigned(MemoTesting) then begin
    //MemoTestingAdd('receive Com'+SerialPortSettings.serial_port_number+' | '+Data));
    FMessageData := Data;
    Synchronize(SyncMemoTesting);
  end;

  //����������
  if assigned(CalibrationForm) then
    CalibrationForm.l_calibration.caption := trim(copy(Data, 40, 6));
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
      Log.save('e', E.ClassName+#9'com m2, � ����������: '+E.Message);
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




// ��� �������� ��������� ����� ����� �����������
initialization
//ThreadComPort := TThreadComPort.Create;


// ��� �������� ��������� ������������
finalization
//ThreadComPort.Destroy;


end.

