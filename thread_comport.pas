unit thread_comport;


interface

uses
  SysUtils, Classes, ActiveX, synaser, SyncObjs, logging, Messages, ZDataset,
  strutils, Variants, sql;

type
  //Здесь необходимо описать класс TThreadComPort:
  TThreadComPort = class(TThread)

  private
    Fno_save: boolean;
    FThreadComPort: TThreadComPort;
    FMessageData: AnsiString;
    FNextSave: boolean;
    Fpkdat: string;
    Fnum: string;
    Fnum_ingot: string;

    function CPortParity(InData: String): Char;
    function SendReadToSerial(InData: AnsiString): AnsiString;
    function hash_bcc(InChar: string): Char;

    procedure SendTKMessage;
    function ReceiveTKData(Data: AnsiString): string;
    function SendEKMessage: boolean;
    function ReceiveEKData(Data: AnsiString): string;
    function ComparePkdat: boolean;

    procedure SyncMemoTesting;
    procedure SyncCalibration;
    function SqlSaveInBuffer(DataIn: AnsiString): boolean;
    function ManipulationWithDate(InDate: string): string;
    procedure SyncNextWeightToRecord;
  protected
    procedure Execute; override;
  public
    Constructor Create(_Log: TLog); overload;
    Destructor Destroy; override;
  published
    property NextSave: boolean read FNextSave write FNextSave;
    property no_save: boolean read Fno_save write Fno_save;
    property SendAttribute: boolean read SendEKMessage;
{    property Apkdat: string read Fpkdat;
    property Anum: string read Fnum write Fnum;
    property Anum_ingot: string read Fnum_ingot write Fnum_ingot;}
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

  Fno_save := false;
  FNextSave := true;

  // создаем поток True - создание остановка, False - создание старт
  FThreadComPort := TThreadComPort.Create(True);
  FThreadComPort.Priority := tpNormal;
  FThreadComPort.FreeOnTerminate := True;
  FThreadComPort.Start;
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
  FNextSave := true; //не правильно
  while True do
  begin
      try
{$IFDEF DEBUG}
  lLog.save('t', 'step 1');
{$ENDIF}
          // при выбор заготовки останавливаем чтение
          if not ThreadStop and not MarkerNextWait then begin
//              lLog.save('t', 'NextSave | '+booltostr(NextSave)+' | '+booltostr(FNextSave));
              //тестирование
              if assigned(MemoTesting) then
                 Synchronize(@SyncMemoTesting);
              //калибровка
              if assigned(CalibrationForm) then
                 Synchronize(@SyncCalibration);
//              lLog.save('e', 'main do NextSave | '+booltostr(NextSave)+' | '+booltostr(FNextSave));
              if NextSave and not MarkerNextWait then
                 SendTKMessage;

              if no_save then begin
                 SendEKMessage;
              end;
//              lLog.save('e', 'main NextSave | '+booltostr(NextSave)+' | '+booltostr(FNextSave));
              if not NextSave then
                 Synchronize(@SyncNextWeightToRecord);
          end
          else
              sleep(1000);
      except
        on E : Exception do
          lLog.save('e', E.ClassName+' serial execute, с сообщением: '+E.Message);
      end;
   end;
   CoUninitialize;
end;


function TThreadComPort.SendReadToSerial(InData: AnsiString): AnsiString;
var
  serial_port: TBlockserial;
begin
    try
        serial_port := TBlockserial.Create;
        serial_port.RaiseExcept := false; //false игнорировать ошибки порта
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


procedure TThreadComPort.SendTKMessage;
var
    msg: AnsiString;
begin
  try
{$IFDEF DEBUG}
  lLog.save('t', 'step 2');
{$ENDIF}
         msg := SendReadToSerial(#2'00#TK#'#16#3+hash_bcc('00#TK#'#16#3));
         FMessageData := msg;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' send tk attribute, с сообщением: '+E.Message);
  end;

  try
         ReceiveTKData(msg);
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' recive tk, с сообщением: '+E.Message);
  end;
end;


function TThreadComPort.SendEKMessage: boolean;
var
    msg: AnsiString;
begin
  try
{$IFDEF DEBUG}
  lLog.save('t', 'step 4');
{$ENDIF}
     //передаем ЭОД вход1-4 переменные 1|0|0|0
     msg := SendReadToSerial(#2'00#EK#1#0#0#0#'#16#3+hash_bcc('00#EK#1#0#0#0#'#16#3));
     FMessageData := msg;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' send ek attribute, с сообщением: '+E.Message);
  end;

  try
      ReceiveEKData(msg);
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' recive ek, с сообщением: '+E.Message);
  end;
end;


function TThreadComPort.ReceiveTKData(Data: AnsiString): string;
begin
{$IFDEF DEBUG}
  lLog.save('t', 'TK marker | '+copy(Data, 28, 1)+' | no_save | '+booltostr(no_save)+' | NextSave | '+booltostr(NextSave));
{$ENDIF}
//{ test }  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 26, 1) = '1') and (no_save = false) then
  if ( {copy(Data, 2, 6) = '00#TK#' )
       and} (copy(Data, 28, 1) = '1')
       and (no_save = false) ) then
  begin
{$IFDEF DEBUG}
  lLog.save('t', 'step 3');
{$ENDIF}
      if ( trim(copy(Data, 40, 6)) <> '' ) then begin //не пропускать пустых значений
          if pkdat <> '' then begin
    //{ test }      SqlSaveInBuffer(trim(copy(Data, 60, 6)))
            SqlSaveInBuffer(trim(copy(Data, 40, 6)));
            NextSave := false;
//            lLog.save('w', 'ReceiveTKData | '+trim(copy(Data, 40, 6)));
          end
          else
            lLog.save('w', 'заготовка не выбрана'+#9+'weight | '+trim(copy(Data, 40, 6)));
        //copy(Data, 2, 6);          //ответ по весу
        //copy(Data, 28, 1);         //признак
        //trim(copy(Data, 40, 6));   //вес только целая часть
      end;
  end;
end;


function TThreadComPort.ReceiveEKData(Data: AnsiString): string;
begin
  if (copy(Data, 2, 6) = '00#EK#') and (copy(Data, 8, 1) = '0') then
  begin
{$IFDEF DEBUG}
  lLog.save('t', 'step 5');
{$ENDIF}
      no_save := false;//запрещаем отправку подтверждения в контроллер -> сброс в SqlSaveInBuffer
  end;
end;


function TThreadComPort.hash_bcc(InChar: string): char;
var
    i: byte;
begin
  result := InChar[1];
  for i := 2 to length(InChar) do
  result := char(ord(result) xor ord(InChar[i]));
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


procedure TThreadComPort.SyncCalibration;
begin
     if assigned(CalibrationForm.l_calibration) then
        CalibrationForm.l_calibration.caption := trim(copy(FMessageData, 40, 6));
end;


function TThreadComPort.SqlSaveInBuffer(DataIn: AnsiString): boolean;
var
  num_correct, num_ingot_correct, pkdat_correct: string;
begin
{$IFDEF DEBUG}
  lLog.save('e', 'no_save | '+booltostr(no_save)+' | false '+booltostr(false));
{$ENDIF}

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

{ id_asutp состоит из полей pkdat+num+num_ingot, где в АСУТП pkdat состоит
  год месяц день,num номер, num_ingot номер слитка.
  в IT pkdat состоит день месяц год,num номер (3х значное нужно добавлять перед числом
  2 нуля), num_ingot (2х значное нужно добавлять перед числом 1 ноль)) номер слитка.
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
      lLog.save('e', E.ClassName+' sql save in buffer, с сообщением: '+E.Message+' | '+TCsqlite.SQuery.SQL.Text);
  end;

  no_save := true;//разрешаем отправку подтверждения в контроллер
end;


procedure TThreadComPort.SyncNextWeightToRecord;
var
  t: boolean;
begin
{$IFDEF DEBUG}
  lLog.save('t', 'step 6');
{$ENDIF}
     SqlNextWeightToRecord;
     NextWeightToRecordLocation;
//     lLog.save('t', 'do pkdat | '+pkdat+' | '+Fpkdat+' | num | '+num+' | '+Fnum+' | num_ingot | '+num_ingot+' | '+Fnum_ingot);
     t := ComparePkdat;//разрешаем снятие следующего показания
     //NextSave := ComparePkdat;//разрешаем снятие следующего показания
     NextSave := t;
//     lLog.save('t', 'after pkdat | '+pkdat+' | '+Fpkdat+' | num | '+num+' | '+Fnum+' | num_ingot | '+num_ingot+' | '+Fnum_ingot);
//     lLog.save('t', 'SyncNextWeightToRecord | ComparePkdat | '+booltostr(t));
end;


// изменение последовательноси 1401292 -> 2901142, для id_asutp
function TThreadComPort.ManipulationWithDate(InDate: string): string;
var
  pkdat_correct: string;
begin
    pkdat_correct := InDate;
    pkdat_correct := StuffString(pkdat_correct, 5, 2, copy(InDate, 1,2));
    pkdat_correct := StuffString(pkdat_correct, 1, 2, copy(InDate, 5,2));
    Result := pkdat_correct;
end;


function TThreadComPort.ComparePkdat: boolean;
begin
//  lLog.save('t', 'pkdat | '+pkdat+' | '+Fpkdat+' | num | '+num+' | '+Anum+' | num_ingot | '+num_ingot+' | '+Anum_ingot);
//  lLog.save('t', pkdat+' | '+num+' | '+num_ingot);
  if (pkdat = Fpkdat) and (num = Fnum) and (num_ingot = Fnum_ingot) then
     Result := false
  else begin
     Fpkdat := pkdat;
     Fnum := num;
     Fnum_ingot := num_ingot;
     Result := true;
  end;
end;


end.

