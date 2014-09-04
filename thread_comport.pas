unit thread_comport;


interface

uses
  SysUtils, Classes, Windows, ActiveX, synaser;

type
  //����� ���������� ������� ����� TThreadComPort:
  TThreadComPort = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  public
    Constructor Create; overload;
    Destructor Destroy; override;
  end;

var
  ThreadComPort: TThreadComPort;
  no_save: bool = false;

  function CPortParity(InData: String): Char;
  procedure WrapperComPort;//������� ��� ������������� � ���������� � ������ �������
  function SendReadToSerial(InData: AnsiString): AnsiString;
  function ReadToMessage: boolean;
  function SendAttribute: boolean;
  function hash_bcc(InChar: string): Char;
  function ReceiveData(Data: AnsiString): string;


//  {$DEFINE DEBUG}


implementation

uses
  main, logging, settings, sql, testing;




constructor TThreadComPort.Create;
begin
  inherited;
  // ������� ����� True - �������� ���������, False - �������� �����
  ThreadComPort := TThreadComPort.Create(True);
  ThreadComPort.Priority := tpNormal;
  ThreadComPort.FreeOnTerminate := True;
  ThreadComPort.Start;
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
      Synchronize(WrapperComPort);
      sleep(1500);
   end;
   CoUninitialize;
end;


procedure WrapperComPort;
begin
  try
      ReadToMessage;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function SendReadToSerial(InData: AnsiString): AnsiString;
var
  serial_port: TBlockserial;
begin
    serial_port := TBlockserial.Create;
    serial_port.RaiseExcept := false; //false ������������ ������ �����
    try
       serial_port.Connect('COM'+ComPortConfigArray[5]);
       if serial_port.InstanceActive then begin
//          serial_port.Config(19200,8,'E',SB2,false,false);
          serial_port.Config(strtoint(ComPortConfigArray[1]),
                             strtoint(ComPortConfigArray[2]),
                             CPortParity(ComPortConfigArray[3]),
                             strtoint(ComPortConfigArray[4]),false,false);
          serial_port.SendString(InData);
          sleep(200);
          Result := serial_port.RecvBufferStr(serial_port.WaitingData, 200);
       end;
    finally
        serial_port.Free;
    end;
end;


function ReadToMessage: boolean;
var
    msg: AnsiString;
begin
  msg := SendReadToSerial(#2'00#TK#'#16#3+hash_bcc('00#TK#'#16#3));

  ReceiveData(msg);

  if no_save then
    SendAttribute;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'no_save -> '+booltostr(no_save));
  {$ENDIF}
end;


function hash_bcc(InChar: string): char;
var
    i: byte;
begin
  result := InChar[1];
  for i := 2 to length(InChar) do
  result := char(ord(result) xor ord(InChar[i]));
end;


function ReceiveData(Data: AnsiString): string;
begin
  if (copy(Data, 2, 6) = '00#EK#') and (copy(Data, 8, 1) = '0') then
  begin
      no_save := false;//��������� �������� ������������� � ���������� -> ����� � SqlSaveInBuffer
  end;
//{ test }  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 26, 1) = '1') and (no_save = false) then
  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 28, 1) = '1') and (no_save = false) then
  begin
      if pkdat <> '' then
//{ test }      SqlSaveInBuffer(trim(copy(Data, 60, 6)))
        SqlSaveInBuffer(trim(copy(Data, 40, 6)))
      else
        SaveLog('warning'+#9#9+'��������� �� �������'+#9+'weight -> '+trim(copy(Data, 40, 6)));
    //copy(Data, 2, 6);          //����� �� ����
    //copy(Data, 28, 1);         //�������
    //trim(copy(Data, 40, 6));   //��� ������ ����� �����
  end;

  //������������
  if TestingStatus then
    MemoTestingAdd('receive Com'+ComPortConfigArray[5]+' -> '+Data);
end;


function SendAttribute: boolean;
var
    msg: AnsiString;
begin
  try
    //�������� ��� ����1-4 ���������� 1|0|0|0
    msg := SendReadToSerial(#2'00#EK#1#0#0#0#'#16#3+hash_bcc('00#EK#1#0#0#0#'#16#3));
    ReceiveData(msg);
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function CPortParity(InData: String): Char;
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

