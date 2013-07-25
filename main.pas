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
  Dialogs, ShellAPI, StdCtrls, Mask, Menus, Grids, DBGrids, DBTables, ExtCtrls,
  CommCtrl, StrUtils, DateUtils;

type
  TForm1 = class(TForm)
    l_current_id: TLabel;
    l_next_id: TLabel;
    DBGrid1: TDBGrid;
    b_selected: TButton;
    l_n_weight_ingot: TLabel;
    l_weight_ingot: TLabel;
    l_grade: TLabel;
    l_n_grade: TLabel;
    l_n_heat: TLabel;
    l_heat: TLabel;
    l_datetime: TLabel;
    l_n_datetime: TLabel;
    l_n_current_shift: TLabel;
    l_current_shift: TLabel;
    l_number_ingot: TLabel;
    l_n_number_ingot: TLabel;
    TrayIcon: TTrayIcon;
    gb_global: TGroupBox;
    gb_data_pu1: TGroupBox;
    gb_weighed_ingot: TGroupBox;
    b_test: TButton;
    l_n_last_save_weight: TLabel;
    l_last_save_weight: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure TrayPopUpCloseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure b_selectedClick(Sender: TObject);
    procedure b_testClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  Form1: TForm1;
    CurrentDir: string;
    HeadName: string = '��� ������� ��-4';
    Version: string = ' v0.0alpha';
    DBFile: string = 'data.sdb';
    LogFile: string = 'app.log';
    PopupTray: TPopupMenu;
    TrayMark: bool = false;

    formattedDateTime: string;


//    {$DEFINE DEBUG}


    //new
    function ViewSelectedIngot: bool;
    function PointReplace(DataIn: string): string;

    function TrayAppRun: bool;
    function CheckAppRun: bool;
    function ViewClear: bool;
    function CurrentShift: string;
    function NextWeightToRecord: bool;
    function ShowTrayMessage(InTitle, InMessage: string; InFlag: integer): bool;
    function ManipulationWithDate(InDate: string; InType: integer): string;

implementation

uses
  settings, logging, module, thread_comport, thread_sql, sql;

{$R *.dfm}





procedure TForm1.b_selectedClick(Sender: TObject);
begin
  if MessageDlg('������� ��������� ��� �����������?', mtCustom, mbYesNo, 0) = mrYes then
   begin
      ViewSelectedIngot;
   end;
end;


procedure TForm1.b_testClick(Sender: TObject);
begin

  l_current_id.Caption := pkdat+'|'+num+'|'+num_ingot;

  //test
  if pkdat <> '' then
   begin
      SqlSaveInBuffer(inttostr(random(100))+'.88');
      //SqlSaveToOracleOfBuffer;
   end;

end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  //�������� 1 ���������� ���������
  CheckAppRun;

  Form1.Caption := HeadName+Version;
  //��������� � showmessage
  Application.Title := HeadName+Version;

  //������� ����������
  CurrentDir := GetCurrentDir;

  //������ �� ��������� �����
  Form1.BorderStyle := bsToolWindow;
  Form1.BorderIcons :=  Form1.BorderIcons - [biMaximize];

  SaveLog('app'+#9#9+'start');

  //������������� ����
  TrayAppRun;

  form1.l_current_shift.Caption := CurrentShift;

  ViewClear;

  ConfigSettings(true);

  ThreadComPortInit;

  ThreadSqlInit;

end;


function NextWeightToRecord: bool;
var
  KeyValues : Variant;
begin

  SQuery.Close;
  SQuery.SQL.Clear;
  SQuery.SQL.Add('SELECT pkdat, num, num_ingot FROM weight');
  SQuery.SQL.Add('order by id desc limit 1');
  SQuery.Open;

  //��������� ����������
  form1.DBGrid1.DataSource.DataSet.DisableControls;
  try
      //���������� �� ������� ����� ������������� �����
      KeyValues := VarArrayOf([SQuery.FieldByName('pkdat').AsString,
                               SQuery.FieldByName('num').AsString,
                               SQuery.FieldByName('num_ingot').AsString]);
      //����� �� �������� �����
      form1.DBGrid1.DataSource.DataSet.Locate('pkdat;num;num_ingot', KeyValues, []);
  finally
      //�������� ����������
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;

  //����������� �����
  form1.DBGrid1.DataSource.DataSet.MoveBy(-1);

  pkdat := Form1.DBGrid1.DataSource.DataSet.FieldByName('pkdat').AsString;
  num := Form1.DBGrid1.DataSource.DataSet.FieldByName('num').AsString;
  num_ingot  := Form1.DBGrid1.DataSource.DataSet.FieldByName('num_ingot').AsString;
  time_ingot := Form1.DBGrid1.DataSource.DataSet.FieldByName('time_ingot').AsString;
  num_heat := Form1.DBGrid1.DataSource.DataSet.FieldByName('num_heat').AsString;
  name := Form1.DBGrid1.DataSource.DataSet.FieldByName('name').AsString;
  weight_ingot := Form1.DBGrid1.DataSource.DataSet.FieldByName('weight_ingot').AsString;
  smena := Form1.DBGrid1.DataSource.DataSet.FieldByName('smena').AsString;

  Form1.l_number_ingot.Caption := num_ingot;
  Form1.l_datetime.Caption := time_ingot;
  Form1.l_heat.Caption := num_heat;
  Form1.l_grade.Caption := name;
  Form1.l_weight_ingot.Caption := weight_ingot;

  //test
  Form1.l_next_id.Caption:=pkdat+'|'+num+'|'+num_ingot;
end;


function ViewSelectedIngot: bool;
begin
  Form1.l_number_ingot.Caption := Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM_INGOT').AsString;
  Form1.l_datetime.Caption := Form1.DBGrid1.DataSource.DataSet.FieldByName('TIME_INGOT').AsString;
  Form1.l_heat.Caption := Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM_HEAT').AsString;
  Form1.l_grade.Caption := Form1.DBGrid1.DataSource.DataSet.FieldByName('NAME').AsString;
  Form1.l_weight_ingot.Caption := Form1.DBGrid1.DataSource.DataSet.FieldByName('WEIGHT_INGOT').AsString;
  pkdat := Form1.DBGrid1.DataSource.DataSet.FieldByName('PKDAT').AsString;
  num := Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM').AsString;
  num_ingot := Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM_INGOT').AsString;
  smena := Form1.DBGrid1.DataSource.DataSet.FieldByName('SMENA').AsString;
end;


function PointReplace(DataIn: string): string;
begin
      result:=StringReplace(Datain,',','.', [rfReplaceAll]);
end;


function CurrentShift: string;
begin
    if (time > strtotime('22:00:00')) and (time < strtotime('07:00:00')) then
      Result := '1';
    if (time > strtotime('07:00:00')) and (time < strtotime('15:00:00')) then
      Result := '2';
    if (time > strtotime('15:00:00')) and (time < strtotime('22:00:00')) then
      Result := '3';
end;


function ViewClear: bool;
var
  i: integer;
begin

  for i:=0 to form1.ComponentCount - 1 do
   begin
    if (form1.Components[i] is Tlabel) then
      begin
        if copy(form1.Components[i].Name,1,4) <> 'l_n_' then
          Tlabel(Form1.FindComponent(form1.Components[i].Name)).Caption := '';
      end;
   end;

end;


function ShowTrayMessage(InTitle, InMessage: string; InFlag: integer): bool;
begin
{
bfNone = 0
bfInfo = 1
bfWarning = 2
bfError = 3
}

  form1.TrayIcon.BalloonTitle := InTitle;
  form1.TrayIcon.BalloonHint := TimeToStr(NOW)+#9+InMessage;
  form1.TrayIcon.BalloonFlags := TBalloonFlags(InFlag);
  form1.TrayIcon.BalloonTimeout := 4;
  form1.TrayIcon.ShowBalloonHint;
  form1.TrayIcon.OnBalloonClick := form1.TrayIconClick;
end;


function ManipulationWithDate(InDate: string; InType: integer): string;
var
  pkdat_correct: string;
begin
    pkdat_correct := InDate;
    pkdat_correct := StuffString(pkdat_correct, 5, 2, copy(InDate, 1,2));
    pkdat_correct := StuffString(pkdat_correct, 1, 2, copy(InDate, 5,2));
    if InType = 0 then
      Result := pkdat_correct;
    insert('.', pkdat_correct, 5);
    insert('.', pkdat_correct, 3);
    if InType = 1 then
      Result := FormatDateTime('yymmdd', (IncDay(strtodate(pkdat_correct), -1)));
end;






function TrayAppRun: bool;
begin
    PopupTray := TPopupMenu.Create(nil);
    Form1.Trayicon.Hint := HeadName;
    Form1.Trayicon.PopupMenu := PopupTray;
    PopupTray.Items.Add(NewItem('�����', 0, False, True, Form1.TrayPopUpCloseClick, 0, 'close'));
    Form1.Trayicon.Visible := True;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := False;
    Form1.Hide;
end;


procedure TForm1.TrayPopUpCloseClick(Sender: TObject);
var
  buttonSelected: Integer;
begin
  ConfigComPort(false);

  ThreadComPort.Terminate;
  ThreadSql.Terminate;

  SaveLog('app'+#9#9+'close');

  Trayicon.Visible := false;
  //��������� ����������
  TerminateProcess(GetCurrentProcess, 0);
end;


procedure TForm1.TrayIconClick(Sender: TObject);
begin
    if TrayMark then
     begin
//        ShowWindow(Wind, SW_SHOWNOACTIVATE);
//        SetForegroundWindow(Application.Handle);
        form1.show;
        TrayMark := false;
     end
    else
     begin
//        ShowWindow(Application.MainForm.Handle, SW_HIDE);
//        SetForegroundWindow(Application.MainForm.Handle);
        form1.hide;
        TrayMark := true;
     end

//    Trayicon1.Visible := False;
//    PopupTray.Items.Delete(0);
end;


function CheckAppRun: bool;
var
  hMutex : THandle;
begin
    // �������� 2 ��������� ���������
    hMutex := CreateMutex(0, true , 'ArmWeightBlooming1');
    if GetLastError = ERROR_ALREADY_EXISTS then
     begin
        Application.Title := HeadName+Version;
        //������ ����� � ������� ���������
        Application.ShowMainForm:=false;
        showmessage('��������� ��������� ��� �������');

        CloseHandle(hMutex);
        TerminateProcess(GetCurrentProcess, 0);
     end;

end;







end.
