unit bsinput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, Controls, Graphics, StdCtrls, LMessages, LCLType,
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
    FUpdatingBounds: Boolean;

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
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Loaded; override;
    procedure SetParent(AParent: TWinControl); override;
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

  ControlStyle := ControlStyle - [csOpaque] + [csCaptureMouse];
  DoubleBuffered := True;

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
  FUpdatingBounds := False;

  Font.Name := 'Segoe UI';
  Font.Size := 10;
  Font.Color := clWindowText;

  // Inisialisasi TEdit internal
  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.SetSubComponent(True);
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

procedure TBsInput.Loaded;
begin
  inherited Loaded;
  UpdateEditBounds;
end;

procedure TBsInput.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if Assigned(FEdit) and (FEdit.Parent <> Self) then
    FEdit.Parent := Self;
  UpdateEditBounds;
end;

procedure TBsInput.UpdateEditBounds;
var
  PadX, EditH, NewTop, NewWidth: Integer;
begin
  if FUpdatingBounds or not Assigned(FEdit) or (csLoading in ComponentState) or (csDestroying in ComponentState) then Exit;

  FUpdatingBounds := True;
  try
    case FInputSize of
      bisSmall: PadX := 8;
      bisLarge: PadX := 16;
    else
      PadX := 12;
    end;

    FEdit.Font.Assign(Font);

    // Gunakan tinggi alami TEdit agar tidak berbenturan dengan nilai internal LCL
    EditH := FEdit.Height;
    if EditH < 16 then EditH := 16;

    NewTop := (Height - EditH) div 2;
    NewWidth := Max(10, Width - (PadX * 2));

    // Eksekusi SetBounds hanya jika terdapat perubahan nilai
    if (FEdit.Left <> PadX) or (FEdit.Top <> NewTop) or
       (FEdit.Width <> NewWidth) or (FEdit.Height <> EditH) then
    begin
      FEdit.SetBounds(PadX, NewTop, NewWidth, EditH);
    end;

    FEdit.ReadOnly := FReadOnly;
    FEdit.Enabled := Enabled;
    FEdit.Color := clWindow;
  finally
    FUpdatingBounds := False;
  end;
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

  case FInputSize of
    bisSmall: Height := 31;
    bisLarge: Height := 48;
  else
    Height := 38;
  end;

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
  FillColor, BdColor, FocusColor, PhColor: TBGRAPixel;
  Radius, PadX, EditH: Integer;
  PhRect: TRect;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height);
  try
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    // 1. Penentuan Warna Isian & Border
    if not Enabled then
    begin
      FillColor := BGRA(233, 236, 239, 255);
      BdColor := TBsTheme.GetDisabledColor;
    end
    else if FReadOnly then
    begin
      FillColor := BGRA(248, 249, 250, 255);
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

      PhColor := BGRA(108, 117, 125, 180);
      TBsGraphics.DrawText(Bmp, PhRect, FPlaceholder, Font, PhColor, bsaStart, 0);
    end;

    Bmp.Draw(Canvas, 0, 0, True);
  finally
    Bmp.Free;
  end;
end;

end.
