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
  Dialogs, ShellAPI, StdCtrls, Mask, Menus, Grids, DBGrids, ExtCtrls,
  CommCtrl, StrUtils, DateUtils, Data.DB;

type
  TForm1 = class(TForm)
    l_current_id: TLabel;
    l_next_id: TLabel;
    DBGrid1: TDBGrid;
    l_n_weight_ingot: TLabel;
    l_weight_ingot: TLabel;
    l_grade: TLabel;
    l_n_grade: TLabel;
    l_n_heat: TLabel;
    l_heat: TLabel;
    l_datetime: TLabel;
    l_n_datetime: TLabel;
    l_number_ingot: TLabel;
    l_n_number_ingot: TLabel;
    gb_global: TGroupBox;
    gb_data_pu1: TGroupBox;
    gb_weighed_ingot: TGroupBox;
    gb_weighed_ingot_in_sql: TGroupBox;
    DBGrid2: TDBGrid;
    TrayIcon: TTrayIcon;
    l_n_message: TLabel;
    l_status: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure TrayPopUpCloseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure DBGrid2DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DBGrid1DblClick(Sender: TObject);
    function CreateMenu: bool;
    procedure ActionMenuItemClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  Form1: TForm1;
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
    function NextWeightToRecord: bool;
    function ShowTrayMessage(InTitle, InMessage: string; InFlag: integer): bool;
    function ManipulationWithDate(InDate: string): string;
    function MouseMoved: bool;
    function NextWeightToRecordLocation: bool;
    function Status: string;


implementation

uses
  settings, logging, thread_comport, sql, testing, calibration;

{$R *.dfm}





procedure TForm1.FormCreate(Sender: TObject);
begin
  //�������� 1 ���������� ���������
  CheckAppRun;

  Form1.Caption := HeadName+'  build('+GetVersion+')';
  //��������� � showmessage
  Application.Title := Form1.Caption;

  //������ �� ��������� �����
  Form1.BorderStyle := bsToolWindow;
  Form1.BorderIcons := Form1.BorderIcons - [biMaximize];

  Log.save('i', 'start '+Log.ProgFileName);

  //������������� ����
  TrayAppRun;

  ViewClear;

  //����������� � dbgrid
  DBGRid1.DataSource := FDataSource;
  DBGrid2.DataSource := SLDataSource;

  CreateMenu;
end;


function NextWeightToRecord: bool;
var
  KeyValues : Variant;
begin

  try
      //��������� ����������
      form1.DBGrid1.DataSource.DataSet.DisableControls;
      SqlNextWeightToRecord;
      //dbgrid ������� �������� ���������
      NextWeightToRecordLocation;
  finally
      //�������� ����������
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;

{ // ��� ��� ������ � dbgrid ������ sql
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
      //����������� �����
      form1.DBGrid1.DataSource.DataSet.MoveBy(-1);
      //�������� ����������
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;

  //����������� �����
//  form1.DBGrid1.DataSource.DataSet.MoveBy(-1);

{}
  // ������ ��������� ��������� (��������)
{  if (form1.DBGrid1.DataSource.DataSet.FieldByName('pkdat').AsString =
     SQuery.FieldByName('pkdat').AsString) and
     (form1.DBGrid1.DataSource.DataSet.FieldByName('num').AsString =
     SQuery.FieldByName('num').AsString) and
     (form1.DBGrid1.DataSource.DataSet.FieldByName('num_ingot').AsString =
     SQuery.FieldByName('num_ingot').AsString)
  then
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
{}

{  pkdat := Form1.DBGrid1.DataSource.DataSet.FieldByName('pkdat').AsString;
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

  //-- test
  Form1.l_next_id.Caption:=pkdat+'|'+num+'|'+num_ingot;}
end;


function NextWeightToRecordLocation: bool;
var
  KeyValues : Variant;
begin
  try
      //��������� ����������
      form1.DBGrid1.DataSource.DataSet.DisableControls;
      //���������� �� ������� ����� ������������� �����
      KeyValues := VarArrayOf([pkdat,num,num_ingot]);
      //����� �� �������� �����
      form1.DBGrid1.DataSource.DataSet.Locate('pkdat;num;num_ingot', KeyValues, []);
  finally
      //�������� ����������
      form1.DBGrid1.DataSource.DataSet.EnableControls;
  end;
  //-- test
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
  num_heat := Form1.DBGrid1.DataSource.DataSet.FieldByName('NUM_HEAT').AsString;
  smena := Form1.DBGrid1.DataSource.DataSet.FieldByName('SMENA').AsString;
end;


function PointReplace(DataIn: string): string;
begin
      result:=StringReplace(Datain,',','.', [rfReplaceAll]);
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


procedure TForm1.DBGrid1DblClick(Sender: TObject);
begin
  // ������ ��������� ���������
  if not MarkerNextWait then begin
    try
        //��������� ����������
        form1.DBGrid1.DataSource.DataSet.DisableControls;
        if MessageDlg('������� ��������� ��� �����������?', mtCustom, mbYesNo, 0) = mrYes then
          ViewSelectedIngot;
    finally
        //�������� ����������
        form1.DBGrid1.DataSource.DataSet.EnableControls;
    end;
  end;
end;


procedure TForm1.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
    if  gdSelected in State	then //color selected
    begin
      with DBGrid1.Canvas do
      begin
        (Sender as TDBGrid).Canvas.Brush.Color:= $002CB902;//green
		    (Sender as TDBGrid).Canvas.Font.Color := clHighLightText;
      end;
    end;
    Dbgrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;


procedure TForm1.DBGrid2DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  R: TRect;
begin
    R := Rect;
    Dec(R.Bottom, 2);
    //�������� ������� ������ � ���������� ������� weight
    if SqlMaxLocal <> 0 then
    begin

        if  gdSelected in State	then //color selected
        begin
            with DBGrid2.Canvas do
            begin
      	  		(Sender as TDBGrid).Canvas.Brush.Color:= clMedGray;
		        	(Sender as TDBGrid).Canvas.Font.Color := clHighLightText;
            end;
		    end;

        if (Column.FieldName = 'transferred') then
        begin
          if SLQuery.FieldByName('transferred').AsString = '�� �������' then
           begin
              with DBGrid2.Canvas do
              begin
                Font.Color := clRed;
                font.Style:= [fsBold];
                (Sender as TDBGrid).Canvas.TextRect(Rect, Rect.Left + 2,
                                      Rect.Top + 2, Column.Field.AsWideString);
              end
           end
          else
           begin
              with DBGrid2.Canvas do
              begin
                Font.Color := $002CB902;//green
                font.Style:= [fsBold];
                (Sender as TDBGrid).Canvas.TextRect(Rect, Rect.Left + 2,
                                      Rect.Top + 2, Column.Field.AsWideString);
              end
          end;
      end
      else
        Dbgrid2.DefaultDrawColumnCell(Rect, DataCol, Column, State);
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


// ��������� ����������������� 1401292 -> 2901142, ��� id_asutp
function ManipulationWithDate(InDate: string): string;
var
  pkdat_correct: string;
begin
    pkdat_correct := InDate;
    pkdat_correct := StuffString(pkdat_correct, 5, 2, copy(InDate, 1,2));
    pkdat_correct := StuffString(pkdat_correct, 1, 2, copy(InDate, 5,2));
    Result := pkdat_correct;
end;


function MouseMoved: bool;
var
  MousePoint: TPoint;
begin
  GetCursorPos(MousePoint);
  {����������� MousePoint � "mickeys" (��������� ����������� ������� �����}
  MousePoint.x := Round(MousePoint.x * (65535 / Screen.Width));
  MousePoint.y := Round(MousePoint.y * (65535 / Screen.Height));
  {���������� ������ ����}
  Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_MOVE, MousePoint.x-20, MousePoint.y-20, 0, 0);
  {���������� ������ ����}
  Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_MOVE, MousePoint.x+20, MousePoint.y+20, 0, 0);
end;



function Status: string;
var
  status: bool;
begin
  if pkdat.IsEmpty then
  begin
    //��������� ���������
    ShowTrayMessage('��������', '��� ������ ������ ������������ ���������', 2);
    form1.l_status.Caption := '����� ��������� ����������';
    status := true;
  end;

  if (not pkdat.IsEmpty) and (not no_save) then
  begin
    form1.l_status.Caption := '�������� ������ � �������� �����������';
    status := true;
  end;

  if (not pkdat.IsEmpty) and no_save then
  begin
    form1.l_status.Caption := '������������� ������ ���� �������� �����������';
    status := true;
  end;

  if status then
    form1.l_status.Visible := true
  else
    form1.l_status.Visible := false;


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
  ThreadComPort.Terminate;

  Log.save('i', 'close '+Log.ProgFileName);

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
    hMutex := CreateMutex(0, true , PWideChar(Log.ProgFileName));
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


function TForm1.CreateMenu: bool;
var
    MainMenu: TMainMenu;
    itemMenu, itemTesting, itemCalibration, itemExit: TMenuItem;
begin
  MainMenu := TMainMenu.Create(form1);
  itemMenu := TMenuItem.Create(MainMenu);

  itemMenu.Caption := '����';
  itemMenu.Name:='main';
  MainMenu.Items.Add(itemMenu);

  itemTesting := TMenuItem.Create(itemMenu);
  itemTesting.Caption := '������������';
  itemTesting.Name := 'testing';
  itemTesting.OnClick:= ActionMenuItemClick;
  itemMenu.Insert(0, itemTesting);

  itemCalibration := TMenuItem.Create(itemMenu);
  itemCalibration.Caption := '����������';
  itemCalibration.Name := 'calibration';
  itemCalibration.OnClick:= ActionMenuItemClick;
  itemMenu.Insert(1, itemCalibration);

  itemExit := TMenuItem.Create(itemMenu);
  itemExit.Caption := '�����';
  itemExit.Name := 'exit';
  itemExit.OnClick:= ActionMenuItemClick;
  itemMenu.Insert(2, itemExit);
end;


procedure TForm1.ActionMenuItemClick(Sender: TObject);
begin
  if TMenuItem(Sender).Name = 'testing' then begin
    CreateTestingForm(self);
  end;

  if TMenuItem(Sender).Name = 'calibration' then begin
    CreateCalibrationForm(self);
  end;

  if TMenuItem(Sender).Name = 'exit' then begin
    TrayPopUpCloseClick(Self);
  end;
end;




end.
