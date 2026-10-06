unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  bstypes, bsthemes, bsbutton, bscard, bsalert, bsprogress, bsspinner,
  bscheckbox, bsinput, bstoast, bsmodal, bsdropdown, bsnavtabs, bsnavbar,
  bsaccordion, bscollapse, bsoffcanvas;

type
  { TfrmMain }
  TfrmMain = class(TForm)
    TimerProgress: TTimer;

    // Layout
    ScrollBox1: TScrollBox;
    BsNavbar1: TBsNavbar;

    // Containers
    BsCard1: TBsCard;
    BsCard2: TBsCard;

    // Buttons
    BsButtonPrimary: TBsButton;
    BsButtonSecondary: TBsButton;
    BsButtonOutline: TBsButton;

    // Feedback
    BsAlert1: TBsAlert;
    BsAlert2: TBsAlert;
    BsToast1: TBsToast;
    BsModal1: TBsModal;
    BsOffcanvas1: TBsOffcanvas;

    // Indicators
    BsProgress1: TBsProgress;
    BsSpinner1: TBsSpinner;

    // Inputs
    BsInput1: TBsInput;
    BsCheckBox1: TBsCheckBox;
    BsSwitch1: TBsCheckBox;

    // Complex
    BsAccordion1: TBsAccordion;
    BsNavTabs1: TBsNavTabs;

    procedure FormCreate(Sender: TObject);
    procedure BsButtonPrimaryClick(Sender: TObject);
    procedure BsButtonSecondaryClick(Sender: TObject);
    procedure BsButtonOutlineClick(Sender: TObject);
    procedure TimerProgressTick(Sender: TObject);
    procedure BsAlert1Close(Sender: TObject);
    procedure BsNavbar1BrandClick(Sender: TObject);
    procedure BsModal1ModalResult(Sender: TObject; AResult: TBsModalResult);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  AccItem: TBsAccordionItem;
begin
  Caption := 'Bootstrap 5 LCL Components Demo';
  Color := $F8F9FA; // Background warna btcLight

  // Setup Accordion Demo
  if Assigned(BsAccordion1) then
  begin
    AccItem := BsAccordion1.AddItem('Accordion Item #1');
    AccItem := BsAccordion1.AddItem('Accordion Item #2');
    AccItem := BsAccordion1.AddItem('Accordion Item #3');
  end;

  // Init Progress Bar animasi
  if Assigned(BsProgress1) then
  begin
    BsProgress1.Value := 0;
    BsProgress1.Animated := True;
    BsProgress1.Striped := True;
  end;

  // Aktifkan timer progress bar
  if Assigned(TimerProgress) then
    TimerProgress.Enabled := True;
end;

procedure TfrmMain.BsButtonPrimaryClick(Sender: TObject);
begin
  if Assigned(BsToast1) then
  begin
    BsToast1.ThemeColor := btcPrimary;
    BsToast1.Title := 'Notification';
    BsToast1.Subtitle := 'Just now';
    BsToast1.MessageText := 'Primary button clicked! Hello from Bootstrap Toast.';
    BsToast1.ShowToast;
  end;
end;

procedure TfrmMain.BsButtonSecondaryClick(Sender: TObject);
begin
  if Assigned(BsModal1) then
  begin
    BsModal1.ThemeColor := btcInfo;
    BsModal1.Title := 'Confirm Action';
    BsModal1.TextBody := 'Are you sure you want to proceed with this demo action?';
    BsModal1.ShowModal;
  end;
end;

procedure TfrmMain.BsButtonOutlineClick(Sender: TObject);
begin
  if Assigned(BsOffcanvas1) then
  begin
    BsOffcanvas1.Placement := bsoRight;
    BsOffcanvas1.ThemeColor := btcLight;
    BsOffcanvas1.Title := 'Settings';
    BsOffcanvas1.BodyText := 'Adjust your preferences and sidebar content here.';
    BsOffcanvas1.ShowOffcanvas;
  end;
end;

procedure TfrmMain.TimerProgressTick(Sender: TObject);
begin
  if Assigned(BsProgress1) then
  begin
    BsProgress1.Value := BsProgress1.Value + 1;
    if BsProgress1.Value >= BsProgress1.Max then
      BsProgress1.Value := BsProgress1.Min;
  end;
end;

procedure TfrmMain.BsAlert1Close(Sender: TObject);
begin
  if Assigned(BsToast1) then
  begin
    BsToast1.ThemeColor := btcWarning;
    BsToast1.Title := 'Alert Closed';
    BsToast1.MessageText := 'You have dismissed the alert box.';
    BsToast1.ShowToast;
  end;
end;

procedure TfrmMain.BsNavbar1BrandClick(Sender: TObject);
begin
  if Assigned(BsToast1) then
  begin
    BsToast1.ThemeColor := btcDark;
    BsToast1.Title := 'Brand Clicked';
    BsToast1.MessageText := 'Navbar brand area was clicked.';
    BsToast1.ShowToast;
  end;
end;

procedure TfrmMain.BsModal1ModalResult(Sender: TObject; AResult: TBsModalResult);
begin
  if AResult = bmrOk then
  begin
    if Assigned(BsToast1) then
    begin
      BsToast1.ThemeColor := btcSuccess;
      BsToast1.Title := 'Success';
      BsToast1.MessageText := 'Action confirmed and executed from Modal!';
      BsToast1.ShowToast;
    end;
  end;
end;

end.

