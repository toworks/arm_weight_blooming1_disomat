unit thread_comport;


interface

uses
  SysUtils, Classes, Windows, ActiveX, Graphics, Forms, AdPort, OoMisc, AdPacket;

type
  //����� ���������� ������� ����� TThreadComPort:
  TThreadComPort = class(TThread)

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
  ThreadComPort: TThreadComPort;
  no_save: bool = false;

  function ThreadComPortInit: bool;
  function ConfigComPort(InData: bool): bool;
  function CPortParity(InData: String): Integer;
  procedure WrapperComPort;//������� ��� ������������� � ���������� � ������ �������
  function ReadComPort: bool;
  function hash_bcc(InChar: string): Char;
  function ReceiveData(Data: AnsiString): string;
  function SendAttribute: Bool;


//  {$DEFINE DEBUG}


implementation

uses
  main, logging, settings, module, sql;





procedure TThreadComPort.Execute;
begin
  CoInitialize(nil);
  while True do
   begin
      Synchronize(WrapperComPort);
      sleep(500);
   end;
   CoUninitialize;
end;


function ThreadComPortInit: bool;
begin
        //������� �����
        ThreadComPort := TThreadComPort.Create(False);
        ThreadComPort.Priority := tpNormal;
        ThreadComPort.FreeOnTerminate := True;
end;


function ConfigComPort(InData: bool): bool;
begin
  //init port
  if InData then
   begin
    try
        Module1.ApdComPort1.Baud := strtoint(ComPortConfigArray[1]);
        Module1.ApdComPort1.DataBits := strtoint(ComPortConfigArray[2]);
        Module1.ApdComPort1.Parity := TParity(CPortParity(AnsiLowerCase(ComPortConfigArray[3])));
        Module1.ApdComPort1.StopBits := strtoint(ComPortConfigArray[4]);
        Module1.ApdComPort1.RS485Mode := false;
        Module1.ApdComPort1.RTS := true;
        Module1.ApdComPort1.LogHex := false;
        Module1.ApdComPort1.TraceHex := false;

        //������������� ������ ������
        Module1.ApdDataPacket1.ComPort := Module1.ApdComPort1;
        Module1.ApdDataPacket1.StartCond := scString;
        Module1.ApdDataPacket1.StartString := #2; //start bit
        Module1.ApdDataPacket1.EndCond := [ecString];
        Module1.ApdDataPacket1.EndString := #3; //stop bit
        Module1.ApdDataPacket1.IncludeStrings := true;
        Module1.ApdDataPacket1.Enabled := true;

        Module1.ApdComPort1.ComNumber := strtoint(ComPortConfigArray[5]);
        Module1.ApdComPort1.Open := true;
    except
      on E : Exception do
        SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
    end;
   end
  else
   begin
        Module1.ApdDataPacket1.Enabled := false;
        Module1.ApdComPort1.Open := False;
   end;
end;


procedure WrapperComPort;
begin
  try
      Application.ProcessMessages;//��������� �������� �� �������� ���������
      ReadComPort;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
end;


function ReadComPort: bool;
begin

  //��������� ������ � �����
  Module1.ApdComPort1.OutPut := #2'00#TK#'#16#3+hash_bcc('00#TK#'#16#3);

  Form1.Caption := HeadName+' v'+Version+'  '+timetostr(time);

  if no_save then
    SendAttribute;

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
      no_save := false;
  end;

  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 28, 1) = '1') and (no_save = false) then
  begin
      if pkdat <> '' then
       begin
          SqlSaveInBuffer(trim(copy(Data, 40, 6)));
          no_save := true;
       end
      else
        SaveLog('warning'+#9#9+'��������� �� �������'+#9+'weight -> '+trim(copy(Data, 40, 6)));
    //copy(Data, 2, 6);          //����� �� ����
    //copy(Data, 28, 1);         //�������
    //trim(copy(Data, 40, 6));   //��� ������ ����� �����
  end;
end;


function SendAttribute: Bool;
begin
      //�������� ��� ����1-4 ���������� 1|0|0|0
      Module1.ApdComPort1.OutPut := #2'00#EK#1#0#0#0#'#16#3+hash_bcc('00#EK#1#0#0#0#'#16#3);
end;


function CPortParity(InData: String): Integer;
{
pNone=0
pOdd=1
pEven=2
pMark=3
pSpace=4
}
begin
  if InData = 'none' then
     result := 0;
  if InData = 'odd' then
     result := 1;
  if InData = 'even' then
     result := 2;
  if InData = 'mark' then
     result := 3;
  if InData = 'space' then
     result := 4;
end;




end.
