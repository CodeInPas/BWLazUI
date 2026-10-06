unit bscard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, Graphics, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsCard: Komponen container (wadah) layout fleksibel dengan header & footer }
  TBsCard = class(TCustomPanel)
  private
    FHeaderHeight: Integer;
    FFooterHeight: Integer;
    FShowHeader: Boolean;
    FShowFooter: Boolean;
    FHeaderText: string;
    FFooterText: string;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FImageSrc: string; // Path/URL placeholder untuk card image top

    procedure SetHeaderHeight(AValue: Integer);
    procedure SetFooterHeight(AValue: Integer);
    procedure SetShowHeader(AValue: Boolean);
    procedure SetShowFooter(AValue: Boolean);
    procedure SetHeaderText(const AValue: string);
    procedure SetFooterText(const AValue: string);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);

    procedure UpdateClientArea;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure AdjustClientRect(var Rect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 40;
    property FooterHeight: Integer read FFooterHeight write SetFooterHeight default 40;
    property ShowHeader: Boolean read FShowHeader write SetShowHeader default False;
    property ShowFooter: Boolean read FShowFooter write SetShowFooter default False;
    property HeaderText: string read FHeaderText write SetHeaderText;
    property FooterText: string read FFooterText write SetFooterText;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcLight;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;

    { Properti bawaan TCustomPanel }
    property Align;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property BevelInner default bvNone;
    property BevelOuter default bvNone;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color default clWindow;
    property Constraints;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground default False;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;

    { Events }
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsCard]);
end;

{ TBsCard }

constructor TBsCard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;

  Width := 300;
  Height := 200;

  BevelInner := bvNone;
  BevelOuter := bvNone;
  Color := clWindow;

  FHeaderHeight := 40;
  FFooterHeight := 40;
  FShowHeader := False;
  FShowFooter := False;
  FThemeColor := btcLight;
  FCornerType := bctSmall;

  FHeaderText := 'Card Header';
  FFooterText := 'Card Footer';

  Font.Name := 'Segoe UI';
  Font.Size := 10;
end;

procedure TBsCard.UpdateClientArea;
begin
  Realign;
  Invalidate;
end;

procedure TBsCard.AdjustClientRect(var Rect: TRect);
var
  Padding: Integer;
begin
  inherited AdjustClientRect(Rect);

  Padding := 1; // Ruang untuk border
  Inc(Rect.Left, Padding);
  Inc(Rect.Top, Padding);
  Dec(Rect.Right, Padding);
  Dec(Rect.Bottom, Padding);

  if FShowHeader then
    Inc(Rect.Top, FHeaderHeight);

  if FShowFooter then
    Dec(Rect.Bottom, FFooterHeight);
end;

procedure TBsCard.SetHeaderHeight(AValue: Integer);
begin
  if FHeaderHeight = AValue then Exit;
  FHeaderHeight := AValue;
  UpdateClientArea;
end;

procedure TBsCard.SetFooterHeight(AValue: Integer);
begin
  if FFooterHeight = AValue then Exit;
  FFooterHeight := AValue;
  UpdateClientArea;
end;

procedure TBsCard.SetShowHeader(AValue: Boolean);
begin
  if FShowHeader = AValue then Exit;
  FShowHeader := AValue;
  UpdateClientArea;
end;

procedure TBsCard.SetShowFooter(AValue: Boolean);
begin
  if FShowFooter = AValue then Exit;
  FShowFooter := AValue;
  UpdateClientArea;
end;

procedure TBsCard.SetHeaderText(const AValue: string);
begin
  if FHeaderText = AValue then Exit;
  FHeaderText := AValue;
  if FShowHeader then Invalidate;
end;

procedure TBsCard.SetFooterText(const AValue: string);
begin
  if FFooterText = AValue then Exit;
  FFooterText := AValue;
  if FShowFooter then Invalidate;
end;

procedure TBsCard.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsCard.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsCard.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TBsCard.Paint;
var
  Bmp, HeaderBmp: TBGRABitmap;
  BgColor, FillColor, BdColor, HeaderColor, TxtColor: TBGRAPixel;
  Radius: Integer;
  HeaderRect, FooterRect: TRect;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

    Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);              try
    FillColor := ColorToBGRA(ColorToRGB(Color));

    // Tentukan warna border dan text berdasarkan tema
    if FThemeColor = btcLight then
    begin
      BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline); // Default abu-abu tipis (12.5% black)
      HeaderColor := BGRA($F7, $F7, $F7, 255); // #F7F7F7
      TxtColor := TBsTheme.GetTextColor(btcDark, bssSolid);
    end
    else
    begin
      BdColor := TBsTheme.GetBaseColor(FThemeColor);
      FillColor := TBsTheme.GetBaseColor(FThemeColor);
      HeaderColor := TBsTheme.GetActiveColor(FThemeColor); // Sedikit lebih gelap
      TxtColor := BS_TEXT_COLOR[FThemeColor];
    end;

    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);
    if Radius > (Width div 2) then Radius := Width div 2; // Cegah radius aneh

    // 1. Gambar Background Utama & Outline Card
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);

    // 2. Gambar Header (Bila Aktif)
    if FShowHeader then
    begin
      HeaderRect := Rect(0, 0, Width, FHeaderHeight);

      // Menggambar header dengan corner radius di atas tapi flat di bawah
      HeaderBmp := TBGRABitmap.Create(Width, FHeaderHeight, ColorToBGRA(clNone));
      try
        // Gambar background dan border bawah header
        HeaderBmp.FillRectAntialias(0, 0, Width, FHeaderHeight, HeaderColor);
        HeaderBmp.DrawLineAntialias(0, FHeaderHeight - 1, Width, FHeaderHeight - 1, BdColor, 1);

        // Render Teks Header
        TBsGraphics.DrawText(HeaderBmp, Rect(16, 0, Width - 16, FHeaderHeight), FHeaderText, Font, TxtColor, bsaStart, 0);

        Bmp.PutImage(0, 0, HeaderBmp, dmDrawWithTransparency);
      finally
        HeaderBmp.Free;
      end;

      // Paksa sudut membulat dengan menggambar ulang outline card di atasnya
      Bmp.RoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, BdColor, 1);
    end;

    // 3. Gambar Footer (Bila Aktif)
    if FShowFooter then
    begin
      FooterRect := Rect(0, Height - FFooterHeight, Width, Height);

      // Background footer
      Bmp.FillRectAntialias(0, Height - FFooterHeight, Width, Height, HeaderColor);
      // Border atas footer
      Bmp.DrawLineAntialias(0, Height - FFooterHeight, Width, Height - FFooterHeight, BdColor, 1);

      // Render Teks Footer
      TBsGraphics.DrawText(Bmp, Rect(16, Height - FFooterHeight, Width - 16, Height), FFooterText, Font, TxtColor, bsaStart, 0);

      // Paksa outline ulang
      Bmp.RoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, BdColor, 1);
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
