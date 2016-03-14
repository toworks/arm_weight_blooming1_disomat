unit Logging;

interface

uses
  SysUtils, Variants, Classes, SyncObjs;


type
  TLog = class

  private
    cs: TCriticalSection;
    destructor Destroy; override;
  public
    ProgFileName: AnsiString;
    constructor Create; overload;
    procedure save(_type, _message: AnsiString);
  end;


implementation


constructor TLog.Create;
begin
  inherited Create;
  cs := TCriticalSection.Create;
  //��� �����
  ProgFileName := ExtractFileName(ChangeFileExt(ParamStr(0), ''));
end;


destructor TLog.Destroy;
begin
  inherited Destroy;
  cs := TCriticalSection.Create;
end;


procedure TLog.save(_type, _message: AnsiString);
var
   f: TextFile;
   log_file: AnsiString;
   level: AnsiString;
begin
{
Type    Level    Description
'a'     ALL      All levels including custom levels.
'd'     DEBUG    Designates fine-grained informational events that are most useful to debug an application.
'e'     ERROR    Designates error events that might still allow the application to continue running.
'f'     FATAL    Designates very severe error events that will presumably lead the application to abort.
'i'     INFO     Designates informational messages that highlight the progress of the application at coarse-grained level.
'o'     OFF      The highest possible rank and is intended to turn off logging.
't'     TRACE    Designates finer-grained informational events than the DEBUG.
'w'     WARN     Designates potentially harmful situations.
}
  cs.Enter;

  _type := trim(AnsiLowerCase(_type));

  if ( _type = 'a' ) then
        level := 'ALL'
  else if ( _type = 'd' ) then
        level := 'DEBUG'
  else if (_type = 'e' ) then
        level := 'ERROR'
  else if ( _type = 'f' ) then
        level := 'FATAL'
  else if ( _type = 'i' ) then
        level := 'INFO'
  else if ( _type = 'o' ) then
        level := 'OFF'
  else if ( _type = 't' ) then
        level := 'TRACE'
  else if ( _type = 'w' ) then
        level := 'WARN'
  else
        level := 'INFO';

  try
      log_file := FormatDateTime('yyyymmdd', NOW);
      AssignFile(f, log_file+'_'+ProgFileName+'.log');
      if not FileExists(log_file+'_'+ProgFileName+'.log') then
       begin
          Rewrite(f);
          CloseFile(f);
       end;

      Append(f);

      Writeln(f, FormatDateTime('yyyy-mm-dd hh:mm:ss.zzz', NOW)+#9+level+#9+_message);

      Flush(f);
      CloseFile(f);
  except
    on E : Exception do
      save('e', E.ClassName+', � ����������: '+E.Message);
  end;

  cs.Leave;
end;


// ��� �������� ��������� ����� ����� �����������
initialization
//Log := TLog.Create;


//��� �������� ��������� ������������
finalization
//Log.Destroy;

end.
