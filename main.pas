unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, DBGrids,
  ExtCtrls, StdCtrls, Menus, db, sql;

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
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    function CreateMenu: boolean;
    procedure ActionMenuItemClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  MainSqlite: TSqlite;
  SLDataSource: TDataSource;
  MainFSql: TFsql;
  FDataSource: TDataSource;


implementation

uses
  {settings,} testing, calibration;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := False;
  Form1.Hide;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  MainSqlite := TSqlite.Create(Log);
  //отображение в dbgrid
  SLDataSource := TDataSource.Create(nil);
  SLDataSource.DataSet := MainSqlite.SQuery;
  DBGrid2.DataSource := SLDataSource;

  MainFSql := TFsql.Create(Log);
  //отображение в dbgrid
  FDataSource := TDataSource.Create(nil);
  FDataSource.DataSet := MainFSql.FQuery;
  DBGrid1.DataSource := FDataSource;

  //запрет на изменение формы
  BorderStyle := bsToolWindow;
  BorderIcons := BorderIcons - [biMaximize];

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
//    CreateCalibrationForm(self);
  end;

  if TMenuItem(Sender).Name = 'exit' then begin
//    TrayPopUpCloseClick(Self);
  end;
end;




end.

