unit Reports;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB, ShellAPI, StdCtrls, Mask, DBCtrls, Menus, Grids,
  DBGrids, DBTables, ExtCtrls, ComCtrls, OoMisc, AdPort, AdPacket;


var
    title: string = '�����: �������� ����� ������� ��-4';
    FileReport: string = 'report.html';
    f:TextFile;

    function Report(DataIn: integer): bool;
    function ReportDetailed: bool;
    function HtmlStyle: bool;
    function ViewReport: bool;

implementation

uses main,sql;



{------------------------------------------------------------------------------}


function Report(DataIn: integer): bool;
var
    DtStart: string;
    DtEnd: string;
    FileO:string;
    _start:integer;
    _end:integer;
    a_mass_ingot,a_mass,a_p_s_c,a_a_s_c,a_aberration: Extended;
    a_count: integer;

begin

    a_mass_ingot :=0;
    a_mass := 0;
    a_p_s_c := 0;
    a_a_s_c := 0;
    a_aberration := 0;
    a_count := 0;

  If Form1.DateTimeStart.date > Form1.DateTimeEnd.date then
  begin
    showmessage('���� ��������� ������� �������.');
    exit;
  end;


      DtStart := ConvertDateTime(form1.DateTimeStart.date);
      DtEnd := ConvertDateTime(form1.DateTimeEnd.date);

    // �������� ����� ������
    DataModule2.query_reports.Active := false;
    DataModule2.query_reports.SQL.Clear;
{    DataModule2.query_reports.SQL.Add('SELECT VVES.*, dbo.Protocol.* FROM dbo.Protocol,');
    DataModule2.query_reports.SQL.Add('(SELECT IDPlavki, NSmeni, COUNT(Ves.IDPlavki) AS KolVo, SUM(VesZagotovki) AS SumVes');
    DataModule2.query_reports.SQL.Add('FROM  dbo.Ves');
    DataModule2.query_reports.SQL.Add('WHERE (Ves.NSmeni = 1 and CONVERT(VARCHAR(10),Ves.Dates2,120) = '''+ ConvertDateTime(Form1.DateTimeStart.date - 1) + ''' and DATEPART(hh, Ves.Dates2) >=22)');
    DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),Ves.Dates2,120) >= ''' + DtStart + '''');
    DataModule2.query_reports.SQL.Add('AND CONVERT(VARCHAR(10),Dates2,120) < ''' + DtEnd + ''')');
    DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),Dates2,120) = ''' + DtEnd + ''' AND DATEPART(hh, Ves.Dates2) < 22)');
    DataModule2.query_reports.SQL.Add('GROUP BY IDPlavki, NSmeni) AS VVES');
    DataModule2.query_reports.SQL.Add('WHERE VVES.IDPlavki = dbo.Protocol.IDPlavki');
    DataModule2.query_reports.SQL.Add('ORDER BY dbo.Protocol.Dates1');
 }
    if DataIn = 0 then
      begin
            DataModule2.query_reports.SQL.Add('SELECT mass.datetime,heats.name,heats.no_shifts, sums.* FROM scale_turntable.dbo.heats, scale_turntable.dbo.mass,');
            DataModule2.query_reports.SQL.Add('(SELECT min(id_m) as id_m, num_heat, sum(mass_ingot) as s_mass_ingot, sum(mass) as s_mass, sum(mass_difference) as s_mass_difference,');
            DataModule2.query_reports.SQL.Add('sum(p_s_c) as s_p_s_c, sum(a_s_c) as s_a_s_c, sum(aberration) as s_aberration,');
            DataModule2.query_reports.SQL.Add('count(num_heat) as s_count FROM scale_turntable.dbo.heats, scale_turntable.dbo.mass');
            DataModule2.query_reports.SQL.Add('WHERE id_m=id_h');
            DataModule2.query_reports.SQL.Add('AND (no_shifts = 1 and CONVERT(VARCHAR(10),datetime,120) = '''+ ConvertDateTime(Form1.DateTimeStart.date - 1) + ''' and DATEPART(hh, datetime) >=22');
            DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),datetime,120) >= ''' + DtStart + '''))');
            DataModule2.query_reports.SQL.Add('AND (CONVERT(VARCHAR(10),datetime,120) < ''' + DtEnd + '''');
            DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),datetime,120) =  ''' + DtEnd + ''' AND DATEPART(hh, datetime) < 22))');
            DataModule2.query_reports.SQL.Add('group by num_heat) as sums');
      end;

    if DataIn = 1 then
      begin
            DataModule2.query_reports.SQL.Add('SELECT mass.datetime,heats.num_heat,heats.no_shifts, sums.* FROM scale_turntable.dbo.heats, scale_turntable.dbo.mass,');
            DataModule2.query_reports.SQL.Add('(SELECT min(id_m) as id_m, name, sum(mass_ingot) as s_mass_ingot, sum(mass) as s_mass, sum(mass_difference) as s_mass_difference,');
            DataModule2.query_reports.SQL.Add('sum(p_s_c) as s_p_s_c, sum(a_s_c) as s_a_s_c, sum(aberration) as s_aberration,');
            DataModule2.query_reports.SQL.Add('count(name) as s_count FROM scale_turntable.dbo.heats, scale_turntable.dbo.mass');
            DataModule2.query_reports.SQL.Add('WHERE id_m=id_h');
            DataModule2.query_reports.SQL.Add('AND (no_shifts = 1 and CONVERT(VARCHAR(10),datetime,120) = '''+ ConvertDateTime(Form1.DateTimeStart.date - 1) + ''' and DATEPART(hh, datetime) >=22');
            DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),datetime,120) >= ''' + DtStart + '''))');
            DataModule2.query_reports.SQL.Add('AND (CONVERT(VARCHAR(10),datetime,120) < ''' + DtEnd + '''');
            DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),datetime,120) =  ''' + DtEnd + ''' AND DATEPART(hh, datetime) < 22))');
            DataModule2.query_reports.SQL.Add('group by name) as sums');
      end;


    DataModule2.query_reports.SQL.Add('where sums.id_m=mass.id_m');
    DataModule2.query_reports.SQL.Add('and sums.id_m=heats.id_h');
    DataModule2.query_reports.SQL.Add('ORDER BY datetime asc');
    DataModule2.query_reports.Active:=true;
    DataModule2.query_reports.Open;


        //������ �����, ���������
         if DataModule2.query_reports.RecordCount > 0 then
           begin
                    //�������� � ���������� �����
                    FileO:= CurrentDir+'\'+FileReport;
                    AssignFile(f,FileO);
                    //if not FileExists(FileO) then
                     //begin
                      Rewrite(f);
                      CloseFile(f);
                     //end;
                     Append(f);

                     //���������
                     Writeln(f,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'+#13);
                     Writeln(f,'<html>'+#13+'<head>'+#13);
                     Writeln(f,'<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">'+#13+'</head>'+#13+'<body>'+#13+'<div align="center">'+#13);
                     Writeln(f,'<title>'+title+'</title>'+#13);

                     //style
                     HtmlStyle;

                     Writeln(f,'<table>');

                     Writeln(f,'<div><table class="blank"><th>'+title+'</th></table></div><hr><br /><br />'+#13+#10);
           end
         else
           begin
                     showmessage('�� �������� ������ ������ ��� ������ ���');
           end;

     while not DataModule2.query_reports.Eof do
      begin
        //��������� �� ������� ��� �� ����
        if  (_start <> DataModule2.query_reports.FieldByName('no_shifts').AsInteger)
            or ((DataModule2.query_reports.FieldByName('no_shifts').AsInteger <> 1) and (DtStart <> copy(DataModule2.query_reports.FieldByName('datetime').AsString,0,10))) then
            begin

                if _end = 1 then
                begin
                    //����� ������
                    Writeln(f,'</table></div><br />'+#13+#10);

                    //����� � �����
                    Writeln(f,'<div><table class="blank">'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ��������� : '+'</td><td id="align-right">'+
//                              DT(Form1.query_reports.FieldByName('Dates1').AsString, Form1.query_reports.FieldByName('NSmeni').AsInteger, 1)+'</td></tr>'+#13+#10);
                              DataModule2.query_reports.FieldByName('datetime').AsString+'</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ������� �� ����� ��-1: '+'</td><td id="align-right">'+floattostr(a_mass_ingot)+' ����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ������ �� ����� : '+'</td><td id="align-right">'+floattostr(a_mass)+' ����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">�������� �������� ������ �� ����� : '+'</td><td id="align-right">'+floattostr(a_p_s_c)+' ����/����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����������� �������� ������ �� ����� : '+'</td><td id="align-right">'+floattostr(a_a_s_c)+' ����/����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">���������� �� ����� (+/-) �� ����� : '+'</td><td id="align-right">'+floattostr(a_aberration)+' ����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">��������� ����� : '+'</td><td id="align-right">'+inttostr(a_count)+' ��</td></tr>'+#13+#10);
                    Writeln(f,'</table></div><br /><br />'+#13+#10);

                    _end:=0;
                end;

                 Writeln(f,'<div><table class="blank">'+#13+#10);
                 Writeln(f,'<tr><td id="align-left">����� ����� : '+'</td><td id="align-right">'+DataModule2.query_reports.FieldByName('no_shifts').AsString+'</td></tr>'+#13+#10);
                 Writeln(f,'<tr><td id="align-left">������ ��������� : '+'</td><td id="align-right">'+
//                           DT(Form1.query_reports.FieldByName('Dates1').AsString, Form1.query_reports.FieldByName('NSmeni').AsInteger, 0)+'</td></tr>'+#13+#10);
                           DataModule2.query_reports.FieldByName('datetime').AsString+'</td></tr>'+#13+#10);
                 Writeln(f,'</table></div><br />'+#13+#10);

                 //������ ������ ��������� ��������
                 Writeln(f,'<div><table>'+#13+#10);
                 Writeln(f,'<tr>'+#13+#10);
                 Writeln(f,'<th>�����</th>'+#13+#10);
                 Writeln(f,'<th>� ������</th>'+#13+#10);
                 Writeln(f,'<th>����� �����</th>'+#13+#10);
                 Writeln(f,'<th>���������� �����.</th>'+#13+#10);
                 Writeln(f,'<th>����� ������ ��-1</th>'+#13+#10);
                 Writeln(f,'<th>����� �����</th>'+#13+#10);
                 Writeln(f,'<th>������� ���� (�)</th>'+#13+#10);
                 Writeln(f,'<th>�������� �������� ������ (�/�)</th>'+#13+#10);
                 Writeln(f,'<th>����������� �������� (�/�)</th>'+#13+#10);
                 Writeln(f,'<th>���������� �� ����� (+/-,�)</th>'+#13+#10);
                 Writeln(f,'</tr>'+#13+#10);

                 _start := DataModule2.query_reports.FieldByName('no_shifts').AsInteger;
                 DtStart :=copy(DataModule2.query_reports.FieldByName('datetime').AsString,0,10);
                 _end := 1;
                 a_mass_ingot := 0;
                 a_mass := 0;
                 a_p_s_c := 0;
                 a_a_s_c := 0;
                 a_aberration := 0;
                 a_count := 0;
            end
        else
            begin
              Writeln(f,'<tr>'+
                        '<td>'+DataModule2.query_reports.FieldByName('datetime').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('num_heat').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('name').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('s_count').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('s_mass_ingot').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('s_mass').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('s_mass_difference').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('s_p_s_c').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('s_a_s_c').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('s_aberration').AsString+'</td>'+
                        '</tr>'+#13+#10
                     );

                        a_mass_ingot := a_mass_ingot + DataModule2.query_reports.FieldByName('s_mass_ingot').AsExtended;
                        a_mass := a_mass + DataModule2.query_reports.FieldByName('s_mass').AsExtended;
                        a_p_s_c := a_p_s_c + DataModule2.query_reports.FieldByName('s_p_s_c').AsExtended;
                        a_a_s_c := a_a_s_c + DataModule2.query_reports.FieldByName('s_a_s_c').AsExtended;
                        a_aberration := a_aberration + DataModule2.query_reports.FieldByName('s_aberration').AsExtended;
                        a_count := a_count + DataModule2.query_reports.FieldByName('s_count').AsInteger;
              DataModule2.query_reports.Next;
            end;
      end;

        if DataModule2.query_reports.RecordCount > 0 then
         begin
                    //����� ������
                    Writeln(f,'</table></div><br />'+#13+#10);

                    //����� � �����
                    Writeln(f,'<div><table class="blank">'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ��������� : '+'</td><td id="align-right">'+
//                              DT(Form1.query_reports.FieldByName('Dates1').AsString, Form1.query_reports.FieldByName('NSmeni').AsInteger, 1)+'</td></tr>'+#13+#10);
                              DataModule2.query_reports.FieldByName('datetime').AsString+'</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ������� �� ����� ��-1: '+'</td><td id="align-right">'+floattostr(a_mass_ingot)+' ����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ������ �� ����� : '+'</td><td id="align-right">'+floattostr(a_mass)+' ����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">�������� �������� ������ �� ����� : '+'</td><td id="align-right">'+floattostr(a_p_s_c)+' ����/����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����������� �������� ������ �� ����� : '+'</td><td id="align-right">'+floattostr(a_a_s_c)+' ����/����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">���������� �� ����� (+/-) �� ����� : '+'</td><td id="align-right">'+floattostr(a_aberration)+' ����</td></tr>'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">��������� ����� : '+'</td><td id="align-right">'+inttostr(a_count)+' ��</td></tr>'+#13+#10);
                    Writeln(f,'</table></div><br /><br />'+#13+#10);

                    Writeln(f,'</table>');
                    Writeln(f,'</div></body>'+#13+'</html>'+#13);

                    //c���� � ���� � �������� �����
                    Flush(f);
                    CloseFile(f);

                    ViewReport;
         end;
end;

function ReportDetailed: bool;
var
    DtStart: string;
    DtEnd: string;
    FileO: string;
    _start: string;
    _end: string;
begin

  If Form1.DateTimeStart.date > Form1.DateTimeEnd.date then
  begin
    showmessage('���� ��������� ������� �������.');
    exit;
  end;


      DtStart := ConvertDateTime(form1.DateTimeStart.date);
      DtEnd := ConvertDateTime(form1.DateTimeEnd.date);

    // �������� ����� ������
    DataModule2.query_reports.Active := false;
    DataModule2.query_reports.SQL.Clear;
    {
    DataModule2.query_reports.SQL.Add('SELECT V.Dates2,V.VesZagotovki,V.NSMeni, Nv.* FROM  Ps150.dbo.Ves AS V,');
    DataModule2.query_reports.SQL.Add('(SELECT NEdIz,NPlavki,NPartii,MarkaStali,idplavki  FROM Ps150.dbo.Protocol) AS Nv');
    DataModule2.query_reports.SQL.Add('WHERE V.IDPlavki = Nv.IDPlavki');
    DataModule2.query_reports.SQL.Add('AND (V.NSmeni = 1 and CONVERT(VARCHAR(10),V.Dates2,120) = '''+ ConvertDateTime(Form1.DateTimeStart.date - 1) + ''' and DATEPART(hh, V.Dates2) >=22');
    DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),V.Dates2,120) >= ''' + DtStart + '''))');
    DataModule2.query_reports.SQL.Add('AND (CONVERT(VARCHAR(10),V.Dates2,120) < ''' + DtEnd + '''');
    DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),V.Dates2,120) =  ''' + DtEnd + ''' AND DATEPART(hh, V.Dates2) < 22))');
    DataModule2.query_reports.SQL.Add('ORDER BY V.Dates2 ASC');
    }
    DataModule2.query_reports.SQL.Add('SELECT CONVERT(VARCHAR(19),datetime,120) AS datetime,num_heat, name, mass_ingot, mass, mass_difference, p_s_c, a_s_c, aberration, no_shifts FROM scale_turntable.dbo.mass, scale_turntable.dbo.heats');
    DataModule2.query_reports.SQL.Add('WHERE id_m=id_h');
    DataModule2.query_reports.SQL.Add('AND (no_shifts = 1 and CONVERT(VARCHAR(10),datetime,120) = '''+ ConvertDateTime(Form1.DateTimeStart.date - 1) + ''' and DATEPART(hh, datetime) >=22');
    DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),datetime,120) >= ''' + DtStart + '''))');
    DataModule2.query_reports.SQL.Add('AND (CONVERT(VARCHAR(10),datetime,120) < ''' + DtEnd + '''');
    DataModule2.query_reports.SQL.Add('OR (CONVERT(VARCHAR(10),datetime,120) =  ''' + DtEnd + ''' AND DATEPART(hh, datetime) < 22))');
    DataModule2.query_reports.SQL.Add('ORDER BY datetime ASC');
    DataModule2.query_reports.Active:=true;
    DataModule2.query_reports.Open;

        //������ �����, ���������
         if DataModule2.query_reports.RecordCount > 0 then
           begin
                    //�������� � ���������� �����
                    FileO:= CurrentDir+'\'+FileReport;
                    AssignFile(f,FileO);
                    //if not FileExists(FileO) then
                     //begin
                      Rewrite(f);
                      CloseFile(f);
                     //end;
                     Append(f);

                     //���������
                     Writeln(f,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'+#13);
                     Writeln(f,'<html>'+#13+'<head>'+#13);
                     Writeln(f,'<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">'+#13+'</head>'+#13+'<body>'+#13+'<div align="center">'+#13);
                     Writeln(f,'<title>'+title+'</title>'+#13);

                     //style
                     HtmlStyle;

                     Writeln(f,'<table>');

                     Writeln(f,'<div><table class="blank"><th>'+title+'</th></table></div><hr><br /><br />'+#13+#10);
           end
         else
           begin
                     showmessage('�� �������� ������ ������ ��� ������ ���');
           end;

     while not DataModule2.query_reports.Eof do
      begin
        //��������� �� ������� ��� �� ����
        if  (_start <> DataModule2.query_reports.FieldByName('no_shifts').AsString)
            or ((DataModule2.query_reports.FieldByName('no_shifts').AsString <> '1') and (DtStart <> copy(DataModule2.query_reports.FieldByName('datetime').AsString,0,10))) then
            begin

                if _end = '1' then
                begin
                    //����� ������
                    Writeln(f,'</table></div><br />'+#13+#10);

                    //����� � �����
                    Writeln(f,'<div><table class="blank">'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ��������� : '+'</td><td id="align-right">'+
//                              DT(Form1.query_reports.FieldByName('Dates1').AsString, Form1.query_reports.FieldByName('NSmeni').AsInteger, 1)+'</td></tr>'+#13+#10);
                              DataModule2.query_reports.FieldByName('datetime').AsString+'</td></tr>'+#13+#10);
                    Writeln(f,'</table></div><br /><br />'+#13+#10);

                    _end := '0';
                end;

                 Writeln(f,'<div><table class="blank">'+#13+#10);
                 Writeln(f,'<tr><td id="align-left">����� ����� : '+'</td><td id="align-right">'+DataModule2.query_reports.FieldByName('no_shifts').AsString+'</td></tr>'+#13+#10);
                 Writeln(f,'<tr><td id="align-left">������ ��������� : '+'</td><td id="align-right">'+
//                           DT(Form1.query_reports.FieldByName('Dates1').AsString, Form1.query_reports.FieldByName('NSmeni').AsInteger, 0)+'</td></tr>'+#13+#10);
                           DataModule2.query_reports.FieldByName('datetime').AsString+'</td></tr>'+#13+#10);
                 Writeln(f,'</table></div><br />'+#13+#10);

                 //������ ������ ��������� ��������
                 Writeln(f,'<div><table>'+#13+#10);
                 Writeln(f,'<tr>'+#13+#10);
                 Writeln(f,'<th>�����</th>'+#13+#10);
                 Writeln(f,'<th>� ������</th>'+#13+#10);
                 Writeln(f,'<th>����� �����</th>'+#13+#10);
                 Writeln(f,'<th>����� ������ ��-1</th>'+#13+#10);
                 Writeln(f,'<th>����� �����</th>'+#13+#10);
                 Writeln(f,'<th>������� ���� (�)</th>'+#13+#10);
                 Writeln(f,'<th>�������� �������� ������ (�/�)</th>'+#13+#10);
                 Writeln(f,'<th>����������� �������� (�/�)</th>'+#13+#10);
                 Writeln(f,'<th>���������� �� ����� (+/-,�)</th>'+#13+#10);
                 Writeln(f,'</tr>'+#13+#10);

                 _start := DataModule2.query_reports.FieldByName('no_shifts').AsString;
                 DtStart :=copy(DataModule2.query_reports.FieldByName('datetime').AsString,0,10);
                 _end := '1';
            end
        else
            begin
              Writeln(f,'<tr>'+
                        '<td>'+DataModule2.query_reports.FieldByName('datetime').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('num_heat').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('name').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('mass_ingot').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('mass').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('mass_difference').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('p_s_c').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('a_s_c').AsString+'</td>'+
                        '<td>'+DataModule2.query_reports.FieldByName('aberration').AsString+'</td>'+
                        '</tr>'+#13+#10
                     );

               DataModule2.query_reports.Next;
            end;
      end;

        if DataModule2.query_reports.RecordCount > 0 then
         begin
                    //����� ������
                    Writeln(f,'</table></div><br />'+#13+#10);

                    //����� � �����
                    Writeln(f,'<div><table class="blank">'+#13+#10);
                    Writeln(f,'<tr><td id="align-left">����� ��������� : '+'</td><td id="align-right">'+
//                              DT(Form1.query_reports.FieldByName('Dates1').AsString, Form1.query_reports.FieldByName('NSmeni').AsInteger, 1)+'</td></tr>'+#13+#10);
                              DataModule2.query_reports.FieldByName('datetime').AsString+'</td></tr>'+#13+#10);
                    Writeln(f,'</table></div><br /><br />'+#13+#10);

                    Writeln(f,'</table>');
                    Writeln(f,'</div></body>'+#13+'</html>'+#13);

                    //c���� � ���� � �������� �����
                    Flush(f);
                    CloseFile(f);

                    ViewReport;
         end;
end;

function ViewReport: bool;
begin
                   //�� ����� "\" ���� � �����
                   if  CurrentDir[length(CurrentDir)] <> '\' then
                    begin
                          //ShellExecute(Form1.Handle, 'open', 'c:\tmp\arm_ps1_spc1_disomat\report.html', nil, nil, SW_SHOWNORMAL);
                          ShellExecute(0,'open','iexplore.exe',pchar(CurrentDir+'\'+FileReport),nil,SW_SHOWNORMAL);
                    end
                   else
                    begin
                          ShellExecute(0,'open','iexplore.exe',pchar(CurrentDir+FileReport),nil,SW_SHOWNORMAL);
                    end;
end;

function HtmlStyle: bool;
begin
                   //style
                   Writeln(f,'<style type="text/css">'+#13+
                             'table {'+#13+
                                              'border-width: 0px;'+#13+
                                              'margin: 1px;'+#13+
                                              'border-spacing: 2px;'+#13+
                                              'border-style: outset;'+#13+
                                              'border-color: gray;'+#13+
                                              'border-collapse: collapse;'+#13+
                                              'font-size: 1em;'+#13+
                                              'text-align: center;'+#13+
                                      '}'+#13+

                              'table th {'+#13+
                                              'border-width: 1px;'+#13+
                                              'padding: 1px;'+#13+
                                              'border-style: solid;'+#13+
                                              'border-color: gray;'+#13+
                                              '-moz-border-radius: 0px 0px 0px 0px;'+#13+
                                       '}'+#13+

                              'table td {'+#13+
                                              'border-width: 1px;'+#13+
                                              'padding: 1px;'+#13+
                                              'border-style: solid;'+#13+
                                              'border-color: gray;'+#13+
                                              '-moz-border-radius: 0px 0px 0px 0px;'+#13+
                                       '}'+#13+

                              'table.blank {'+#13+
                                              'border-width: 0px;'+#13+
                                              'font-size: 1em;'+#13+
                                      '}'+#13+

                              'table.blank th {'+#13+
                                                  'border-width: 0px;'+#13+
                                                  'font-size: 1em;'+#13+
                                              '}'+#13+

                              'table.blank td {'+#13+
                                                  'border-width: 0px;'+#13+
                                                  'font-size: 1em;'+#13+
                                              '}'+#13+

                              '#align-left {'+#13+
                                                  'text-align: left;'+#13+
                                           '}'+#13+

                              '#align-right {'+#13+
                                                  'text-align: right;'+#13+
                                           '}'+#13+

                             '</style>'+#13);
end;

end.
