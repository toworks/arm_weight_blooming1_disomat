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
    FSQuery: TZQuery;
    FSConnect: TZConnection;
    function ConfigSettings(InData: bool): bool;
    function SqlLocalCreateTable: boolean;
  public
    Constructor Create; overload;
    Destructor Destroy; override;

    function ReadConfigSettings: bool;

    property SConnect: TZConnection read FSConnect write FSConnect;
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
   CurrentDir: string;
   HeadName: string = ' ��� ������� ��-4 ';
   DBFile: string = 'data.sdb';

//   SConnect: TZConnection;
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

  ConfigSettings(true);
  ReadConfigSettings;
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

      FSConnect := TZConnection.Create(nil);
      FSQuery := TZQuery.Create(nil);

      try
        FSConnect.Database := CurrentDir+'\'+DBFile;
        FSConnect.LibraryLocation := CurrentDir+'\sqlite3.dll';
        FSConnect.Protocol := 'sqlite-3';
        FSConnect.Connect;
        FSQuery.Connection := FSConnect;
      except
        on E : Exception do
          Log.save('e', E.ClassName+' sqlite config settings, � ����������: '+E.Message);
      end;
   end
  else
   begin
      FSQuery.Destroy;
      FSConnect.Destroy;
   end;

end;


function TSettings.ReadConfigSettings: bool;
var
  i: integer;
begin

    FSQuery.Close;
    FSQuery.SQL.Clear;
    FSQuery.SQL.Add('SELECT * FROM settings');
    FSQuery.Open;


    while not FSQuery.Eof do
     begin
      //fbsql
      if FSQuery.FieldByName('name').AsString = '::FbSql::ip' then
        FbSqlSettings.ip := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::FbSql::db_name' then
        FbSqlSettings.db_name := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::FbSql::library' then
        FbSqlSettings.lib := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::FbSql::dialect' then
        FbSqlSettings.dialect := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::FbSql::user' then
        FbSqlSettings.user := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::FbSql::password' then
        FbSqlSettings.password := FSQuery.FieldByName('value').AsString;

      //orasql
      if FSQuery.FieldByName('name').AsString = '::OraSql::ip' then
        OraSqlSettings.ip := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::OraSql::port' then
        OraSqlSettings.port := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::OraSql::db_name' then
        OraSqlSettings.db_name := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::OraSql::user' then
        OraSqlSettings.user := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::OraSql::password' then
        OraSqlSettings.password := FSQuery.FieldByName('value').AsString;

      //comport
      if FSQuery.FieldByName('name').AsString = '::ComPort::baud' then
        SerialPortSettings.baud := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::ComPort::data_bits' then
        SerialPortSettings.data_bits := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::ComPort::parity' then
        SerialPortSettings.parity := AnsiLowerCase(FSQuery.FieldByName('value').AsString);
      if FSQuery.FieldByName('name').AsString = '::ComPort::stop_bits' then
        SerialPortSettings.stop_bits := FSQuery.FieldByName('value').AsString;
      if FSQuery.FieldByName('name').AsString = '::ComPort::number' then
        SerialPortSettings.serial_port_number := FSQuery.FieldByName('value').AsString;

        FSQuery.Next;
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


function TSettings.SqlLocalCreateTable: boolean;
var
  _SQuery: TZQuery;
  sindex: string;
begin
{ id_asutp ������� �� ����� pkdat+num+num_ingot, ��� � ����� pkdat �������
  ��� ����� ����,num �����, num_ingot ����� ������.
  � IT pkdat ������� ���� ����� ���,num ����� (3� ������� ����� ��������� ����� ������
  2 ����), num_ingot (2� ������� ����� ��������� ����� ������ 1 ����)) ����� ������.
}
  try
      _SQuery := TZQuery.Create(nil);
      _SQuery.Connection := FSConnect;
      _SQuery.Close;
      _SQuery.SQL.Clear;
      _SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS weight');
      _SQuery.SQL.Add('(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
      _SQuery.SQL.Add(', pkdat NUMERIC(7) NOT NULL, num NUMERIC(3) NOT NULL');
      _SQuery.SQL.Add(', num_ingot NUMERIC(2) NOT NULL');
      _SQuery.SQL.Add(', id_asutp NUMERIC(12) NOT NULL');
      _SQuery.SQL.Add(', heat VARCHAR(16) NOT NULL');
      _SQuery.SQL.Add(', timestamp INTEGER(12) NOT NULL');
      _SQuery.SQL.Add(', weight NUMERIC(16,4)');
      _SQuery.SQL.Add(', transferred NUMERIC(1,1) DEFAULT(0))');
      _SQuery.ExecSQL;

      sindex := 'CREATE INDEX IF NOT EXISTS idx_weight_asc ON weight (' +
                'id        ASC, ' +
                'id_asutp  ASC, ' +
                'num       ASC, ' +
                'pkdat     ASC, ' +
                'num_ingot ASC)';

      _SQuery.Close;
      _SQuery.SQL.Clear;
      _SQuery.SQL.Text := sindex;
      _SQuery.ExecSQL;

      sindex := 'CREATE INDEX IF NOT EXISTS idx_weight_desc ON weight (' +
                'id        DESC, ' +
                'id_asutp  DESC, ' +
                'num       DESC, ' +
                'pkdat     DESC, ' +
                'num_ingot DESC)';

      _SQuery.Close;
      _SQuery.SQL.Clear;
      _SQuery.SQL.Text := sindex;
      _SQuery.ExecSQL;
  except
    on E : Exception do
      Log.save('e', E.ClassName+' create table, � ����������: '+E.Message);
  end;

  FreeAndNil(_SQuery);
end;




// ��� �������� ��������� ����� ����� �����������
initialization
Log := Tlog.Create;
SettingsApp := TSettings.Create;

//��� �������� ��������� ������������
finalization
SettingsApp.Destroy;

end.

