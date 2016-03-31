unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, DBGrids,
  ExtCtrls, StdCtrls, Menus, db, {$ifdef windows} Windows, {$endif}
  logging, sql, thread_sql_read{, thread_sql_send, thread_comport},
  Grids;

type

  { TForm1 }

  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    gb_data_pu1: TGroupBox;
    gb_data_pu2: TGroupBox;
    gb_weighed_ingot_in_sql: TGroupBox;
    l_datetime: TLabel;
    l_weight_ingot: TLabel;
    l_heat: TLabel;
    l_grade: TLabel;
    l_n_weight_ingot: TLabel;
    l_n_heat: TLabel;
    l_n_grade: TLabel;
    l_n_number_ingot: TLabel;
    l_number_ingot: TLabel;
    l_n_datetime: TLabel;
    procedure DBGrid1DblClick(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DBGrid1PrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    function CreateMenu: boolean;
    procedure ActionMenuItemClick(Sender: TObject);
  private
    procedure DBgrid1Create(Sender: TObject);
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  ThreadSqlRead: TThreadSqlRead;
//  ThreadSqlSend: TThreadSqlSend;
//  ThreadComPort: TThreadComPort;
  MainSqlite: TSqlite;
  SDataSource: TDataSource;
  MainFSql: TFsql;
  FDataSource: TDataSource;

//    {$DEFINE DEBUG}

  function ViewSelectedIngot: boolean;
  function PointReplace(DataIn: string): string;
  function ViewClear: boolean;


implementation

uses
  settings, testing, calibration;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  try
      Log.save('i', 'close '+Log.ProgFileName);

{      if assigned(ThreadComPort) then
        ThreadComPort.Terminate;
      if assigned(ThreadSqlRead) then
        ThreadSqlRead.Terminate;
      if assigned(ThreadSqlSend) then
        ThreadSqlSend.Terminate;

      if assigned(MainSqlite) then
        MainSqlite.Destroy;
      if assigned(SDataSource) then
        SDataSource.Destroy;
      if assigned(MainFSql) then
        MainFSql.Destroy;
      if assigned(FDataSource) then
        FDataSource.Destroy;}
  finally
    // закрываем приложение
    {$ifdef unix}
      FpKill(FpGetpid, 9);
    {$endif}
    {$ifdef windows}
      TerminateProcess(GetCurrentProcess, 0);
    {$endif}
  end;
end;



procedure TForm1.DBGrid1DblClick(Sender: TObject);
begin
  // маркер следующей заготовки
  if not MarkerNextWait then begin
    try
        //отключаем управление
        form1.DBGrid1.DataSource.DataSet.DisableControls;
        if MessageDlg('Выбрать заготовку для взвешивания?', mtCustom, mbYesNo, 0) = mrYes then
          ViewSelectedIngot;
    finally
        //включаем управление
        form1.DBGrid1.DataSource.DataSet.EnableControls;
    end;
  end;
end;


procedure TForm1.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  R: TRect;
begin
  if  gdSelected in State then //color selected
  begin
    with DBGrid1.Canvas do
    begin
      (Sender as TDBGrid).Canvas.Brush.Color:= $002CB902;//green
      	    (Sender as TDBGrid).Canvas.Font.Color := clHighLightText;
    end;
  end;
  DBGrid1.Canvas.FillRect(Rect);
  Dbgrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;


procedure TForm1.DBGrid1PrepareCanvas(sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
var
   i: integer;
   TitleWidth: integer;
   TextWidth: integer;
begin
    with (Sender As TDBGrid) do begin
      for i:=0 to Columns.Count-1 do begin
          TitleWidth := Canvas.TextWidth(Columns.Items[i].Title.Caption);
          TextWidth := Canvas.TextWidth(Columns.Items[i].Field.ToString);
//          if (TextWidth < Columns.Items[i].Width) then begin
             Columns.Items[i].Width := TitleWidth+25;
             Columns.Items[i].Alignment := taCenter;//taLeftJustify;
             Columns.Items[i].Title.Alignment := taCenter;//taLeftJustify;
//          end;
      end;
    end;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Log.save('i', 'start '+Log.ProgFileName);

  MainSqlite := TSqlite.Create(Log);
  //отображение в dbgrid
  SDataSource := TDataSource.Create(nil);
  SDataSource.DataSet := MainSqlite.SQuery;
  DBGrid2.DataSource := SDataSource;

  MainFSql := TFsql.Create(Log);
  //отображение в dbgrid
  FDataSource := TDataSource.Create(nil);
  DBgrid1Create(self);
  FDataSource.DataSet := MainFSql.FQuery;
  DBGrid1.DataSource := FDataSource;

  ThreadSqlRead := TThreadSqlRead.Create(Log);
//  ThreadSqlSend := TThreadSqlSend.Create(Log);
//  ThreadComPort := TThreadComPort.Create(Log);

  Form1.Caption := SettingsApp.HeadName+'  build('+SettingsApp.GetVersion+')';
  //заголовки к showmessage
  Application.Title := Form1.Caption;

  //запрет на изменение формы
  BorderStyle := bsToolWindow;
  BorderIcons := BorderIcons - [biMaximize];

  ViewClear;

  CreateMenu;
end;


function TForm1.CreateMenu: boolean;
var
    MainMenu: TMainMenu;
    itemMenu, itemTesting, itemCalibration, itemExit: TMenuItem;
begin
  MainMenu := TMainMenu.Create(form1);
  itemMenu := TMenuItem.Create(MainMenu);

  itemMenu.Caption := 'Меню';
  itemMenu.Name:='main';
  MainMenu.Items.Add(itemMenu);

  itemTesting := TMenuItem.Create(itemMenu);
  itemTesting.Caption := 'Тестирование';
  itemTesting.Name := 'testing';
  itemTesting.OnClick:= @ActionMenuItemClick;
  itemMenu.Insert(0, itemTesting);

  itemCalibration := TMenuItem.Create(itemMenu);
  itemCalibration.Caption := 'Калибровка';
  itemCalibration.Name := 'calibration';
  itemCalibration.OnClick:= @ActionMenuItemClick;
  itemMenu.Insert(1, itemCalibration);

  itemExit := TMenuItem.Create(itemMenu);
  itemExit.Caption := 'Выход';
  itemExit.Name := 'exit';
  itemExit.OnClick:= @ActionMenuItemClick;
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
     Form1.Close;
  end;
end;


procedure TForm1.DBgrid1Create(Sender: TObject);
var
   i: integer;
begin
  DBGrid1.Columns.Clear;
  DBGrid1.Columns.Add.FieldName := 'smena';
  DBGrid1.Columns.Add.FieldName := 'num_ingot';
  DBGrid1.Columns.Add.FieldName := 'time_ingot';
  DBGrid1.Columns.Add.FieldName := 'num_heat';
  DBGrid1.Columns.Add.FieldName := 'name';
  DBGrid1.Columns.Add.FieldName := 'weight_ingot';
  DBGrid1.Columns.Add.FieldName := 'steel_group';

  DBGrid1.Columns.Items[0].Title.Caption := 'Смена';
  DBGrid1.Columns.Items[1].Title.Caption := '№ Слитка';
  DBGrid1.Columns.Items[2].Title.Caption := 'Время';
  DBGrid1.Columns.Items[3].Title.Caption := '№ Плавки';
  DBGrid1.Columns.Items[4].Title.Caption := 'Марка стали';
  DBGrid1.Columns.Items[5].Title.Caption := 'Масса слитка ПУ-1 (т)';
  DBGrid1.Columns.Items[6].Title.Caption := 'steel_group';

  DBGrid1.Columns.Items[6].Visible := false;
end;


function ViewSelectedIngot: boolean;
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


function ViewClear: boolean;
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




end.

