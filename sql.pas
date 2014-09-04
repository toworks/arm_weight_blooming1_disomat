unit sql;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   Dialogs, StdCtrls, StrUtils, Data.DB, pFIBQuery;

var
    time_ingot, pkdat, num, num_ingot, num_heat, name, weight_ingot, steel_group,
    smena: string;
    SqlMaxLocal: integer = 0;
    MarkerNextWait: bool = false;

//    {$DEFINE DEBUG}


    function SqlNextWeightToRecord: bool;
    function SqlReadTable(InData: string): bool;
    function SqlSaveInBuffer(DataIn: AnsiString): Bool;
    function SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): Bool;
    function SqlSaveToOracleOfBuffer: Bool;
    function SqlReadTableLocal: bool;

implementation


uses
    main, settings, logging, module, thread_comport, thread_sql;





function SqlNextWeightToRecord: bool;
var
  FQueryNextRecord: TpFIBQuery;
  i: integer;
begin
  FQueryNextRecord := TpFIBQuery.Create(nil);
  FQueryNextRecord.Database := Module1.pFIBDatabase1;
  FQueryNextRecord.Transaction := Module1.pFIBTransaction1;

  i:=0;
  try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('SELECT pkdat, num, num_ingot FROM weight');
      SQuery.SQL.Add('order by id desc limit 1');
      SQuery.Open;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  try
      FQueryNextRecord.Close;
      FQueryNextRecord.SQL.Clear;
      FQueryNextRecord.SQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group , sh.smena');
      FQueryNextRecord.SQL.Add('from ingots i, heats h, steels s, shifts sh');
      FQueryNextRecord.SQL.Add('where ((i.pkdat='+ SQuery.FieldByName('pkdat').AsString +'');
      FQueryNextRecord.SQL.Add('and (i.num='+ SQuery.FieldByName('num').AsString +'');
      FQueryNextRecord.SQL.Add('and i.num_ingot>'+ SQuery.FieldByName('num_ingot').AsString +'');
      FQueryNextRecord.SQL.Add('or i.num>'+ SQuery.FieldByName('num').AsString +'))');
      FQueryNextRecord.SQL.Add('or i.pkdat>'+ SQuery.FieldByName('pkdat').AsString +')');
      FQueryNextRecord.SQL.Add('and i.pkdat=h.pkdat and i.num=h.num');
      FQueryNextRecord.SQL.Add('and i.pkdat=sh.pkdat');
      FQueryNextRecord.SQL.Add('and h.steel_grade=s.steel_grade');
      FQueryNextRecord.SQL.Add('order by i.pkdat asc, i.num asc, i.num_ingot asc');
      Application.ProcessMessages;//��������� �������� �� �������� ���������
      FQueryNextRecord.ExecQuery;
  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'FQueryNextRecord -> '+FQueryNextRecord.SQL.Text);
  {$ENDIF}
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'pkdat empty? -> '+FQueryNextRecord.FieldByName('pkdat').AsString);
  {$ENDIF}

  // ������ ��������� ��������� (��������)
  if FQueryNextRecord.FieldByName('pkdat').AsString = '' then
  begin
      SqlMax := 0;
      form1.l_n_message.Visible := true;
      form1.l_n_message.Font.Color := $002CB902;//green
      form1.l_n_message.Caption := ' �������� ��������� ��������� ';
      MarkerNextWait := true;

      form1.l_weight_ingot.Visible := false;
      form1.l_grade.Visible := false;
      form1.l_heat.Visible := false;
      form1.l_datetime.Visible := false;
      form1.l_number_ingot.Visible := false;
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


  try
      while not FQueryNextRecord.Eof do
      begin
          if i = 1 then
            break;

          pkdat := FQueryNextRecord.FieldByName('pkdat').AsString;
          num := FQueryNextRecord.FieldByName('num').AsString;
          num_ingot := FQueryNextRecord.FieldByName('num_ingot').AsString;
          time_ingot := timetostr(FQueryNextRecord.FieldByName('time_ingot').AsTime);
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
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  FreeAndNil(FQueryNextRecord);
end;


function SqlSaveInBuffer(DataIn: AnsiString): Bool;
var
  num_correct, num_ingot_correct, pkdat_correct: string;
  sindex: string;
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
    SaveLog('debug'+#9#9+'pkdat_correct -> '+pkdat_correct);
    SaveLog('debug'+#9#9+'num_correct -> '+num_correct);
    SaveLog('debug'+#9#9+'num_ingot_correct -> '+num_ingot_correct);
  {$ENDIF}

{ id_asutp ������� �� ����� pkdat+num+num_ingot, ��� � ����� pkdat �������
  ��� ����� ����,num �����, num_ingot ����� ������.
  � IT pkdat ������� ���� ����� ���,num ����� (3� ������� ����� ��������� ����� ������
  2 ����), num_ingot (2� ������� ����� ��������� ����� ������ 1 ����)) ����� ������.
}
  try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('CREATE TABLE IF NOT EXISTS weight');
      SQuery.SQL.Add('(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE');
      SQuery.SQL.Add(', pkdat NUMERIC(7) NOT NULL, num NUMERIC(3) NOT NULL');
      SQuery.SQL.Add(', num_ingot NUMERIC(2) NOT NULL');
      SQuery.SQL.Add(', id_asutp NUMERIC(12) NOT NULL');
      SQuery.SQL.Add(', heat VARCHAR(16) NOT NULL');
      SQuery.SQL.Add(', timestamp INTEGER(12) NOT NULL');
      SQuery.SQL.Add(', weight NUMERIC(16,4)');
      SQuery.SQL.Add(', transferred NUMERIC(1,1) DEFAULT(0))');
      SQuery.ExecSQL;

      sindex := 'CREATE INDEX IF NOT EXISTS idx_weight_asc ON weight (' +
                'id        ASC, ' +
                'id_asutp  ASC, ' +
                'num       ASC, ' +
                'pkdat     ASC, ' +
                'num_ingot ASC)';

      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Text := sindex;
      SQuery.ExecSQL;

      sindex := 'CREATE INDEX IF NOT EXISTS idx_weight_desc ON weight (' +
                'id        DESC, ' +
                'id_asutp  DESC, ' +
                'num       DESC, ' +
                'pkdat     DESC, ' +
                'num_ingot DESC)';

      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Text := sindex;
      SQuery.ExecSQL;

      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('INSERT INTO weight');
      SQuery.SQL.Add('(pkdat, num, num_ingot, id_asutp, heat, timestamp, weight)');
      SQuery.SQL.Add('VALUES('+pkdat+', '+num+', '+num_ingot+',');
      SQuery.SQL.Add(''+pkdat_correct+num_correct+num_ingot_correct+',');
      SQuery.SQL.Add(''+num_heat+', strftime(''%s'',''now''), '+PointReplace(DataIn)+')');      
      SQuery.ExecSQL;

  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  no_save := true;//��������� �������� ������������� � ����������

  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT pkdat, num, num_ingot, id_asutp,');
  SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'') as timestamp, weight FROM weight');
  SQuery.SQL.Add('where id_asutp='+pkdat_correct+num_correct+num_ingot_correct+'');
  SQuery.Open;

  //save to log file
  {SaveLog('sql'+#9#9+'write'+#9+'id_asutp -> '+SQuery.FieldByName('id_asutp').AsString);
  SaveLog('sql'+#9#9+'write'+#9+'weight -> '+SQuery.FieldByName('weight').AsString);}

  //��������� ���������
  ShowTrayMessage('���������', '�: '+num_ingot+#9+'���: '+SQuery.FieldByName('weight').AsString, 1);

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'pkdat_correct -> '+SQuery.FieldByName('id_asutp').AsString);
  {$ENDIF}

  try
      SqlReadTableLocal;//views ���������� ���������
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  try
    SqlSaveToOracle(SQuery.FieldByName('id_asutp').AsString, SQuery.FieldByName('weight').AsString
                    , SQuery.FieldByName('timestamp').AsString);

    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('UPDATE weight SET transferred=1');
    SQuery.SQL.Add('where id_asutp='+pkdat_correct+num_correct+num_ingot_correct+'');
    SQuery.ExecSQL;
  except
      on E : Exception do
        SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  //������� ������ ������ 6 ������� 2629743(���� �����)*6
  try
      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('DELETE FROM weight');
      SQuery.SQL.Add('where timestamp<(strftime(''%s'',''now'')-(2629743*6))');
      SQuery.ExecSQL;
   except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  //���� ������� ������
  SendAttribute;

  //��������� ������ (������) �� ���������
  NextWeightToRecord;

  //����������, ��� �� �������� �� �����
  SqlSaveToOracleOfBuffer;
end;


function SqlSaveToOracleOfBuffer: Bool;
var
  i: integer;
  Byffer: array of array of AnsiString;
begin
  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT id_asutp, weight,');
  SQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'' ) as timestamp');
  SQuery.SQL.Add('FROM weight');
  SQuery.SQL.Add('where transferred=0');
  SQuery.SQL.Add('order by id asc limit 10'); //�������� �� 10 ��
  SQuery.Open;

  i := 0;
  while not SQuery.Eof do
   begin
      if i = Length(Byffer) then SetLength(Byffer, i+1, 3);
      Byffer[i,0] := SQuery.FieldByName('id_asutp').AsString;
      Byffer[i,1] := SQuery.FieldByName('weight').AsString;
      Byffer[i,2] := SQuery.FieldByName('timestamp').AsString;      
      inc(i);
      SQuery.Next;
   end;

  for i := Low(Byffer) to High(Byffer) do
   begin
    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'id_asutp -> '+Byffer[i,0]);
      SaveLog('debug'+#9#9+'weight -> '+Byffer[i,1]);
      SaveLog('debug'+#9#9+'timestamp -> '+Byffer[i,2]);
    {$ENDIF}
      try
        SqlSaveToOracle(Byffer[i,0], Byffer[i,1], Byffer[i,2]);

        SQuery.Close;
        SQuery.SQL.Clear;
        SQuery.SQL.Add('UPDATE weight SET transferred=1');
        SQuery.SQL.Add('where id_asutp='+Byffer[i,0]+'');
        SQuery.ExecSQL;
        //save to log file
        {SaveLog('sql'+#9#9+'write'+#9+'id_asutp -> '+Byffer[i,0]);
        SaveLog('sql'+#9#9+'write'+#9+'weight -> '+Byffer[i,1]);
        SaveLog('sql'+#9#9+'write'+#9+'timestamp -> '+Byffer[i,2]);}
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
   end;
end;


function SqlSaveToOracle(IdIn, WeightIn, TimestampIn: AnsiString): Bool;
begin
  try
    Module1.OraQuery1.Close;
    Module1.OraQuery1.SQL.Clear;
    Module1.OraQuery1.SQL.Add('INSERT INTO crop');
    Module1.OraQuery1.SQL.Add('(id_asutp, weight_bloom, date_weight_bloom)');
    Module1.OraQuery1.SQL.Add('VALUES ('+IdIn+', '+PointReplace(WeightIn)+',');
    Module1.OraQuery1.SQL.Add('TO_DATE('''+TimestampIn+''', ''yyyy-mm-dd hh24:mi:ss''))');

{    Module1.OraQuery1.SQL.Add('begin');
    Module1.OraQuery1.SQL.Add('INSERT INTO crop');
    Module1.OraQuery1.SQL.Add('(id_asutp, weight_bloom, date_weight_bloom)');
    Module1.OraQuery1.SQL.Add('VALUES ('+IdIn+', '+PointReplace(WeightIn)+',');
    Module1.OraQuery1.SQL.Add('TO_DATE('''+TimestampIn+''', ''yyyy-mm-dd hh24:mi:ss''));');
    Module1.OraQuery1.SQL.Add('exception');
    Module1.OraQuery1.SQL.Add('when dup_val_on_index then');
    Module1.OraQuery1.SQL.Add('update crop');
    Module1.OraQuery1.SQL.Add('set weight_bloom = '+PointReplace(WeightIn)+',');
    Module1.OraQuery1.SQL.Add('date_weight_bloom = TO_DATE('''+TimestampIn+''', ''yyyy-mm-dd hh24:mi:ss'')');
    Module1.OraQuery1.SQL.Add('where id_asutp = '+IdIn+';');
    Module1.OraQuery1.SQL.Add('end;');}

{    Module1.OraQuery1.SQL.Add('MERGE INTO crop USING dual ON');
    Module1.OraQuery1.SQL.Add('(id_asutp = '+IdIn+')');
    Module1.OraQuery1.SQL.Add('WHEN MATCHED THEN UPDATE');
    Module1.OraQuery1.SQL.Add('SET weight_bloom = '+PointReplace(WeightIn)+',');
    Module1.OraQuery1.SQL.Add('date_weight_bloom = TO_DATE('''+TimestampIn+''', ''yyyy-mm-dd hh24:mi:ss'')');
    Module1.OraQuery1.SQL.Add('WHEN NOT MATCHED THEN INSERT');
    Module1.OraQuery1.SQL.Add('(id_asutp, weight_bloom, date_weight_bloom)');
    Module1.OraQuery1.SQL.Add('VALUES ('+IdIn+', '+PointReplace(WeightIn)+',');
    Module1.OraQuery1.SQL.Add('TO_DATE('''+TimestampIn+''', ''yyyy-mm-dd hh24:mi:ss''))');}

    Application.ProcessMessages;//��������� �������� �� �������� ���������
    Module1.OraQuery1.ExecSQL;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'Module1.OraQuery1.SQL.Text -> '+Module1.OraQuery1.SQL.Text);
  {$ENDIF}
  except
    on E : Exception do begin
    Module1.OraQuery1.Close;
    Module1.OraQuery1.SQL.Clear;
    Module1.OraQuery1.SQL.Add('update crop');
    Module1.OraQuery1.SQL.Add('set weight_bloom = '+PointReplace(WeightIn)+',');
    Module1.OraQuery1.SQL.Add('date_weight_bloom = TO_DATE('''+TimestampIn+''',');
    Module1.OraQuery1.SQL.Add('''yyyy-mm-dd hh24:mi:ss'')');
    Module1.OraQuery1.SQL.Add('where id_asutp = '+IdIn+'');

    Application.ProcessMessages;//��������� �������� �� �������� ���������
    Module1.OraQuery1.ExecSQL;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'Module1.OraQuery1.SQL.Text -> '+Module1.OraQuery1.SQL.Text);
  {$ENDIF}
    end;
  end;

end;


function SqlReadTable(InData: string): bool;
begin
  try
      Module1.pFIBDataSet1.Active := false;
      Module1.pFIBDataSet1.Close;
      Module1.pFIBDataSet1.SQLs.SelectSQL.Clear;
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group, sh.smena');
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('from ingots i, heats h, steels s, shifts sh');
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('where i.pkdat=h.pkdat');
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and i.pkdat=sh.pkdat');
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and i.num=h.num');
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and h.steel_grade=s.steel_grade');
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and i.pkdat in ('+InData+')');
      Module1.pFIBDataSet1.SQLs.SelectSQL.Add('order by i.pkdat desc, i.num desc, i.num_ingot desc');
//      Application.ProcessMessages;//��������� �������� �� �������� ���������
      Module1.pFIBDataSet1.Open;
      Module1.pFIBDataSet1.Active := true;
  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;
  //���������� ����������� ���� � DBGrid -> pFIBDataSet1
  TDateTimeField(Module1.pFIBDataSet1.FieldByName('time_ingot')).DisplayFormat:='hh:nn:ss';
end;


function SqlReadTableLocal: bool;
begin
  SLQuery.Close;
  SLQuery.SQL.Clear;
  SLQuery.SQL.Add('SELECT substr(pkdat,7,1) as shift, num_ingot,');
  SLQuery.SQL.Add('datetime(timestamp, ''unixepoch'', ''localtime'' ) as timestamp,');
  SLQuery.SQL.Add('heat, weight,');
  SLQuery.SQL.Add('case when transferred = 1 then ''�������'' else ''�� �������'' end as transferred');
  SLQuery.SQL.Add('FROM weight');
  SLQuery.SQL.Add('order by timestamp desc limit 100');
  SLQuery.Open;

  //���������� ����������� ���� � DBGrid -> 20 characters
  TStringField(SDataSource.DataSet.FieldByName('shift')).DisplayWidth := 3;
  TStringField(SDataSource.DataSet.FieldByName('timestamp')).DisplayWidth := 20;
  TStringField(SDataSource.DataSet.FieldByName('transferred')).DisplayWidth := 20;
end;


end.
