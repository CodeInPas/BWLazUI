unit bsinput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, StdCtrls, LMessages, LCLType,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsInput: Komponen teks input bergaya Bootstrap 5 (Composite Control) }
  TBsInput = class(TCustomControl)
  private
    FEdit: TEdit;
    FState: TBsControlState;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FIsFocused: Boolean;

    FOnChange: TNotifyEvent;
    FOnKeyDown: TKeyEvent;
    FOnKeyPress: TKeyPressEvent;
    FOnKeyUp: TKeyEvent;

    function GetText: string;
    procedure SetText(const AValue: string);
    function GetPlaceholder: string;
    procedure SetPlaceholder(const AValue: string);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    function GetPasswordChar: char;
    procedure SetPasswordChar(AValue: char);
    function GetReadOnly: Boolean;
    procedure SetReadOnly(AValue: Boolean);
    function GetMaxLength: Integer;
    procedure SetMaxLength(AValue: Integer);

    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure EditMouseEnter(Sender: TObject);
    procedure EditMouseLeave(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditKeyPress(Sender: TObject; var Key: char);
    procedure EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure CMMouseEnter(var Message: TLMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TLMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
    procedure CMColorChanged(var Message: TLMessage); message CM_COLORCHANGED;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure DoEnter; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Text: string read GetText write SetText;
    property PlaceholderText: string read GetPlaceholder write SetPlaceholder;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property PasswordChar: char read GetPasswordChar write SetPasswordChar default #0;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property MaxLength: Integer read GetMaxLength write SetMaxLength default 0;

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Events }
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: TKeyEvent read FOnKeyUp write FOnKeyUp;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsInput]);
end;

{ TBsInput }

constructor TBsInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];

  Width := 200;
  Height := 38;
  Color := clWindow;

  FState := bcsNormal;
  FIsFocused := False;
  FThemeColor := btcPrimary;
  FCornerType := bctSmall;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  // Buat inner TEdit
  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.BorderStyle := bsNone;
  FEdit.Color := Color;
  FEdit.Font := Font;
  FEdit.TabOrder := 0;

  // Hubungkan events internal
  FEdit.OnEnter := @EditEnter;
  FEdit.OnExit := @EditExit;
  FEdit.OnChange := @EditChange;
  FEdit.OnMouseEnter := @EditMouseEnter;
  FEdit.OnMouseLeave := @EditMouseLeave;
  FEdit.OnKeyDown := @EditKeyDown;
  FEdit.OnKeyPress := @EditKeyPress;
  FEdit.OnKeyUp := @EditKeyUp;
end;

{ Getter & Setter }

function TBsInput.GetText: string;
begin
  Result := FEdit.Text;
end;

procedure TBsInput.SetText(const AValue: string);
begin
  FEdit.Text := AValue;
end;

function TBsInput.GetPlaceholder: string;
begin
  Result := FEdit.TextHint;
end;

procedure TBsInput.SetPlaceholder(const AValue: string);
begin
  FEdit.TextHint := AValue;
end;

procedure TBsInput.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  if FIsFocused then Invalidate;
end;

procedure TBsInput.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

function TBsInput.GetPasswordChar: char;
begin
  Result := FEdit.PasswordChar;
end;

procedure TBsInput.SetPasswordChar(AValue: char);
begin
  FEdit.PasswordChar := AValue;
end;

function TBsInput.GetReadOnly: Boolean;
begin
  Result := FEdit.ReadOnly;
end;

procedure TBsInput.SetReadOnly(AValue: Boolean);
begin
  FEdit.ReadOnly := AValue;
  if FEdit.ReadOnly then
    FEdit.Color := ColorToRGB(clBtnFace)
  else
    FEdit.Color := Color;
  Invalidate;
end;

function TBsInput.GetMaxLength: Integer;
begin
  Result := FEdit.MaxLength;
end;

procedure TBsInput.SetMaxLength(AValue: Integer);
begin
  FEdit.MaxLength := AValue;
end;

{ Penanganan Event & State }

procedure TBsInput.EditEnter(Sender: TObject);
begin
  FIsFocused := True;
  FState := bcsFocused;
  Invalidate;
  if Assigned(OnEnter) then OnEnter(Self);
end;

procedure TBsInput.EditExit(Sender: TObject);
begin
  FIsFocused := False;
  FState := bcsNormal;
  Invalidate;
  if Assigned(OnExit) then OnExit(Self);
end;

procedure TBsInput.EditChange(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TBsInput.EditMouseEnter(Sender: TObject);
begin
  if not Enabled then Exit;
  if not FIsFocused then
  begin
    FState := bcsHover;
    Invalidate;
  end;
end;

procedure TBsInput.EditMouseLeave(Sender: TObject);
begin
  if not Enabled then Exit;
  if not FIsFocused then
  begin
    FState := bcsNormal;
    Invalidate;
  end;
end;

procedure TBsInput.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Assigned(FOnKeyDown) then FOnKeyDown(Self, Key, Shift);
end;

procedure TBsInput.EditKeyPress(Sender: TObject; var Key: char);
begin
  if Assigned(FOnKeyPress) then FOnKeyPress(Self, Key);
end;

procedure TBsInput.EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Assigned(FOnKeyUp) then FOnKeyUp(Self, Key, Shift);
end;

procedure TBsInput.CMMouseEnter(var Message: TLMessage);
begin
  inherited;
  EditMouseEnter(Self);
end;

procedure TBsInput.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  EditMouseLeave(Self);
end;

procedure TBsInput.CMEnabledChanged(var Message: TLMessage);
begin
  inherited;
  FEdit.Enabled := Enabled;
  if not Enabled then
  begin
    FState := bcsDisabled;
    FIsFocused := False;
    FEdit.Color := ColorToRGB(clBtnFace);
  end
  else
  begin
    FState := bcsNormal;
    if ReadOnly then FEdit.Color := ColorToRGB(clBtnFace) else FEdit.Color := Color;
  end;
  Invalidate;
end;

procedure TBsInput.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  FEdit.Font := Font;
  Resize;
end;

procedure TBsInput.CMColorChanged(var Message: TLMessage);
begin
  inherited;
  if (not ReadOnly) and Enabled then
    FEdit.Color := Color;
  Invalidate;
end;

procedure TBsInput.DoEnter;
begin
  inherited DoEnter;
  FEdit.SetFocus;
end;

procedure TBsInput.Resize;
begin
  inherited Resize;
  if Assigned(FEdit) then
  begin
    // Posisi TEdit di tengah secara vertikal dan diberi padding horizontal 12px
    FEdit.Left := 12;
    FEdit.Width := Width - 24;
    FEdit.Top := (Height - FEdit.Height) div 2;
  end;
end;

procedure TBsInput.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, FillColor, BdColor, FocusColor: TBGRAPixel;
  Radius: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    // Kalkulasi Warna
    if not Enabled then
    begin
      FillColor := TBsTheme.GetDisabledColor;
      BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline); // #ced4da
    end
    else
    begin
      FillColor := ColorToBGRA(ColorToRGB(Color));
      if ReadOnly then FillColor := TBsTheme.GetDisabledColor;

      if FState = bcsFocused then
        BdColor := TBsTheme.GetBaseColor(FThemeColor)
      else
        BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
    end;

    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    // Render Focus Ring
    if FState = bcsFocused then
    begin
      FocusColor := TBsTheme.GetFocusRingColor(FThemeColor);
      TBsGraphics.DrawFocusRing(Bmp, ClientRect, Radius, FocusColor, 3);
    end;

    // Render Background dan Border Input
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.

