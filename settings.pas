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
  ZAbstractConnection, ZConnection, ZAbstractRODataset, ZStoredProcedure;

type
  TSettings = class


  private
    { Private declarations }
  protected

  end;

var
   SettingsApp: TSettings;
   SConnect: TZConnection;
   SQuery: TZQuery;

   FbSqlConfigArray: Array[1..6] of String;
   OraSqlConfigArray: Array[1..5] of String;
   ComPortConfigArray: Array[1..5] of String;

//   {$DEFINE DEBUG}

   function ConfigSettings(InData: bool): bool;
   function ReadConfigSettings: bool;


implementation

uses
  main, logging;



function ConfigSettings(InData: bool): bool;
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
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
   end
  else
   begin
      SQuery.Destroy;
      SConnect.Destroy;
   end;

end;


function ReadConfigSettings: bool;
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
        FbSqlConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::db_name' then
        FbSqlConfigArray[2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::library' then
        FbSqlConfigArray[3] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::dialect' then
        FbSqlConfigArray[4] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::user' then
        FbSqlConfigArray[5] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::FbSql::password' then
        FbSqlConfigArray[6] := SQuery.FieldByName('value').AsString;

      //orasql
      if SQuery.FieldByName('name').AsString = '::OraSql::ip' then
        OraSqlConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::port' then
        OraSqlConfigArray[2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::db_name' then
        OraSqlConfigArray[3] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::user' then
        OraSqlConfigArray[4] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::OraSql::password' then
        OraSqlConfigArray[5] := SQuery.FieldByName('value').AsString;

      //comport
      if SQuery.FieldByName('name').AsString = '::ComPort::baud' then
        ComPortConfigArray[1] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::ComPort::data_bits' then
        ComPortConfigArray[2] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::ComPort::parity' then
        ComPortConfigArray[3] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::ComPort::stop_bits' then
        ComPortConfigArray[4] := SQuery.FieldByName('value').AsString;
      if SQuery.FieldByName('name').AsString = '::ComPort::number' then
        ComPortConfigArray[5] := SQuery.FieldByName('value').AsString;

        SQuery.Next;
     end;

 {$IFDEF DEBUG}
  SaveLog('debug'+#9#9+'ComPortConfigArray[1] -> '+ComPortConfigArray[1]);
  SaveLog('debug'+#9#9+'ComPortConfigArray[2] -> '+ComPortConfigArray[2]);
  SaveLog('debug'+#9#9+'ComPortConfigArray[3] -> '+ComPortConfigArray[3]);
  SaveLog('debug'+#9#9+'ComPortConfigArray[4] -> '+ComPortConfigArray[4]);
  SaveLog('debug'+#9#9+'ComPortConfigArray[5] -> '+ComPortConfigArray[5]);
 {$ENDIF}

end;



// ��� �������� ��������� ����� ����� �����������
initialization
  SettingsApp := TSettings.Create;

//��� �������� ��������� ������������
finalization
  SettingsApp.Destroy;

end.