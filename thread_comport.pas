unit thread_comport;


interface

uses
  SysUtils, Classes, Windows, ActiveX, synaser;

type
  //����� ���������� ������� ����� TThreadComPort:
  TThreadComPort = class(TThread)

  private
    procedure ReadToMessage;

    var
      count: integer;
  protected
    procedure Execute; override;
  public
    Constructor Create; overload;
    Destructor Destroy; override;

    function CPortParity(InData: String): Char;
    function SendReadToSerial(InData: AnsiString): AnsiString;
    function SendAttribute: boolean;
    function hash_bcc(InChar: string): Char;
    function ReceiveData(Data: AnsiString): string;
  end;

var
  ThreadComPort: TThreadComPort;
  no_save: bool = false;


//  {$DEFINE DEBUG}


implementation

uses
  main, logging, settings, sql, testing, calibration;




constructor TThreadComPort.Create;
begin
  inherited;
  // ������� ����� True - �������� ���������, False - �������� �����
  ThreadComPort := TThreadComPort.Create(True);
  ThreadComPort.Priority := tpNormal;
  ThreadComPort.FreeOnTerminate := True;
  ThreadComPort.Start;

  count := 10;
end;


destructor TThreadComPort.Destroy;
begin
  if ThreadComPort <> nil then begin
    ThreadComPort.Terminate;
  end;
  inherited Destroy;
end;


procedure TThreadComPort.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      Synchronize(ReadToMessage);
      sleep(1000);
   end;
   CoUninitialize;
end;


function TThreadComPort.SendReadToSerial(InData: AnsiString): AnsiString;
var
  serial_port: TBlockserial;
begin
    //status ������ � ������������
    if count > 10 then begin
      Status;
      count := 0;
    end
    else
      inc(count);

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

  if no_save then
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
      no_save := false;//��������� �������� ������������� � ���������� -> ����� � SqlSaveInBuffer
  end;
//{ test }  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 26, 1) = '1') and (no_save = false) then
  if ( copy(Data, 2, 6) = '00#TK#' ) and (copy(Data, 28, 1) = '1')
      and (no_save = false) then
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
  if assigned(MemoTesting) then
    MemoTestingAdd('receive Com'+SerialPortSettings.serial_port_number+' | '+Data);

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
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
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


// ��� �������� ��������� ����� ����� �����������
initialization
ThreadComPort := TThreadComPort.Create;


// ��� �������� ��������� ������������
finalization
ThreadComPort.Destroy;


end.

