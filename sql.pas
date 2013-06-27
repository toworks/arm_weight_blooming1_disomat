unit sql;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   Dialogs, StdCtrls, StrUtils, Data.DB;

var
    time_ingot, pkdat, num, num_ingot, num_heat, name, weight_ingot, steel_group,
    smena: string;


//    {$DEFINE DEBUG}


    function SqlNextWeightToRecord: bool;
    function SqlReadTable(InData: string): bool;
    function SqlSaveInBuffer(DataIn: AnsiString): Bool;
    function SqlSaveToOracle(IdIn, WeightIn: AnsiString): Bool;
    function SqlSaveToOracleOfBuffer: Bool;


implementation


uses
    main, settings, logging, module, thread_comport;





function SqlNextWeightToRecord: bool;
var
  i: integer;
begin

  i:=0;

  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT pkdat, num, num_ingot FROM weight');
  SQuery.SQL.Add('order by id desc limit 1');
  SQuery.Open;

  Module1.pFIBQuery1.Close;
  Module1.pFIBQuery1.SQL.Clear;
  Module1.pFIBQuery1.SQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group , sh.smena');
  Module1.pFIBQuery1.SQL.Add('from ingots i, heats h, steels s, shifts sh');
  Module1.pFIBQuery1.SQL.Add('where ((i.pkdat='+ SQuery.FieldByName('pkdat').AsString +'');
  Module1.pFIBQuery1.SQL.Add('and (i.num='+ SQuery.FieldByName('num').AsString +'');
  Module1.pFIBQuery1.SQL.Add('and i.num_ingot>'+ SQuery.FieldByName('num_ingot').AsString +'');
  Module1.pFIBQuery1.SQL.Add('or i.num>'+ SQuery.FieldByName('num').AsString +'))');
  Module1.pFIBQuery1.SQL.Add('or i.pkdat>'+ SQuery.FieldByName('pkdat').AsString +')');
  Module1.pFIBQuery1.SQL.Add('and i.pkdat=h.pkdat and i.num=h.num');
  Module1.pFIBQuery1.SQL.Add('and i.pkdat=sh.pkdat');
  Module1.pFIBQuery1.SQL.Add('and h.steel_grade=s.steel_grade');
  Module1.pFIBQuery1.SQL.Add('order by i.pkdat asc, i.num asc, i.num_ingot asc');
  Module1.pFIBQuery1.ExecQuery;


  while not Module1.pFIBQuery1.Eof do
   begin
      if i = 1 then
        break;

          pkdat := Module1.pFIBQuery1.FieldByName('pkdat').AsString;
          num := Module1.pFIBQuery1.FieldByName('num').AsString;
          num_ingot := Module1.pFIBQuery1.FieldByName('num_ingot').AsString;
          time_ingot := timetostr(Module1.pFIBQuery1.FieldByName('time_ingot').AsTime);
          num_heat := Module1.pFIBQuery1.FieldByName('num_heat').AsString;
          name := Module1.pFIBQuery1.FieldByName('name').AsString;
          weight_ingot := Module1.pFIBQuery1.FieldByName('weight_ingot').AsString;
          smena := Module1.pFIBQuery1.FieldByName('smena').AsString;

          Form1.l_number_ingot.Caption := num_ingot;
          Form1.l_datetime.Caption := time_ingot;
          Form1.l_heat.Caption := num_heat;
          Form1.l_grade.Caption := name;
          Form1.l_weight_ingot.Caption := weight_ingot;

      //test
      Form1.l_next_id.Caption:=pkdat+'|'+num+'|'+num_ingot;

      inc(i);
      Module1.pFIBQuery1.Next;
   end;
end;


function SqlSaveInBuffer(DataIn: AnsiString): Bool;
var
  num_correct, num_ingot_correct, pkdat_correct: string;
begin

  pkdat_correct := ManipulationWithDate(pkdat, 0);
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
      SQuery.SQL.Add(', timestamp DATETIME NOT NULL');
      SQuery.SQL.Add(', weight NUMERIC(16,4)');
      SQuery.SQL.Add(', transferred NUMERIC(1,1) DEFAULT(0))');
      SQuery.ExecSQL;

      SQuery.Close;
      SQuery.SQL.Clear;
      SQuery.SQL.Add('INSERT INTO weight');
      SQuery.SQL.Add('(pkdat, num, num_ingot, id_asutp, timestamp, weight)');
      SQuery.SQL.Add('VALUES('+pkdat+', '+num+', '+num_ingot+',');
      SQuery.SQL.Add(''+pkdat_correct+num_correct+num_ingot_correct+', strftime(''%s'',''now''), '+PointReplace(DataIn)+')');
      SQuery.ExecSQL;

  except
    on E : Exception do
      SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT pkdat, num, num_ingot, id_asutp, weight FROM weight');
  SQuery.SQL.Add('where id_asutp='+pkdat_correct+num_correct+num_ingot_correct+'');
  SQuery.Open;

  SaveLog('sql'+#9#9+'write'+#9+'id_asutp -> '+SQuery.FieldByName('id_asutp').AsString);
  SaveLog('sql'+#9#9+'write'+#9+'weight -> '+SQuery.FieldByName('weight').AsString);
  //��������� ���������
  ShowTrayMessage('���������', '�: '+num+#9+'���: '+SQuery.FieldByName('weight').AsString, 1);

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'pkdat_correct -> '+SQuery.FieldByName('id_asutp').AsString);
  {$ENDIF}

  try
    SqlSaveToOracle(SQuery.FieldByName('id_asutp').AsString, SQuery.FieldByName('weight').AsString);

    SQuery.Close;
    SQuery.SQL.Clear;
    SQuery.SQL.Add('UPDATE weight SET transferred=1');
    SQuery.SQL.Add('where id_asutp='+pkdat_correct+num_correct+num_ingot_correct+'');
    SQuery.ExecSQL;

    //��������� ���������� ���������
    form1.l_last_save_weight.Caption := timetostr(NOW);
  except
      on E : Exception do
        SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
  end;

  //������� ������ ������ 6 ������� 2629743(���� �����)*6
  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('DELETE FROM weight');
  SQuery.SQL.Add('where timestamp<(strftime(''%s'',''now'')-(2629743*6))');
  SQuery.ExecSQL;

  //��������� ������ (������) �� ���������
  NextWeightToRecord;

  //���� ������� ������
  SendAttribute;

  //����������, ��� �� �������� �� �����
  SqlSaveToOracleOfBuffer;
end;


function SqlSaveToOracleOfBuffer: Bool;
var
  i: integer;
  Byffer: array of array of variant;
begin
  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT id_asutp, weight FROM weight');
  SQuery.SQL.Add('where transferred=0');
  SQuery.SQL.Add('order by id asc limit 10'); //�������� �� 10 ��
  SQuery.Open;

  i := 0;
  while not SQuery.Eof do
   begin
      if i = Length(Byffer) then SetLength(Byffer, i+1, 2);
      Byffer[i,0] := SQuery.FieldByName('id_asutp').AsString;
      Byffer[i,1] := SQuery.FieldByName('weight').AsString;
      inc(i);
      SQuery.Next;
   end;

  for i := Low(Byffer) to High(Byffer) do
   begin
    {$IFDEF DEBUG}
      SaveLog('debug'+#9#9+'id_asutp -> '+Byffer[i,0]);
      SaveLog('debug'+#9#9+'weight -> '+Byffer[i,1]);
    {$ENDIF}
      try
        SqlSaveToOracle(Byffer[i,0], Byffer[i,1]);

        SQuery.Close;
        SQuery.SQL.Clear;
        SQuery.SQL.Add('UPDATE weight SET transferred=1');
        SQuery.SQL.Add('where id_asutp='+Byffer[i,0]+'');
        SQuery.ExecSQL;

        SaveLog('sql'+#9#9+'write'+#9+'id_asutp -> '+Byffer[i,0]);
        SaveLog('sql'+#9#9+'write'+#9+'weight -> '+Byffer[i,1]);
      except
        on E : Exception do
          SaveLog('error'+#9#9+E.ClassName+', � ����������: '+E.Message);
      end;
   end;
end;


function SqlSaveToOracle(IdIn, WeightIn: AnsiString): Bool;
begin

    Module1.OraQuery1.FetchAll := true;
    Module1.OraQuery1.Close;
    Module1.OraQuery1.SQL.Clear;
    Module1.OraQuery1.SQL.Add('INSERT INTO crop');
    Module1.OraQuery1.SQL.Add('(id_asutp, weight_bloom)');
    Module1.OraQuery1.SQL.Add('VALUES ('+IdIn+', '+PointReplace(WeightIn)+')');
    Module1.OraQuery1.ExecSQL;

  {$IFDEF DEBUG}
    SaveLog('debug'+#9#9+'Module1.OraQuery1.SQL.Text -> '+Module1.OraQuery1.SQL.Text);
  {$ENDIF}
end;


function SqlReadTable(InData: string): bool;
begin
  Module1.pFIBDataSet1.Active := false;
  Module1.pFIBDataSet1.Close;
  Module1.pFIBDataSet1.SQLs.SelectSQL.Clear;
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('select i.pkdat,i.num,i.num_ingot,h.num_heat, s.name,i.weight_ingot, i.time_ingot, s.steel_group, sh.smena');
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('from ingots i, heats h, steels s, shifts sh');
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('where i.pkdat=h.pkdat');
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and i.pkdat=sh.pkdat');
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and i.num=h.num');
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and h.steel_grade=s.steel_grade');
//  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and Pkdat=(select max(PKdat) from heats)');
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('and pkdat in ('+InData+')');
  Module1.pFIBDataSet1.SQLs.SelectSQL.Add('order by i.pkdat desc, i.num desc, i.num_ingot desc');
  Module1.pFIBDataSet1.Open;
  Module1.pFIBDataSet1.Active := true;

  //���������� ����������� ���� � DBGrid -> pFIBDataSet1
  TDateTimeField(Module1.pFIBDataSet1.FieldByName('time_ingot')).DisplayFormat:='hh:nn:ss';

  form1.l_current_shift.Caption := CurrentShift;
end;



end.
