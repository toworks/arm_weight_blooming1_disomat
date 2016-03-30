unit testing;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   Dialogs, StdCtrls, StrUtils, DB, SyncObjs;

type
  TTestingForm = class(TForm)
  private
    b_ForceSendAttribute: TButton;
    procedure b_ForceSendAttributeClick(Sender: TObject);
  protected
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
  end;


var
    TestingForm: TTestingForm;
    MemoTesting: TMemo;
    function MemoTestingAdd(InData: AnsiString): bool;
    procedure CreateTestingForm(Sender: TObject);

implementation


uses
    settings, main;


constructor TTestingForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  inherited CreateNew(AOwner);

  MemoTesting := TMemo.Create(Self);
  MemoTesting.SetBounds(2, 2, 590, 300);
  MemoTesting.Parent := Self;

  b_ForceSendAttribute := TButton.Create(Self);
  b_ForceSendAttribute.SetBounds(2, 310, 130, 20);
  b_ForceSendAttribute.Caption := 'Послать признак';
  b_ForceSendAttribute.OnClick := @b_ForceSendAttributeClick;
  b_ForceSendAttribute.Parent := Self;
end;


procedure CreateTestingForm(Sender: TObject);
var
  i: integer;
begin
  TestingForm := TTestingForm.CreateNew(nil);
  try
    TestingForm.Height := 360;
    TestingForm.Width := 600;
    //запрет на изменение формы
    TestingForm.BorderStyle := bsToolWindow;
    TestingForm.BorderIcons := TestingForm.BorderIcons - [biMaximize];
    TestingForm.Caption := ' тестирование';
    TestingForm.Icon := Form1.Icon;
    TestingForm.Position := poMainFormCenter;
    TestingForm.ShowModal;
  finally
    FreeAndNil(MemoTesting);
    FreeAndNil(TestingForm);
  end;
end;


function MemoTestingAdd(InData: AnsiString): bool;
begin
  try
    if MemoTesting.Lines.Count = 0 then
      MemoTesting.Lines.add(timetostr(now)+#9+'testing'+#9+InData)
    else
      MemoTesting.Lines.Insert(0, timetostr(now)+#9+'testing'+#9+InData);

    MemoTesting.SelStart := 0;
    MemoTesting.SelLength := 0;

    if MemoTesting.Lines.Count-1 > 10 then
      MemoTesting.ScrollBars := ssVertical;

  except
    on E : Exception do
      Log.save('e', E.ClassName+', с сообщением: '+E.Message);
  end;
end;


procedure TTestingForm.b_ForceSendAttributeClick(Sender: TObject);
begin
//  ThreadComPort.SendAttribute;
end;




end.
