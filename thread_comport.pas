unit thread_comport;


interface

uses
  SysUtils, Classes, ActiveX, synaser, SyncObjs, logging, Messages, ZDataset,
  strutils, Variants, sql;

type
  //Здесь необходимо описать класс TThreadComPort:
  TThreadComPort = class(TThread)

  private
//    Fcount: integer;
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
    function ManipulationWithDate(InDate: string): string;
    procedure SyncNextWeightToRecord;
    procedure SyncNextWeightToRecordLocation;
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
  // создаем поток True - создание остановка, False - создание старт
  FThreadComPort := TThreadComPort.Create(True);
  FThreadComPort.Priority := tpNormal;
  FThreadComPort.FreeOnTerminate := True;
  FThreadComPort.Start;

  Fno_save := false;
//  Fcount := 10;
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

          //тестирование
          if assigned(MemoTesting) then
             Synchronize(@SyncMemoTesting);
          //калибровка
          if assigned(CalibrationForm) then
             Synchronize(@SyncCalibration);
//          Synchronize(SyncStatus);
          ReadToMessage;
          if Fno_save then
             SendAttribute;
      except
        on E : Exception do
          lLog.save('e', E.ClassName+' serial execute, с сообщением: '+E.Message);
      end;

//      sleep(1000);
   end;
   CoUninitialize;
end;


function TThreadComPort.SendReadToSerial(InData: AnsiString): AnsiString;
var
  serial_port: TBlockserial;
begin
    //status работы с контроллером
//    if Fcount > 5 then begin
//      Synchronize(Status);
//      Fcount := 0;
//    end
//    else
//      inc(Fcount);

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


procedure TThreadComPort.ReadToMessage;
var
    msg: AnsiString;
begin
  try
         msg := SendReadToSerial(#2'00#TK#'#16#3+hash_bcc('00#TK#'#16#3));
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' serial send/read, с сообщением: '+E.Message);
  end;

  try
      ReceiveData(msg);
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' serial recive, с сообщением: '+E.Message);
  end;

{  if Fno_save then
    SendAttribute;

  {$IFDEF DEBUG}
    lLog.save('d', 'no_save | '+booltostr(Fno_save));
  {$ENDIF}}
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

  lLog.save('d', 'ReceiveData | '+Data);
  lLog.save('w', 'pkdat | '+pkdat+' | num | '+num+' | num_ingot | '+num_ingot);

  if (copy(Data, 2, 6) = '00#EK#') and (copy(Data, 8, 1) = '0') then
  begin
      Fno_save := false;//запрещаем отправку подтверждения в контроллер -> сброс в SqlSaveInBuffer
  end;
//{ test }  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 26, 1) = '1') and (no_save = false) then
  if ( copy(Data, 2, 6) = '00#TK#' ) and (copy(Data, 28, 1) = '1')
      and (Fno_save = false) then
  begin
      if ( trim(copy(Data, 40, 6)) <> '' ) then begin //не пропускать пустых значений
          if pkdat <> '' then
    //{ test }      SqlSaveInBuffer(trim(copy(Data, 60, 6)))
            SqlSaveInBuffer(trim(copy(Data, 40, 6)))
          else
            lLog.save('w', 'заготовка не выбрана'+#9+'weight -> '+trim(copy(Data, 40, 6)));
        //copy(Data, 2, 6);          //ответ по весу
        //copy(Data, 28, 1);         //признак
        //trim(copy(Data, 40, 6));   //вес только целая часть
      end;
  end;

{  //тестирование
  if assigned(MemoTesting) then
//    Synchronize(SyncMemoTesting);

  //калибровка
  if assigned(CalibrationForm) then
//    Synchronize(SyncCalibration);}
end;


function TThreadComPort.SendAttribute: boolean;
var
    msg: AnsiString;
begin
  try
    //передаем ЭОД вход1-4 переменные 1|0|0|0
    msg := SendReadToSerial(#2'00#EK#1#0#0#0#'#16#3+hash_bcc('00#EK#1#0#0#0#'#16#3));
    ReceiveData(msg);
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' com send attribute, с сообщением: '+E.Message);
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
//  form1.no_save := Fno_save;
end;


procedure TThreadComPort.SyncCalibration;
begin
      CalibrationForm.l_calibration.caption := trim(copy(FMessageData, 40, 6));
end;


function TThreadComPort.SqlSaveInBuffer(DataIn: AnsiString): boolean;
var
  num_correct, num_ingot_correct, pkdat_correct: string;
begin

  lLog.save('e', 'Fno_save | '+booltostr(Fno_save)+' | false '+booltostr(false));

  // маркер следующей заготовки (ожидание)
  if MarkerNextWait then
    exit;

  //следующая запись (слиток) от записаной
  Synchronize(@SyncNextWeightToRecord);

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

  //ThreadComPort.no_save := true;//разрешаем отправку подтверждения в контроллер
  //form1.no_save := true;//разрешаем отправку подтверждения в контроллер
  Fno_save := true;//разрешаем отправку подтверждения в контроллер
  //Synchronize(SyncStatus);

  try
      TCsqlite.SQuery.Close;
      TCsqlite.SQuery.SQL.Clear;
      TCsqlite.SQuery.SQL.Add('SELECT pkdat, num, num_ingot, id_asutp,');
      TCsqlite.SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'') as timestamp, weight FROM weight');
      TCsqlite.SQuery.SQL.Add('where id_asutp='+pkdat_correct+num_correct+num_ingot_correct+'');
      TCsqlite.SQuery.Open;
  except
    on E : Exception do
      lLog.save('e', E.ClassName+' sql select in buffer, с сообщением: '+E.Message+' | '+TCsqlite.SQuery.SQL.Text);
  end;
  //save to log file
  {lLog.save('sql'+#9#9+'write'+#9+'id_asutp -> '+SQuery.FieldByName('id_asutp').AsString);
  lLog.save('sql'+#9#9+'write'+#9+'weight -> '+SQuery.FieldByName('weight').AsString);}

  //сообщение оператору
//  ShowTrayMessage('Заготовка', '№: '+num_ingot+#9+'вес: '+TCsqlite.SQuery.FieldByName('weight').AsString, 1);

  {$IFDEF DEBUG}
    lLog.save('d', 'pkdat_correct -> '+ TCsqlite.SQuery.FieldByName('id_asutp').AsString);
  {$ENDIF}
end;


procedure TThreadComPort.SyncNextWeightToRecord;
var
  KeyValues : Variant;
begin
  try
      //отключаем управление
      form1.DBGrid1.DataSource.DataSet.DisableControls;
      SqlNextWeightToRecord;
      //dbgrid текущая выбраная заготовка
      Synchronize(@SyncNextWeightToRecordLocation);
  finally
      //включаем управление
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;
end;


procedure TThreadComPort.SyncNextWeightToRecordLocation;
var
  KeyValues : Variant;
begin
  try
      //отключаем управление
      form1.DBGrid1.DataSource.DataSet.DisableControls;
      //переменные по которым будет производиться поиск
      KeyValues := VarArrayOf([pkdat,num,num_ingot]);
      //поиск по ключивым полям
      form1.DBGrid1.DataSource.DataSet.Locate('pkdat;num;num_ingot', KeyValues, []);
  finally
      //включаем управление
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;
  //-- test
  //Form1.l_next_id.Caption:=pkdat+'|'+num+'|'+num_ingot;
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




// При загрузке программы класс будет создаваться
initialization
//ThreadComPort := TThreadComPort.Create;


// При закрытии программы уничтожаться
finalization
//ThreadComPort.Destroy;


end.

