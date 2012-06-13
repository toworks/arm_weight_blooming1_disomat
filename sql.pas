unit sql;

interface

uses
  SysUtils, Classes, WideStrings, DBXMsSQL, DB, SqlExpr, DBTables, ADODB,
  IBCustomDataSet, IBQuery, IBDatabase, IBSQL, Vcl.ExtCtrls, Windows, Messages,
  Graphics,Dialogs;

type
  TDataModule2 = class(TDataModule)
    ADOConnection1: TADOConnection;
    ADOQuery1: TADOQuery;
    DataSource1: TDataSource;
    query_count: TADOQuery;
    ib_datasource: TDataSource;
    ib_timer: TTimer;
    ib_connection: TADOConnection;
    ib_query: TADOQuery;
    ib_query_count: TADOQuery;
    ib_query_view: TADOQuery;
    query_reports: TADOQuery;
    query_s_g_c: TADOQuery;
    procedure ib_timerTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule2: TDataModule2;
  i: integer;



implementation
    uses main, db_weight;


{$R *.dfm}

{-------------------------------}

procedure TDataModule2.ib_timerTimer(Sender: TObject);
begin

      //����� ������
      NewRecDbWeight;

end;


{-------------------------------}



end.
