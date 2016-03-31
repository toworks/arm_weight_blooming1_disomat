unit calibration;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   Dialogs, StdCtrls, StrUtils;

type
  TCalibrationForm = class(TForm)

  private

  public
    l_calibration: TLabel;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
  end;


var
    CalibrationForm: TCalibrationForm;
    procedure CreateCalibrationForm(Sender: TObject);

implementation


uses
    main, settings, logging, thread_comport;


constructor TCalibrationForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  inherited CreateNew(AOwner);
     try
         l_calibration := TLabel.Create(Self);
      with l_calibration do begin
         Caption := '0';
         Parent := Self;
         Align := alTop;
         Alignment := taCenter;
         Left := 0;
         Top := 0;
         font.size := 62;
         font.Style := [fsBold];
         Font.Name := 'Tahoma';
         font.Color := $00FE9901; // blue lite
         Width := 580;
         Height := 340;
      end;
   except
     on E: Exception do
       Log.save('e', E.ClassName + ', с сообщением: ' + E.Message);
   end;
end;


procedure CreateCalibrationForm(Sender: TObject);
var
  i: integer;
begin
//  CalibrationForm := TCalibrationForm.CreateNew(nil);
  CalibrationForm := TCalibrationForm.CreateNew(nil);
  try
    CalibrationForm.Height := 360;
    CalibrationForm.Width := 600;
    //запрет на изменение формы
    CalibrationForm.BorderStyle := bsToolWindow;
    CalibrationForm.BorderIcons := CalibrationForm.BorderIcons - [biMaximize];
    CalibrationForm.Caption := ' калибровка';
    CalibrationForm.Icon := Form1.Icon;
    CalibrationForm.Position := poMainFormCenter;
    CalibrationForm.ShowModal;
  finally
    FreeAndNil(CalibrationForm);
  end;
end;





end.
