{

CREATE TABLE settings (
    name  VARCHAR( 50 )   PRIMARY KEY
                          NOT NULL
                          UNIQUE,
    value VARCHAR( 256 )
);

INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::ip', '10.21.22.22');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::user', 'sysdba');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::password', 'masterkey');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::db_name', 'c:\Account.gdb');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::library', 'fbclient.dll');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::ip', 'krr-sql24');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::user', 'asutp');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::password', 'bl2');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::db_name', 'reserv');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::dialect', 3);
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::port', 1521);
INSERT INTO [settings] ([name], [value]) VALUES ('::ComPort::baud', 9600);
INSERT INTO [settings] ([name], [value]) VALUES ('::ComPort::data_bits', 8);
INSERT INTO [settings] ([name], [value]) VALUES ('::ComPort::parity', 'Even');
INSERT INTO [settings] ([name], [value]) VALUES ('::ComPort::stop_bits', 1);
INSERT INTO [settings] ([name], [value]) VALUES ('::ComPort::number', 1);

}

unit settings;

interface

uses
  SysUtils, Classes, Windows, ActiveX, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, ZAbstractRODataset, ZStoredProcedure,
  logging, sql;

type
  TSettings = class

  private
    FCurrentDir: string;
    Fsqlite: TSqlite;

    function SqlLocalCreateTable: boolean;
    function ReadConfigSettings: boolean;
    function FGetVersion: string;// Версия сборки программы
    function FHeadName: string;
    function FDBFile: string;
  public
    Constructor Create; overload;
    Destructor Destroy; override;

    property HeadName: string read FHeadName;
    property DBFile: string read FDBFile;
    property CurrentDir: string read FCurrentDir;
    property GetVersion: string read FGetVersion;
  end;

  TSqlSettings = Record
    ip            : string[20];
    port          : string[10];
    db_name       : string[255];
    lib           : string[20];
    dialect       : string[1];
    user          : string[50];
    password      : string[50];
  end;

  TSerialSettings = Record
    baud                  : string[10];
    data_bits             : string[1];
    parity                : string[10];
    stop_bits             : string[1];
    serial_port_number    : string[3];
  end;

var
   Log: TLog;
   SettingsApp: TSettings;

   FbSqlSettings: TSqlSettings;
   OraSqlSettings: TSqlSettings;
   SerialPortSettings: TSerialSettings;


//   {$DEFINE DEBUG}



implementation

uses
  main;


constructor TSettings.Create;
begin
  inherited Create;

  //текущая дириктория
  FCurrentDir := GetCurrentDir;

  Fsqlite := TSqlite.Create(Log);

  ReadConfigSettings;
//  ConfigFirebirdSetting(true);
  SqlLocalCreateTable; //create local sqlite table
end;


destructor TSettings.Destroy;
begin
//  ConfigFirebirdSetting(false);
  inherited Destroy;
end;


function TSettings.FHeadName: string;
var
  HeadName: string;
begin
  HeadName := ' АРМ резчика ПУ-4 ';
  result := HeadName;
end;


function TSettings.FDBFile: string;
var
  DBFile: string;
begin
  DBFile := 'data.sdb';
  result := DBFile;
end;


function TSettings.ReadConfigSettings: boolean;
var
  i: integer;
begin
    try
        Fsqlite.SQuery.Close;
        Fsqlite.SQuery.SQL.Clear;
        Fsqlite.SQuery.SQL.Add('SELECT * FROM settings');
        Fsqlite.SQuery.Open;
    except
      on E : Exception do
        Log.save('e', E.ClassName+' read settings, с сообщением: '+E.Message);
    end;

    while not Fsqlite.SQuery.Eof do
     begin
      //fbsql
      if Fsqlite.SQuery.FieldByName('name').AsString = '::FbSql::ip' then
        FbSqlSettings.ip := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::FbSql::db_name' then
        FbSqlSettings.db_name := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::FbSql::library' then
        FbSqlSettings.lib := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::FbSql::dialect' then
        FbSqlSettings.dialect := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::FbSql::user' then
        FbSqlSettings.user := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::FbSql::password' then
        FbSqlSettings.password := Fsqlite.SQuery.FieldByName('value').AsString;

      //orasql
      if Fsqlite.SQuery.FieldByName('name').AsString = '::OraSql::ip' then
        OraSqlSettings.ip := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::OraSql::port' then
        OraSqlSettings.port := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::OraSql::db_name' then
        OraSqlSettings.db_name := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::OraSql::user' then
        OraSqlSettings.user := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::OraSql::password' then
        OraSqlSettings.password := Fsqlite.SQuery.FieldByName('value').AsString;

      //comport
      if Fsqlite.SQuery.FieldByName('name').AsString = '::ComPort::baud' then
        SerialPortSettings.baud := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::ComPort::data_bits' then
        SerialPortSettings.data_bits := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::ComPort::parity' then
        SerialPortSettings.parity := AnsiLowerCase(Fsqlite.SQuery.FieldByName('value').AsString);
      if Fsqlite.SQuery.FieldByName('name').AsString = '::ComPort::stop_bits' then
        SerialPortSettings.stop_bits := Fsqlite.SQuery.FieldByName('value').AsString;
      if Fsqlite.SQuery.FieldByName('name').AsString = '::ComPort::number' then
        SerialPortSettings.serial_port_number := Fsqlite.SQuery.FieldByName('value').AsString;

        Fsqlite.SQuery.Next;
     end;

 {$IFDEF DEBUG}
  Log.save('d', 'SerialPortSettings.baud -> '+SerialPortSettings.baud);
  Log.save('d', 'SerialPortSettings.data_bits -> '+SerialPortSettings.data_bits);
  Log.save('d', 'SerialPortSettings.parity -> '+SerialPortSettings.parity);
  Log.save('d', 'SerialPortSettings.stop_bits -> '+SerialPortSettings.stop_bits);
  Log.save('d', 'SerialPortSettings.serial_port_number -> '+SerialPortSettings.serial_port_number);
 {$ENDIF}

end;


function TSettings.FGetVersion: string;
type
  TVerInfo=packed record
    Nevazhno: array[0..47] of byte; // ненужные нам 48 байт
    Minor, Major, Build, Release: word; // а тут версия
  end;
var
  s: TResourceStream;
  v: TVerInfo;
begin
  result := '';
  try
    s := TResourceStream.Create(HInstance, '#1', RT_VERSION); // достаём ресурс
    if s.Size > 0 then begin
      s.Read(v,SizeOf(v)); // читаем нужные нам байты
      result := Format('%d%d%d%d', [v.Major, v.Minor, v.Release, v.Build]);
   end;
  finally
      s.Free;
  end;
end;


function TSettings.SqlLocalCreateTable: boolean;
var
  sindex: string;
begin
{ id_asutp состоит из полей pkdat+num+num_ingot, где в АСУТП pkdat состоит
  год месяц день,num номер, num_ingot номер слитка.
  в IT pkdat состоит день месяц год,num номер (3х значное нужно добавлять перед числом
  2 нуля), num_ingot (2х значное нужно добавлять перед числом 1 ноль)) номер слитка.
}
  try
      Fsqlite.SQuery.Close;
      Fsqlite.SQuery.SQL.Clear;
      Fsqlite.SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS weight');
      Fsqlite.SQuery.SQL.Add('(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
      Fsqlite.SQuery.SQL.Add(', pkdat NUMERIC(7) NOT NULL, num NUMERIC(3) NOT NULL');
      Fsqlite.SQuery.SQL.Add(', num_ingot NUMERIC(2) NOT NULL');
      Fsqlite.SQuery.SQL.Add(', id_asutp NUMERIC(12) NOT NULL');
      Fsqlite.SQuery.SQL.Add(', heat VARCHAR(16) NOT NULL');
      Fsqlite.SQuery.SQL.Add(', timestamp INTEGER(12) NOT NULL');
      Fsqlite.SQuery.SQL.Add(', weight NUMERIC(16,4)');
      Fsqlite.SQuery.SQL.Add(', transferred NUMERIC(1,1) DEFAULT(0))');
      Fsqlite.SQuery.ExecSQL;

      sindex := 'CREATE INDEX IF NOT EXISTS idx_weight_asc ON weight (' +
                'id        ASC, ' +
                'id_asutp  ASC, ' +
                'num       ASC, ' +
                'pkdat     ASC, ' +
                'num_ingot ASC)';

      Fsqlite.SQuery.Close;
      Fsqlite.SQuery.SQL.Clear;
      Fsqlite.SQuery.SQL.Text := sindex;
      Fsqlite.SQuery.ExecSQL;

      sindex := 'CREATE INDEX IF NOT EXISTS idx_weight_desc ON weight (' +
                'id        DESC, ' +
                'id_asutp  DESC, ' +
                'num       DESC, ' +
                'pkdat     DESC, ' +
                'num_ingot DESC)';

      Fsqlite.SQuery.Close;
      Fsqlite.SQuery.SQL.Clear;
      Fsqlite.SQuery.SQL.Text := sindex;
      Fsqlite.SQuery.ExecSQL;
  except
    on E : Exception do
      Log.save('e', E.ClassName+' create table, с сообщением: '+E.Message);
  end;
end;




// При загрузке программы класс будет создаваться
initialization
Log := Tlog.Create;
SettingsApp := TSettings.Create;

//При закрытии программы уничтожаться
finalization
SettingsApp.Destroy;

end.

