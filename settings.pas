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
  logging;

type
  TSettings = class
  private
     SQuery: TZQuery;
     Log: TLog;
  public
    Constructor Create; overload;
    Destructor Destroy; override;

    function ConfigSettings(InData: bool): bool;
    function ReadConfigSettings: bool;
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
   SettingsApp: TSettings;
   CurrentDir: string;
   HeadName: string = ' ��� ������� ��-4 ';
   DBFile: string = 'data.sdb';

   SConnect: TZConnection;
   FbSqlSettings: TSqlSettings;
   OraSqlSettings: TSqlSettings;
   SerialPortSettings: TSerialSettings;

   function GetVersion: string;// ������ ������ ���������


//   {$DEFINE DEBUG}



implementation

uses
  main, sql;



constructor TSettings.Create;
begin
  inherited Create;
  //������� ����������
  CurrentDir := GetCurrentDir;
  Log := Tlog.Create;
  ConfigSettings(true);
  ConfigFirebirdSetting(true);
  SqlLocalCreateTable; //create local sqlite table
end;


destructor TSettings.Destroy;
begin
  ConfigFirebirdSetting(false);
  ConfigSettings(false);
  inherited Destroy;
end;


function TSettings.ConfigSettings(InData: bool): bool;
var
  f: File of Word;
begin

  if InData then
   begin

      SConnect := TZConnection.Create(nil);
      SQuery := TZQuery.Create(nil);

      try
        SConnect.Database := CurrentDir+'\'+DBFile;
        SConnect.LibraryLocation := CurrentDir+'\sqlite3.dll';
        SConnect.Protocol := 'sqlite-3';
        SConnect.Connect;
        SQuery.Connection := SConnect;

        ReadConfigSettings;

      except
        on E : Exception do
          Log.save('e', E.ClassName+', � ����������: '+E.Message);
      end;
   end
  else
   begin
      SQuery.Destroy;
      SConnect.Destroy;
   end;

end;


function TSettings.ReadConfigSettings: bool;
var
  i: integer;
begin

    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('SELECT * FROM settings');
    SQuery.Open;


    while not SQuery.Eof do
     begin
      //fbsql
      if SQuery.FieldByName('name').AsString = '::FbSql::ip' then
        FbSqlSettings.ip := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::db_name' then
        FbSqlSettings.db_name := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::library' then
        FbSqlSettings.lib := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::dialect' then
        FbSqlSettings.dialect := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::user' then
        FbSqlSettings.user := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::password' then
        FbSqlSettings.password := SQuery.FieldByName('value').AsString;

      //orasql
      if SQuery.FieldByName('name').AsString = '::OraSql::ip' then
        OraSqlSettings.ip := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::port' then
        OraSqlSettings.port := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::db_name' then
        OraSqlSettings.db_name := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::user' then
        OraSqlSettings.user := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::password' then
        OraSqlSettings.password := SQuery.FieldByName('value').AsString;

      //comport
      if SQuery.FieldByName('name').AsString = '::ComPort::baud' then
        SerialPortSettings.baud := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::ComPort::data_bits' then
        SerialPortSettings.data_bits := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::ComPort::parity' then
        SerialPortSettings.parity := AnsiLowerCase(SQuery.FieldByName('value').AsString);
      if SQuery.FieldByName('name').AsString = '::ComPort::stop_bits' then
        SerialPortSettings.stop_bits := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::ComPort::number' then
        SerialPortSettings.serial_port_number := SQuery.FieldByName('value').AsString;

        SQuery.Next;
     end;

 {$IFDEF DEBUG}
  Log.save('d', 'SerialPortSettings.baud -> '+SerialPortSettings.baud);
  Log.save('d', 'SerialPortSettings.data_bits -> '+SerialPortSettings.data_bits);
  Log.save('d', 'SerialPortSettings.parity -> '+SerialPortSettings.parity);
  Log.save('d', 'SerialPortSettings.stop_bits -> '+SerialPortSettings.stop_bits);
  Log.save('d', 'SerialPortSettings.serial_port_number -> '+SerialPortSettings.serial_port_number);
 {$ENDIF}

end;


function GetVersion: string;
type
  TVerInfo=packed record
    Nevazhno: array[0..47] of byte; // �������� ��� 48 ����
    Minor, Major, Build, Release: word; // � ��� ������
  end;
var
  s: TResourceStream;
  v: TVerInfo;
begin
  result := '';
  try
    s := TResourceStream.Create(HInstance, '#1', RT_VERSION); // ������ ������
    if s.Size > 0 then begin
      s.Read(v,SizeOf(v)); // ������ ������ ��� �����
      result := Format('%d%d%d%d', [v.Major, v.Minor, v.Release, v.Build]);
   end;
  finally
      s.Free;
  end;
end;


// ��� �������� ��������� ����� ����� �����������
initialization
SettingsApp := TSettings.Create;

//��� �������� ��������� ������������
finalization
SettingsApp.Destroy;

end.

