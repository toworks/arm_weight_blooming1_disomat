program ArmWeightBlooming1;

uses
  Forms,
  main in 'main.pas' {Form1},
  sql in 'sql.pas' {DataModule2: TDataModule},
  reports in 'reports.pas',
  db_weight in 'db_weight.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDataModule2, DataModule2);
  Application.Run;
end.
