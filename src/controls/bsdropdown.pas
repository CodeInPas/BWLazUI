unit bsdropdown;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Menus, Types, Forms,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsDropdown: Tombol pemicu menu dropdown bergaya Bootstrap 5 }
  TBsDropdown = class(TCustomControl)
  private
    FState: TBsControlState;
    FThemeColor: TBsThemeColor;
    FStyle: TBsStyle;
    FSize: TBsSize;
    FCornerType: TBsCornerType;
    FDropdownMenu: TPopupMenu;
    FIsPressed: Boolean;
    FShowCaret: Boolean;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetStyle(AValue: TBsStyle);
    procedure SetSize(AValue: TBsSize);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetDropdownMenu(AValue: TPopupMenu);
    procedure SetShowCaret(AValue: Boolean);

    procedure ApplySize;
    procedure ShowDropdown;

    { LCL Messages }
    procedure CMMouseEnter(var Message: TLMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TLMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TLMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property Style: TBsStyle read FStyle write SetStyle default bssSolid;
    property SizeMode: TBsSize read FSize write SetSize default bszDefault;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctNormal;
    property DropdownMenu: TPopupMenu read FDropdownMenu write SetDropdownMenu;
    property ShowCaret: Boolean read FShowCaret write SetShowCaret default True;

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property Color;
    property Constraints;
    property Cursor;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Event Bawaan }
    property OnClick;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsDropdown]);
end;

{ TBsDropdown }

constructor TBsDropdown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;

  TabStop := True;
  FState := bcsNormal;
  FIsPressed := False;

  FThemeColor := btcPrimary;
  FStyle := bssSolid;
  FSize := bszDefault;
  FCornerType := bctNormal;
  FDropdownMenu := nil;
  FShowCaret := True;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  ApplySize;
end;

procedure TBsDropdown.ApplySize;
begin
  case FSize of
    bszSmall:
      begin
        Height := 31;
        if Width < 80 then Width := 80;
        Font.Size := 9;
      end;
    bszDefault:
      begin
        Height := 38;
        if Width < 120 then Width := 120;
        Font.Size := 10;
      end;
    bszLarge:
      begin
        Height := 48;
        if Width < 140 then Width := 140;
        Font.Size := 12;
      end;
  end;
end;

procedure TBsDropdown.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsDropdown.SetStyle(AValue: TBsStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TBsDropdown.SetSize(AValue: TBsSize);
begin
  if FSize = AValue then Exit;
  FSize := AValue;
  ApplySize;
  Invalidate;
end;

procedure TBsDropdown.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsDropdown.SetDropdownMenu(AValue: TPopupMenu);
begin
  if FDropdownMenu = AValue then Exit;
  FDropdownMenu := AValue;
end;

procedure TBsDropdown.SetShowCaret(AValue: Boolean);
begin
  if FShowCaret = AValue then Exit;
  FShowCaret := AValue;
  Invalidate;
end;

procedure TBsDropdown.ShowDropdown;
var
  Pt: TPoint;
begin
  if Assigned(FDropdownMenu) then
  begin
    FState := bcsActive;
    Invalidate;
    Update; // Paksa render state aktif sebelum popup menahan thread

    Pt := ClientToScreen(Point(0, Height));
    FDropdownMenu.PopUp(Pt.X, Pt.Y);

    // Kembalikan status setelah menu ditutup
    FIsPressed := False;
    if PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos)) then
      FState := bcsHover
    else if Focused then
      FState := bcsFocused
    else
      FState := bcsNormal;
    Invalidate;
  end
  else if Assigned(OnClick) then
    OnClick(Self);
end;

procedure TBsDropdown.CMMouseEnter(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  if not Focused then
    FState := bcsHover
  else
    FState := bcsHover;
  Invalidate;
end;

procedure TBsDropdown.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsDropdown.CMEnabledChanged(var Message: TLMessage);
begin
  inherited;
  if not Enabled then
  begin
    FState := bcsDisabled;
    FIsPressed := False;
  end
  else if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsDropdown.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsDropdown.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsDropdown.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsPressed := True;
    FState := bcsActive;
    if CanFocus then SetFocus;
    Invalidate;
  end;
end;

procedure TBsDropdown.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if FIsPressed and (Button = mbLeft) then
  begin
    if PtInRect(ClientRect, Point(X, Y)) then
      ShowDropdown
    else
    begin
      FIsPressed := False;
      if Focused then FState := bcsFocused else FState := bcsNormal;
      Invalidate;
    end;
  end;
end;

procedure TBsDropdown.DoEnter;
begin
  inherited DoEnter;
  if Enabled and not FIsPressed then
  begin
    FState := bcsFocused;
    Invalidate;
  end;
end;

procedure TBsDropdown.DoExit;
begin
  inherited DoExit;
  if Enabled then
  begin
    FIsPressed := False;
    FState := bcsNormal;
    Invalidate;
  end;
end;

procedure TBsDropdown.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_SPACE) or (Key = VK_RETURN) or (Key = VK_DOWN) then
  begin
    FIsPressed := True;
    FState := bcsActive;
    Invalidate;
  end;
end;

procedure TBsDropdown.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if FIsPressed and ((Key = VK_SPACE) or (Key = VK_RETURN) or (Key = VK_DOWN)) then
  begin
    ShowDropdown;
  end;
end;

procedure TBsDropdown.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, FillColor, BdColor, TxtColor, FocusColor: TBGRAPixel;
  Radius, CaretX, CaretY: Integer;
  TextRect: TRect;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  //Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    FillColor := ColorToBGRA(clNone);
    BdColor := ColorToBGRA(clNone);
    TxtColor := TBsTheme.GetTextColor(FThemeColor, FStyle);

    if not Enabled then
    begin
      if FStyle = bssSolid then
      begin
        FillColor := TBsTheme.GetDisabledColor;
        BdColor := FillColor;
      end
      else
        BdColor := TBsTheme.GetDisabledColor;
      TxtColor := TBsTheme.GetDisabledTextColor;
    end
    else
    begin
      case FStyle of
        bssSolid:
          begin
            BdColor := TBsTheme.GetBaseColor(FThemeColor);
            case FState of
              bcsNormal, bcsFocused: FillColor := BdColor;
              bcsHover: FillColor := TBsTheme.GetHoverColor(FThemeColor);
              bcsActive: FillColor := TBsTheme.GetActiveColor(FThemeColor);
            end;
            if FState <> bcsNormal then BdColor := FillColor;
          end;
        bssOutline:
          begin
            BdColor := TBsTheme.GetBaseColor(FThemeColor);
            case FState of
              bcsHover:
                begin
                  FillColor := BdColor;
                  TxtColor := BS_TEXT_COLOR[FThemeColor];
                end;
              bcsActive:
                begin
                  FillColor := TBsTheme.GetActiveColor(FThemeColor);
                  BdColor := FillColor;
                  TxtColor := BS_TEXT_COLOR[FThemeColor];
                end;
            end;
          end;
      end;
    end;

    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    if (FState = bcsFocused) or ((Focused) and (FState = bcsHover)) then
    begin
      FocusColor := TBsTheme.GetFocusRingColor(FThemeColor);
      TBsGraphics.DrawFocusRing(Bmp, ClientRect, Radius, FocusColor, 3);
    end;

    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);

    TextRect := ClientRect;
    if FShowCaret then
    begin
      TextRect.Right := TextRect.Right - 20; // Sisakan ruang untuk caret

      // Gambar Caret (Segitiga kecil ke bawah)
      CaretX := Width - 14;
      CaretY := (Height div 2) - 2;

      Bmp.FillPolyAntialias([
        PointF(CaretX - 4, CaretY),
        PointF(CaretX + 4, CaretY),
        PointF(CaretX, CaretY + 4)
      ], TxtColor);
    end;

    TBsGraphics.DrawText(Bmp, TextRect, Caption, Font, TxtColor, bsaCenter, 0);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.

