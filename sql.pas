unit sql;

interface

uses
   SysUtils, ActiveX, Variants, Classes, StrUtils, Data.DB, ZConnection, ZDataset,
   ZDbcIntfs, SyncObjs;

var
    FConnect: TZConnection;
    FQuery: TZQuery;
    FDataSource: TDataSource;
    SLQuery: TZQuery;
    SLDataSource: TDataSource;
    time_ingot, pkdat, num, num_ingot, num_heat, name, weight_ingot, steel_group,
    smena: string;
    MarkerNextWait: boolean = false;


//    {$DEFINE DEBUG}


    function ConfigFirebirdSetting(InData: boolean): boolean;
    function SqlNextWeightToRecord: boolean;
    function SqlSaveInBuffer(DataIn: AnsiString): boolean;
    function SqlLocalCreateTable: boolean;

implementation


uses
    settings, logging, thread_sql_send, thread_comport, thread_sql_read, main;





function ConfigFirebirdSetting(InData: boolean): boolean;
begin
  if InData then
  begin
      try
        FConnect := TZConnection.Create(nil);
        FQuery := TZQuery.Create(nil);
        FConnect.LibraryLocation := '.\fbclient.dll';// ��������� �� ������ ����� �� ������
        FConnect.Protocol := 'firebird-2.5';
        FConnect.Database := FbSqlSettings.db_name;
        FConnect.HostName := FbSqlSettings.ip;
        FConnect.User := FbSqlSettings.user;
        FConnect.Password := FbSqlSettings.password;
        FConnect.ReadOnly := True;
        FConnect.LoginPrompt := false;
        FConnect.Port := 3050;
        FConnect.AutoCommit := False;
        FConnect.TransactIsolationLevel := tiReadCommitted;
        with FConnect.Properties do
        begin
             Add('Dialect=3');
             Add('isc_tpb_read_committed');
             Add('isc_tpb_concurrency');              // Needed for multiuser environments
             Add('isc_tpb_nowait');                   // Needed for multiuser environments
             Add('timeout=3');
//             Add('codepage=NONE');
//             Add('controls_cp=CP_UTF8');
//             Add('AutoEncodeStrings=ON');
//             Add('codepage=win1251');
//             Add('client_encoding=UTF8');
        end;
        FConnect.Connect;
        FQuery.Connection := FConnect;

        FDataSource := TDataSource.Create(nil);
        FDataSource.DataSet := FQuery;
      except
        on E: Exception do begin
          Log.save('e', E.ClassName+', � ����������: '+E.Message);
        end;
      end;
  end
  else
  begin
        FreeAndNil(FQuery);
        FreeAndNil(FConnect);
  end;

end;


function SqlNextWeightToRecord: boolean;
var
  _SQuery: TZQuery;
  FQueryNextRecord: TZQuery;
  i: integer;
begin

  i:=0;
  try
      _SQuery := TZQuery.Create(nil);
      _SQuery.Connection := SConnect;
      _SQuery.Close;
      _SQuery.SQL.Clear;
      _SQuery.SQL.Add('SELECT pkdat, num, num_ingot FROM weight');
      _SQuery.SQL.Add('order by id desc limit 1');
      _SQuery.Open;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  try
      FQueryNextRecord := TZQuery.Create(nil);
      FQueryNextRecord.Connection := FConnect;
      FQueryNextRecord.Close;
      FQueryNextRecord.SQL.Clear;
      FQueryNextRecord.SQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group , sh.smena');
      FQueryNextRecord.SQL.Add('from ingots i, heats h, steels s, shifts sh');
      FQueryNextRecord.SQL.Add('where ((i.pkdat='+ _SQuery.FieldByName('pkdat').AsString +'');
      FQueryNextRecord.SQL.Add('and (i.num='+ _SQuery.FieldByName('num').AsString +'');
      FQueryNextRecord.SQL.Add('and i.num_ingot>'+ _SQuery.FieldByName('num_ingot').AsString +'');
      FQueryNextRecord.SQL.Add('or i.num>'+ _SQuery.FieldByName('num').AsString +'))');
      FQueryNextRecord.SQL.Add('or i.pkdat>'+ _SQuery.FieldByName('pkdat').AsString +')');
      FQueryNextRecord.SQL.Add('and i.pkdat=h.pkdat and i.num=h.num');
      FQueryNextRecord.SQL.Add('and i.pkdat=sh.pkdat');
      FQueryNextRecord.SQL.Add('and h.steel_grade=s.steel_grade');
      FQueryNextRecord.SQL.Add('order by i.pkdat asc, i.num asc, i.num_ingot asc');
      FQueryNextRecord.Open;
  {$IFDEF DEBUG}
    Log.save('d', 'FQueryNextRecord -> '+FQueryNextRecord.SQL.Text);
  {$ENDIF}
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  {$IFDEF DEBUG}
    Log.save('d', 'pkdat empty? -> '+FQueryNextRecord.FieldByName('pkdat').AsString);
  {$ENDIF}

  try
      // ������ ��������� ��������� (��������)
      if FQueryNextRecord.FieldByName('pkdat').AsString = '' then
      begin
          form1.SqlMax := 0;
          form1.l_n_message.Visible := true;
          form1.l_n_message.Font.Color := $002CB902;//green
          form1.l_n_message.Caption := ' �������� ��������� ��������� ';
          MarkerNextWait := true;

          form1.l_weight_ingot.Visible := false;
          form1.l_grade.Visible := false;
          form1.l_heat.Visible := false;
          form1.l_datetime.Visible := false;
          form1.l_number_ingot.Visible := false;
          FreeAndNil(_SQuery);
          FreeAndNil(FQueryNextRecord);//������ ������
          exit;
      end
      else
      begin
          form1.l_n_message.Visible := false;
          MarkerNextWait := false;
          form1.l_weight_ingot.Visible := true;
          form1.l_grade.Visible := true;
          form1.l_heat.Visible := true;
          form1.l_datetime.Visible := true;
          form1.l_number_ingot.Visible := true;
      end;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  try
      while not FQueryNextRecord.Eof do
      begin
          if i = 1 then
            break;

          pkdat := FQueryNextRecord.FieldByName('pkdat').AsString;
          num := FQueryNextRecord.FieldByName('num').AsString;
          num_ingot := FQueryNextRecord.FieldByName('num_ingot').AsString;
          time_ingot := timetostr(FQueryNextRecord.FieldByName('time_ingot').AsDateTime);
          num_heat := FQueryNextRecord.FieldByName('num_heat').AsString;
          name := FQueryNextRecord.FieldByName('name').AsString;
          weight_ingot := FQueryNextRecord.FieldByName('weight_ingot').AsString;
          smena := FQueryNextRecord.FieldByName('smena').AsString;

          Form1.l_number_ingot.Caption := num_ingot;
          Form1.l_datetime.Caption := time_ingot;
          Form1.l_heat.Caption := num_heat;
          Form1.l_grade.Caption := name;
          Form1.l_weight_ingot.Caption := weight_ingot;

          //-- test
          Form1.l_next_id.Caption:=pkdat+'|'+num+'|'+num_ingot;

          inc(i);
          FQueryNextRecord.Next;
      end;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  FreeAndNil(_SQuery);
  FreeAndNil(FQueryNextRecord);
end;


function SqlSaveInBuffer(DataIn: AnsiString): boolean;
var
  _SQuery: TZQuery;
  num_correct, num_ingot_correct, pkdat_correct: string;
begin

  // ������ ��������� ��������� (��������)
  if MarkerNextWait then
    exit;

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
    Log.save('d', 'pkdat_correct -> '+pkdat_correct);
    Log.save('d', 'num_correct -> '+num_correct);
    Log.save('d', 'num_ingot_correct -> '+num_ingot_correct);
  {$ENDIF}

{ id_asutp ������� �� ����� pkdat+num+num_ingot, ��� � ����� pkdat �������
  ��� ����� ����,num �����, num_ingot ����� ������.
  � IT pkdat ������� ���� ����� ���,num ����� (3� ������� ����� ��������� ����� ������
  2 ����), num_ingot (2� ������� ����� ��������� ����� ������ 1 ����)) ����� ������.
}
  try
      _SQuery := TZQuery.Create(nil);
      _SQuery.Connection := SConnect;
      _SQuery.Close;
      _SQuery.SQL.Clear;
      _SQuery.SQL.Add('INSERT INTO weight');
      _SQuery.SQL.Add('(pkdat, num, num_ingot, id_asutp, heat, timestamp, weight)');
      _SQuery.SQL.Add('VALUES('+pkdat+', '+num+', '+num_ingot+',');
      _SQuery.SQL.Add(''+pkdat_correct+num_correct+num_ingot_correct+',');
      _SQuery.SQL.Add(''+num_heat+', strftime(''%s'',''now''), '+PointReplace(DataIn)+')');
      _SQuery.ExecSQL;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message+' | '+_SQuery.SQL.Text);
  end;

  //ThreadComPort.no_save := true;//��������� �������� ������������� � ����������
  form1.no_save := true;//��������� �������� ������������� � ����������

  try
      _SQuery.Close;
      _SQuery.SQL.Clear;
      _SQuery.SQL.Add('SELECT pkdat, num, num_ingot, id_asutp,');
      _SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'') as timestamp, weight FROM weight');
      _SQuery.SQL.Add('where id_asutp='+pkdat_correct+num_correct+num_ingot_correct+'');
      _SQuery.Open;
  except
    on E : Exception do
      Log.save('e', E.ClassName+', � ����������: '+E.Message+' | '+_SQuery.SQL.Text);
  end;
  //save to log file
  {Log.save('sql'+#9#9+'write'+#9+'id_asutp -> '+SQuery.FieldByName('id_asutp').AsString);
  Log.save('sql'+#9#9+'write'+#9+'weight -> '+SQuery.FieldByName('weight').AsString);}

  //��������� ���������
  ShowTrayMessage('���������', '�: '+num_ingot+#9+'���: '+_SQuery.FieldByName('weight').AsString, 1);

  {$IFDEF DEBUG}
    Log.save('d', 'pkdat_correct -> '+_SQuery.FieldByName('id_asutp').AsString);
  {$ENDIF}

  //��������� ������ (������) �� ���������
  NextWeightToRecord;
  FreeAndNil(_SQuery);
end;


function SqlLocalCreateTable: boolean;
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
      _SQuery.Connection := SConnect;
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
      Log.save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  FreeAndNil(_SQuery);
end;




end.
