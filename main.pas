{
����� ���� � ������� DISOMAT 432:����������
��������� � S1
������ - RS232
�������� - 9600
������������ ����� -  ���
������ � 8 ��� ���
�������� ��� - 1

����� ���� � ������� DISOMAT 4331:������������
��������� � ��� S1
��������� - DDP 8785

ApdComPort
Parity - pEven


��� ��������� interbase
������� ��������������� ������� ODBC firebird
������������� ���������� � ������ ����������>��� �������� ������ ����������>�����������������>��������� ������ (ODBC)
�������� ���������� = firebird
ip = 10.21.22.22
���� � ���� = c:\Account.gdb
login = SYSDBA
password = MASTERKEY
}

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB, ShellAPI, StdCtrls, Mask, DBCtrls, Menus, Grids,
  DBGrids, DBTables, ExtCtrls, ComCtrls, OoMisc, AdPort, AdPacket, Reports,db_weight;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button4: TButton;
    Timer1: TTimer;
    DBGrid2: TDBGrid;
    ApdComPort1: TApdComPort;
    ApdDataPacket1: TApdDataPacket;
    Label7: TLabel;
    Label10: TLabel;
    b_report_detailed: TButton;
    b_report_heat: TButton;
    DateTimeEnd: TDateTimePicker;
    Label6: TLabel;
    DateTimeStart: TDateTimePicker;
    Label5: TLabel;
    DBGrid1: TDBGrid;
    b_selected: TButton;
    b_report_steel: TButton;
    p_weight_ingot: TPanel;
    Label8: TLabel;
    l_steel_group: TLabel;
    Label1: TLabel;
    Label3: TLabel;
    l_weight_ingot: TLabel;
    l_name: TLabel;
    Label4: TLabel;
    Label2: TLabel;
    l_num_heat: TLabel;
    l_datetime: TLabel;
    Label9: TLabel;
    Panel2: TPanel;
    p_head: TPanel;
    l_current_shift1: TLabel;
    l_sql_work1: TLabel;
    l_work_p1: TLabel;
    l_sql_work2: TLabel;
    l_work_p2: TLabel;
    l_current_shift2: TLabel;
    l_calendar1: TLabel;
    l_calendar2: TLabel;
    l_num_ingot: TLabel;
    Label11: TLabel;
    procedure InitForm(Sender: TObject);
    procedure InitComPort(Sender: TObject);
    procedure InitSql(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure b_report_heatClick(Sender: TObject);
    procedure b_report_steelClick(Sender: TObject);
    procedure b_report_detailedClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ApdDataPacket1StringPacket(Sender: TObject; Data: AnsiString);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure b_selectedClick(Sender: TObject);





  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  Form1: TForm1;
  formattedDateTime: string;
  CurrentDir: string;
  HeadName: string = '��� ������� ��-4';
  max: integer = 0;
  no_save: string = '0';
  StartTime: TDateTime;


  // ��������������� ���� � sql ������
  function ConvertDateTime(date: TDateTime): string;
  function GetShift: string;
  function hash_bcc(InChar :string):char;
  function ReceiveData(Data: AnsiString): string;
  function SendAttribute: Bool;
  function SaveWeightSql(DataIn: AnsiString): Bool;
  function CheckData(DataIn, a: AnsiString): bool;
  function ViewSql: bool;
  function NewWeightSql: bool;

  //new
  function TimeWorkProgram: bool;
  function ViewWeightIngot(DataIn: bool): bool;
  function PointReplace(DataIn: string): string;
  function ViewShift: bool;



implementation

uses
  sql;

{$R *.dfm}

procedure TForm1.InitForm(Sender: TObject);
begin

  //����� ������ ���������
  StartTime :=  NOW;

  Form1.Caption := HeadName;
  //��������� � showmessage
  Application.Title := HeadName;

  //������� ����������
  CurrentDir := GetCurrentDir;

  InitSql(Sender);

  DateTimeStart.DateTime := date;
  DateTimeEnd.DateTime := date;


  InitComPort(Sender);

  //������ �������
  Timer1.Enabled:= True;
  Timer1.Interval:=500;

  DataModule2.ib_timer.Enabled:= True;
  DataModule2.ib_timer.Interval:=5000; //5cek

  //����������� ������� �����
  l_current_shift1.Caption := '����� �����:';
  l_current_shift2.Caption := GetShift;

  //��������� ��������� ������ � DBGrid �� ����
  ViewSql;
  //��������� ��������� ������ � DBGrid �� ����
  ViewDbWeight;

  Label6.Caption:='F1 - ����� �� ������'+#13+'F2 - ����� �� ����� �����'
                   +#13+'F3 - ��������� �����';

  //����� ������ ���������
  TimeWorkProgram;

  //������� Caption
  if strtoint(MaxIdDBWeight)-1 = 0 then
    begin
        ViewWeightIngot(false);
    end
  else
    begin
      NextRecDbWeight;
//      ViewWeightIngot(true);
    end;

end;


procedure TForm1.InitComPort(Sender: TObject);
begin

      //init port
      ApdComPort1.Baud := 9600;
      ApdComPort1.DataBits := 8;
      ApdComPort1.Parity := pEven;
      ApdComPort1.StopBits := 1;

      //������������� ������ ������
      ApdDataPacket1.StartCond := scString;
      ApdDataPacket1.StartString := #2; //start bit
      ApdDataPacket1.EndCond := [ecString];
      ApdDataPacket1.EndString := #3; //stop bit
      ApdDataPacket1.IncludeStrings := true;

end;

procedure TForm1.InitSql(Sender: TObject);
begin
  try
        DataModule2.ADOConnection1.CommandTimeout:=30;
        DataModule2.ADOConnection1.ConnectionTimeout:=30;
        DataModule2.ADOConnection1.Connected:=True;
  except
        showmessage('������ ���������� � ��������� ����� ������.' +#13#10+ '���������� ����� �������.');
        DataModule2.ADOConnection1.Connected:=False;
        TerminateProcess(GetCurrentProcess, 0);
  end;

  try
        DataModule2.ib_connection.CommandTimeout:=30;
        DataModule2.ib_connection.ConnectionTimeout:=30;
        DataModule2.ib_connection.Connected:=True;
  except
        showmessage('������ ���������� � ��������� ����� ������.' +#13#10+ '���������� ����� �������.');
        DataModule2.ib_connection.Connected:=False;
        TerminateProcess(GetCurrentProcess, 0);
  end;

  l_sql_work1.Caption := '���������� � ��: ';
  l_sql_work2.Caption := datetostr(NOW) + ' ' + FormatDateTime('hh:mm', NOW);

{ ConnectionString
  MSSQL
  Provider=SQLOLEDB.1;Password=12345678;Persist Security Info=True;User ID=sa;Initial Catalog=scale_turntable;Data Source=krr-ws03302;Use Procedure for Prepare=1;Auto Translate=True;Packet Size=4096;Workstation ID=KRR-WS08022;Use Encryption for Data=False;Tag with column collation when possible=False

  interbase
  Provider=MSDASQL.1;Password=masterkey;Persist Security Info=True;User ID=sysdba;Data Source=firebird
}
end;

procedure TForm1.b_report_heatClick(Sender: TObject);
begin
      Report(0);
end;

procedure TForm1.b_report_steelClick(Sender: TObject);
begin
      Report(1);
end;

procedure TForm1.b_report_detailedClick(Sender: TObject);
begin
      ReportDetailed;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin

    //test
    SaveWeightSql('6,1');

    //�������� label
    NewRecDbWeight;

    //��� ����� - �������� ������
    //NextRecDbWeight;

end;


procedure TForm1.b_selectedClick(Sender: TObject);
begin
      if MessageDlg('������� ��������� ��� �����������?', mtCustom, mbYesNo, 0) = mrYes then
        begin
               ViewWeightIngot(true);
        end;
end;

procedure TForm1.ApdDataPacket1StringPacket(Sender: TObject; Data: AnsiString);
begin
        ReceiveData(Data);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin

    //�������� label
    NewRecDbWeight;

    //��� ����� - �������� ������
    //NextRecDbWeight;

end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
      //��������� ������ � �����
      ApdComPort1.OutPut := #2'00#TK#'#16#3+hash_bcc('00#TK#'#16#3);

      //
      NewWeightSql;

      //����� ������ ���������
      TimeWorkProgram;

      if no_save = '1' then
        begin
              SendAttribute;
        end;

      //����������� ������� �����
      ViewShift;

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
      ApdComPort1.open := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  hMutex : THandle;
begin
        // �������� 2 ��������� ���������
        hMutex := CreateMutex(0, true , 'AarmWeightBlooming1');
        if GetLastError = ERROR_ALREADY_EXISTS then
        begin


          Application.Title := HeadName;
          //������ ����� � ������� ���������
          Application.ShowMainForm:=false;
          showmessage('��������� ��������� ��� �������');


          CloseHandle(hMutex);
          TerminateProcess(GetCurrentProcess, 0);
        end;

end;

Function ConvertDateTime(date: TDateTime): string;
begin
  DateTimeToString(formattedDateTime, 'yyyy-mm-dd', date);
  Result := formattedDateTime;
end;

function SaveWeightSql(DataIn: AnsiString): Bool;
var
    id_m_max: string;
begin

    id_m_max := MaxIdDBWeight;

        try
        // ������ ���� � disomat � SQL
        DataModule2.ADOQuery1.Active := false;
        DataModule2.ADOQuery1.SQL.Clear;
        DataModule2.ADOQuery1.SQL.Add('declare @mass_difference DECIMAL (16,4)');
        DataModule2.ADOQuery1.SQL.Add('declare @a_s_c DECIMAL (16,4)');
        DataModule2.ADOQuery1.SQL.Add('declare @aberration DECIMAL (16,4)');
        DataModule2.ADOQuery1.SQL.Add('set @mass_difference=('+ PointReplace(Form1.l_weight_ingot.Caption) +'-'+ PointReplace(DataIn) +')');
        DataModule2.ADOQuery1.SQL.Add('set @a_s_c=left(('+ PointReplace(Form1.l_weight_ingot.Caption) +'/'+ PointReplace(DataIn) +'),5)');
        DataModule2.ADOQuery1.SQL.Add('set @aberration=(-'+ PointReplace(Form1.l_steel_group.Caption) +'+@a_s_c)');

         DataModule2.ADOQuery1.SQL.Add('Insert INTO scale_turntable.dbo.mass (pkdat, num, num_ingot, datetime, mass, mass_difference, p_s_c, a_s_c, aberration)');
//        DataModule2.ADOQuery1.SQL.Add('VALUES ('+ pkdat +','+ num +','+ num_ingot +', getdate(),'+ PointReplace(DataIn) +','+ PointReplace(MassDifference(Form1.l_weight_ingot.Caption,DataIn)) +','+ PointReplace(Form1.l_steel_group.Caption) +','+ PointReplace(A_S_C(DataIn,Form1.l_weight_ingot.Caption)) +',0.0)');

        DataModule2.ADOQuery1.SQL.Add('VALUES ('+ pkdat +','+ num +','+ num_ingot +', getdate(),'+ PointReplace(DataIn) +',@mass_difference,'+ PointReplace(Form1.l_steel_group.Caption) +',@a_s_c,@aberration)');
        DataModule2.ADOQuery1.SQL.Add('Insert INTO scale_turntable.dbo.heats (id_h, num_heat, name, mass_ingot, no_shifts)');
        DataModule2.ADOQuery1.SQL.Add('VALUES ('+ id_m_max +','+ Form1.l_num_heat.Caption +','''+ Form1.l_name.Caption +''','+ PointReplace(Form1.l_weight_ingot.Caption) +','+ smena +')');
        DataModule2.ADOQuery1.ExecSQL;

        //���� ������� ������
        SendAttribute;

        //��������� ������ (������) �� ���������
        NextRecDbWeight;

        except
             showmessage('������ ������ ���� � ��');
             exit;
        end;
end;

function GetShift: string;
var
  CurrentTime: TDateTime;
  CTime: string;
begin
  CurrentTime := NOW;
  CTime := FormatDateTime('hh:mm:ss', CurrentTime);

  // 2 �����
  if (CTime > '07:00:00') and (CTime < '15:00:00') then
  begin
    Result := '2';
  end;

  // 3 �����
  if (CTime > '15:00:00') and (CTime < '22:00:00') then
  begin
    Result := '3';
  end;

  // 1 �����
  if (CTime > '22:00:00') or (CTime < '07:00:00') then
  begin
     Result := '1';
  end;
end;


function hash_bcc(InChar :string):char;
var
    i :byte;
begin
  result := InChar[1];
  for i := 2 to length(InChar) do
  result := char(ord(result) xor ord(InChar[i]));
end;


function ReceiveData(Data: AnsiString): string;
begin
  if (copy(Data, 2, 6) = '00#EK#') and (copy(Data, 8, 1) = '0') then
  begin
      no_save:='0';
  end;

  if (copy(Data, 2, 6) = '00#TK#') and (copy(Data, 28, 1) = '1') and (no_save = '0') then
  begin
      SaveWeightSql(trim(copy(Data, 40, 6)));
      no_save:='1';
    //copy(Data, 2, 6);          //����� �� ����
    //copy(Data, 28, 1);         //�������
    //trim(copy(Data, 40, 6));   //��� ������ ����� �����
  end;
end;

function SendAttribute: Bool;
begin
      //�������� ��� ����1-4 ���������� 1|0|0|0
      Form1.ApdComPort1.OutPut := #2'00#EK#1#0#0#0#'#16#3+hash_bcc('00#EK#1#0#0#0#'#16#3);
end;

function CheckData(DataIn, a: AnsiString): bool;
var
    i:integer;
begin

      Trim(DataIn);

 if (length(DataIn)=0) then
   begin
             result:=false;
             exit;
   end;

      for i:=1 to length(DataIn) do
      begin
          if not (DataIn[i] in ['0'..'9']) and (a<>'') then
            begin
                  result:=false;
                  break;
            end
          else
            begin
                  result:=true;
                  break;
            end;
      end;

end;

function ViewSql: bool;
begin
        // ��������� ������ � DBGrid �� ����
        DataModule2.ADOQuery1.Active:=false;
        DataModule2.ADOQuery1.SQL.Clear;
        DataModule2.ADOQuery1.SQL.Add('SELECT TOP 100 CONVERT(VARCHAR(19),datetime,120) AS datetime,num_heat, name, mass_ingot, mass, mass_difference, p_s_c, a_s_c, aberration');
        DataModule2.ADOQuery1.SQL.Add('FROM  scale_turntable.dbo.mass, scale_turntable.dbo.heats');
        DataModule2.ADOQuery1.SQL.Add('where id_m=id_h');
        DataModule2.ADOQuery1.SQL.Add('ORDER BY datetime desc');
        DataModule2.ADOQuery1.Active:=true;
        DataModule2.ADOQuery1.Open;
end;

function NewWeightSql: bool;
begin
        DataModule2.query_count.Active:=false;
        DataModule2.query_count.SQL.Clear;
        DataModule2.query_count.SQL.Add('SELECT COUNT(id_m) AS count FROM scale_turntable.dbo.mass');
        DataModule2.query_count.Active:=true;
        DataModule2.query_count.Open;

        if max < DataModule2.query_count.FieldValues['count'] then
        begin
               max:=DataModule2.query_count.FieldValues['count'];
               ViewSql;
        end;
end;

function TimeWorkProgram: bool;
begin
       form1.l_work_p1.Caption := '����� ������ ���������: ';
       form1.l_work_p2.Caption := timetostr(StartTime-NOW);
       //FormatDateTime('hh:mm:ss', NOW);
end;

function ViewWeightIngot(DataIn: bool): bool;
begin
  if DataIn = true then
    begin
      Form1.l_num_ingot.Caption:=Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM_INGOT').AsString;
      Form1.l_datetime.Caption:=Form1.DBGrid1.DataSource.DataSet.FieldByName('TIME_INGOT').AsString;
      Form1.l_num_heat.Caption:=Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM_HEAT').AsString;
      Form1.l_name.Caption:=Form1.DBGrid1.DataSource.DataSet.FieldByName('NAME').AsString;
      Form1.l_weight_ingot.Caption:=Form1.DBGrid1.DataSource.DataSet.FieldByName('WEIGHT_INGOT').AsString;
      Form1.l_steel_group.Caption:=SteelGroupCoefficient(Form1.DBGrid1.DataSource.DataSet.FieldByName('STEEL_GROUP').AsString);
      pkdat:=Form1.DBGrid1.DataSource.DataSet.FieldByName('PKDAT').AsString;
      num:=Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM').AsString;
      num_ingot:=Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM_INGOT').AsString;
      smena:=Form1.DBGrid1.DataSource.DataSet.FieldByName('SMENA').AsString;
    end
  else
    begin
      Form1.l_num_ingot.Caption:='0';
      Form1.l_datetime.Caption:='0';
      Form1.l_num_heat.Caption:='0';
      Form1.l_name.Caption:='0';
      Form1.l_weight_ingot.Caption:='0';
      Form1.l_steel_group.Caption:='0';
    end;
end;

function PointReplace(DataIn: string): string;
begin
      result:=StringReplace(Datain,',','.', [rfReplaceAll]);
end;

function ViewShift: bool;
begin
      if Form1.l_current_shift2.Caption <> GetShift then
        begin
              //����������� ������� �����
              Form1.l_current_shift2.Caption := GetShift;
        end;
end;

{============== PressKey START ===============}
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
          if ord(Key) = 112 then b_report_heat.Click; //F1 = 112
          if ord(Key) = 113 then b_report_steel.Click; //F2 = 113
          if ord(Key) = 114 then b_report_detailed.Click; //F3 = 114
end;
{============== PressKey END ===============}


end.
