unit bsbutton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, Graphics, LMessages, LCLType,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsButton: Komponen tombol interaktif bergaya Bootstrap 5 }
  TBsButton = class(TCustomControl)
  private
    FState: TBsControlState;
    FThemeColor: TBsThemeColor;
    FStyle: TBsStyle;
    FSize: TBsSize;
    FCornerType: TBsCornerType;
    FIsPressed: Boolean;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetStyle(AValue: TBsStyle);
    procedure SetSize(AValue: TBsSize);
    procedure SetCornerType(AValue: TBsCornerType);

    procedure ApplySize;

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

    { Properti Bawaan LCL }
    property Action;
    property Align;
    property Anchors;
    property AutoSize;
    property BidiMode;
    property BorderSpacing;
    property Caption;
    property Color;
    property Constraints;
    property Cursor;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Event Bawaan }
    property OnClick;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsButton]);
end;

{ TBsButton }

constructor TBsButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csDoubleClicks];
  ControlStyle := ControlStyle - [csOpaque] + [csCaptureMouse];
  DoubleBuffered := True;

  TabStop := True;
  FState := bcsNormal;
  FIsPressed := False;

  FThemeColor := btcPrimary;
  FStyle := bssSolid;
  FSize := bszDefault;
  FCornerType := bctNormal;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  ApplySize;
end;

procedure TBsButton.ApplySize;
begin
  case FSize of
    bszSmall:
      begin
        Height := 31;
        if Width < 60 then Width := 60;
        Font.Size := 9;
      end;
    bszDefault:
      begin
        Height := 38;
        if Width < 80 then Width := 80;
        Font.Size := 10;
      end;
    bszLarge:
      begin
        Height := 48;
        if Width < 100 then Width := 100;
        Font.Size := 12;
      end;
  end;
end;

procedure TBsButton.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsButton.SetStyle(AValue: TBsStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TBsButton.SetSize(AValue: TBsSize);
begin
  if FSize = AValue then Exit;
  FSize := AValue;
  ApplySize;
  Invalidate;
end;

procedure TBsButton.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsButton.CMMouseEnter(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  if FIsPressed then
    FState := bcsActive
  else if not Focused then
    FState := bcsHover
  else
    FState := bcsHover; // Hover meng-override tampilan Focus (Focus ring tetap digambar)
  Invalidate;
end;

procedure TBsButton.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsButton.CMEnabledChanged(var Message: TLMessage);
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

procedure TBsButton.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsButton.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TBsButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if FIsPressed and (Button = mbLeft) then
  begin
    FIsPressed := False;
    if PtInRect(ClientRect, Point(X, Y)) then
      FState := bcsHover
    else if Focused then
      FState := bcsFocused
    else
      FState := bcsNormal;
    Invalidate;
  end;
end;

procedure TBsButton.DoEnter;
begin
  inherited DoEnter;
  if Enabled and not FIsPressed then
  begin
    FState := bcsFocused;
    Invalidate;
  end;
end;

procedure TBsButton.DoExit;
begin
  inherited DoExit;
  if Enabled then
  begin
    FIsPressed := False;
    FState := bcsNormal;
    Invalidate;
  end;
end;

procedure TBsButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_SPACE) or (Key = VK_RETURN) then
  begin
    FIsPressed := True;
    FState := bcsActive;
    Invalidate;
  end;
end;

procedure TBsButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if FIsPressed and ((Key = VK_SPACE) or (Key = VK_RETURN)) then
  begin
    FIsPressed := False;
    FState := bcsFocused;
    Invalidate;
    if Assigned(OnClick) then OnClick(Self);
  end;
end;

procedure TBsButton.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, FillColor, BdColor, TxtColor, FocusColor: TBGRAPixel;
  Radius: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

 // Bmp := TBGRABitmap.Create(Width, Height, BgColor);
 // Bmp := TBGRABitmap.Create(Width, Height);
  Bmp := TBGRABitmap.Create(Width, Height);
  try
    // Reset warna dasar
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
            // Border mengikuti Fill pada Solid
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
        bssSoft:
          begin
            FillColor := TBsTheme.GetBaseColor(FThemeColor);
            FillColor.alpha := 38; // 15% opacity
            case FState of
              bcsHover: FillColor.alpha := 64; // 25% opacity
              bcsActive: FillColor.alpha := 89; // 35% opacity
            end;
          end;
        bssGhost:
          begin
            case FState of
              bcsHover:
                begin
                  FillColor := TBsTheme.GetBaseColor(FThemeColor);
                  FillColor.alpha := 38;
                end;
              bcsActive:
                begin
                  FillColor := TBsTheme.GetBaseColor(FThemeColor);
                  FillColor.alpha := 64;
                end;
            end;
          end;
      end;
    end;

    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    // Render Focus Ring (Di belakang background jika outline, atau di sekitarnya)
    if (FState = bcsFocused) or ((Focused) and (FState = bcsHover)) then
    begin
      FocusColor := TBsTheme.GetFocusRingColor(FThemeColor);
      TBsGraphics.DrawFocusRing(Bmp, ClientRect, Radius, FocusColor, 3);
    end;

    // Render Background dan Border
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);

    // Render Text
    TBsGraphics.DrawText(Bmp, ClientRect, Caption, Font, TxtColor, bsaCenter, 0);

    //Bmp.Draw(Canvas, 0, 0, False);
    Bmp.Draw(Canvas, 0, 0, True);
  finally
    Bmp.Free;
  end;
end;

end.
