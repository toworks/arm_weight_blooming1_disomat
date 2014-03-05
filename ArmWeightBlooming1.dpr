program ArmWeightBlooming1;

uses
  Forms,
  main in 'main.pas' {Form1},
  module in 'module.pas' {Module1: TDataModule},
  sql in 'sql.pas',
  settings in 'settings.pas',
  logging in 'logging.pas',
  thread_comport in 'thread_comport.pas',
  thread_sql in 'thread_sql.pas',
  testing in 'testing.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TModule1, Module1);
  Application.Run;
end.
