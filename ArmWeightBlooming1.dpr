program ArmWeightBlooming1;

uses
  Forms,
  main in 'main.pas' {Form1},
  sql in 'sql.pas',
  settings in 'settings.pas',
  logging in 'logging.pas',
  thread_comport in 'thread_comport.pas',
  thread_sql_read in 'thread_sql_read.pas',
  testing in 'testing.pas',
  thread_sql_send in 'thread_sql_send.pas',
  calibration in 'calibration.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
