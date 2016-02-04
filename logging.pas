unit Logging;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, OoMisc;


type
  TLog = class
  private
  public
    ProgFileName: AnsiString;
    function save(_type, _message: AnsiString): boolean;
    constructor Create; overload;
    destructor Destroy; override;
  end;


var
  Log: TLog;


implementation



constructor TLog.Create;
begin
  inherited Create;
  //имя файла
  ProgFileName := ExtractFileName(ChangeFileExt(ParamStr(0), ''));
end;


destructor TLog.Destroy;
begin
  inherited Destroy;
end;


function TLog.save(_type, _message: AnsiString): boolean;
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
      save('e', E.ClassName+', с сообщением: '+E.Message);
  end;
end;


// При загрузке программы класс будет создаваться
initialization
Log := TLog.Create;

//При закрытии программы уничтожаться
finalization
Log.Destroy;

end.
