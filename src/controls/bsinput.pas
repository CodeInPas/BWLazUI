unit bsinput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, Graphics, StdCtrls, LMessages, LCLType,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsInputSize = (bisSmall, bisMedium, bisLarge);

  { TBsInput: Komponen Input Teks bergaya Bootstrap 5 }
  TBsInput = class(TCustomControl)
  private
    FEdit: TEdit;
    FThemeColor: TBsThemeColor;
    FInputSize: TBsInputSize;
    FCornerType: TBsCornerType;
    FPlaceholder: string;
    FText: string;
    FState: TBsControlState;
    FIsHovered: Boolean;
    FIsFocused: Boolean;
    FReadOnly: Boolean;
    FOnChange: TNotifyEvent;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetInputSize(AValue: TBsInputSize);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetPlaceholder(const AValue: string);
    procedure SetTextValue(const AValue: string);
    procedure SetReadOnlyValue(AValue: Boolean);

    procedure OnInternalEditChange(Sender: TObject);
    procedure OnInternalEditEnter(Sender: TObject);
    procedure OnInternalEditExit(Sender: TObject);
    procedure OnInternalEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure UpdateEditBounds;

    { LCL Messages }
    procedure CMMouseEnter(var Message: TLMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TLMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Text: string read FText write SetTextValue;
    property Placeholder: string read FPlaceholder write SetPlaceholder;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property InputSize: TBsInputSize read FInputSize write SetInputSize default bisMedium;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property ReadOnly: Boolean read FReadOnly write SetReadOnlyValue default False;

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
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

  // Inisialisasi Dimensi Awal
  Width := 200;
  Height := 38;
  TabStop := True;

  FThemeColor := btcPrimary;
  FInputSize := bisMedium;
  FCornerType := bctSmall;
  FState := bcsNormal;
  FIsHovered := False;
  FIsFocused := False;
  FReadOnly := False;
  FPlaceholder := 'Enter text...';
  FText := '';

  Font.Name := 'Segoe UI';
  Font.Size := 10;
  Font.Color := clWindowText;

  // Inisialisasi TEdit internal
  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.BorderStyle := bsNone;
  FEdit.AutoSelect := False;
  FEdit.OnChange := @OnInternalEditChange;
  FEdit.OnEnter := @OnInternalEditEnter;
  FEdit.OnExit := @OnInternalEditExit;
  FEdit.OnKeyDown := @OnInternalEditKeyDown;

  UpdateEditBounds;
end;

destructor TBsInput.Destroy;
begin
  inherited Destroy;
end;

procedure TBsInput.UpdateEditBounds;
var
  PadX, EditH: Integer;
begin
  // Guard Clause: Mencegah Access Violation jika FEdit belum ter-instansiasi
  if not Assigned(FEdit) then Exit;

  case FInputSize of
    bisSmall:
      begin
        PadX := 8;
        Height := 31;
      end;
    bisLarge:
      begin
        PadX := 16;
        Height := 48;
      end;
  else
    // bisMedium
    PadX := 12;
    Height := 38;
  end;

  Canvas.Font.Assign(Font);
  EditH := Canvas.TextHeight('Gy') + 2;
  if EditH < 16 then EditH := 16;

  FEdit.SetBounds(PadX, (Height - EditH) div 2, Width - (PadX * 2), EditH);
  FEdit.Font.Assign(Font);
  FEdit.ReadOnly := FReadOnly;
  FEdit.Enabled := Enabled;
  FEdit.Color := clWindow;
end;

procedure TBsInput.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsInput.SetInputSize(AValue: TBsInputSize);
begin
  if FInputSize = AValue then Exit;
  FInputSize := AValue;
  UpdateEditBounds;
  Invalidate;
end;

procedure TBsInput.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsInput.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder = AValue then Exit;
  FPlaceholder := AValue;
  Invalidate;
end;

procedure TBsInput.SetTextValue(const AValue: string);
begin
  if FText = AValue then Exit;
  FText := AValue;
  if Assigned(FEdit) and (FEdit.Text <> FText) then
    FEdit.Text := FText;
  Invalidate;
end;

procedure TBsInput.SetReadOnlyValue(AValue: Boolean);
begin
  if FReadOnly = AValue then Exit;
  FReadOnly := AValue;
  if Assigned(FEdit) then
    FEdit.ReadOnly := FReadOnly;
  Invalidate;
end;

procedure TBsInput.OnInternalEditChange(Sender: TObject);
begin
  if Assigned(FEdit) then
    FText := FEdit.Text;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TBsInput.OnInternalEditEnter(Sender: TObject);
begin
  FIsFocused := True;
  FState := bcsFocused;
  Invalidate;
  DoEnter;
end;

procedure TBsInput.OnInternalEditExit(Sender: TObject);
begin
  FIsFocused := False;
  FState := bcsNormal;
  Invalidate;
  DoExit;
end;

procedure TBsInput.OnInternalEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  KeyDown(Key, Shift);
end;

procedure TBsInput.CMMouseEnter(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  FIsHovered := True;
  if not FIsFocused then FState := bcsHover;
  Invalidate;
end;

procedure TBsInput.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  FIsHovered := False;
  if not FIsFocused then FState := bcsNormal;
  Invalidate;
end;

procedure TBsInput.CMEnabledChanged(var Message: TLMessage);
begin
  inherited;
  if Assigned(FEdit) then
    FEdit.Enabled := Enabled;
  if not Enabled then
    FState := bcsDisabled
  else if FIsFocused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsInput.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  UpdateEditBounds;
  Invalidate;
end;

procedure TBsInput.WMSize(var Message: TLMSize);
begin
  inherited;
  UpdateEditBounds;
  Invalidate;
end;

procedure TBsInput.Resize;
begin
  inherited Resize;
  UpdateEditBounds;
end;

procedure TBsInput.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Enabled and Assigned(FEdit) and CanFocus then
    FEdit.SetFocus;
end;

procedure TBsInput.DoEnter;
begin
  inherited DoEnter;
  if Enabled and Assigned(FEdit) and not FEdit.Focused then
    FEdit.SetFocus;
end;

procedure TBsInput.DoExit;
begin
  inherited DoExit;
end;

procedure TBsInput.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, FillColor, BdColor, FocusColor, PhColor: TBGRAPixel;
  Radius, PadX, EditH: Integer;
  PhRect: TRect;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    // 1. Penentuan Warna Isian & Border
    if not Enabled then
    begin
      FillColor := BGRA(233, 236, 239, 255); // #e9ecef (Bootstrap disabled bg)
      BdColor := TBsTheme.GetDisabledColor;
    end
    else if FReadOnly then
    begin
      FillColor := BGRA(248, 249, 250, 255); // #f8f9fa
      BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
    end
    else
    begin
      FillColor := ColorToBGRA(ColorToRGB(clWindow));
      BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
      if FIsHovered and not FIsFocused then
        BdColor := TBsTheme.GetBaseColor(btcSecondary);
    end;

    // 2. Gambar Focus Ring
    if Enabled and FIsFocused then
    begin
      FocusColor := TBsTheme.GetFocusRingColor(FThemeColor);
      BdColor := TBsTheme.GetBaseColor(FThemeColor);
      TBsGraphics.DrawFocusRing(Bmp, ClientRect, Radius, FocusColor, 3);
    end;

    // 3. Gambar Latar Belakang & Border Input
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);

    // 4. Render Placeholder jika Teks Kosong
    if (FText = '') and (FPlaceholder <> '') and Assigned(FEdit) then
    begin
      case FInputSize of
        bisSmall: PadX := 8;
        bisLarge: PadX := 16;
      else
        PadX := 12;
      end;

      Canvas.Font.Assign(Font);
      EditH := Canvas.TextHeight('Gy') + 2;
      PhRect := Rect(PadX + 2, (Height - EditH) div 2, Width - PadX, (Height + EditH) div 2);

      PhColor := BGRA(108, 117, 125, 180); // #6c757d (Muted gray)
      TBsGraphics.DrawText(Bmp, PhRect, FPlaceholder, Font, PhColor, bsaStart, 0);
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
