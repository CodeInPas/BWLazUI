unit bsnavbar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsNavbarItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  { TBsNavbar: Komponen Navigasi Header bergaya Bootstrap 5 }
  TBsNavbar = class(TCustomControl)
  private
    FBrandText: string;
    FItems: TStringList;
    FThemeColor: TBsThemeColor;

    FBrandRect: TRect;
    FItemRects: array of TRect;

    FBrandHovered: Boolean;
    FBrandPressed: Boolean;
    FItemHoverIndex: Integer;
    FItemDownIndex: Integer;

    FOnBrandClick: TNotifyEvent;
    FOnItemClick: TBsNavbarItemEvent;

    procedure SetBrandText(const AValue: string);
    procedure SetItems(AValue: TStringList);
    procedure SetThemeColor(AValue: TBsThemeColor);

    procedure ItemsChanged(Sender: TObject);
    procedure UpdateLayout;
    function GetItemIndexAt(X, Y: Integer): Integer;

    { LCL Messages }
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property BrandText: string read FBrandText write SetBrandText;
    property Items: TStringList read FItems write SetItems;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcDark;

    { Properti Bawaan }
    property Align default alTop;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property ShowHint;
    property Visible;

    { Events }
    property OnBrandClick: TNotifyEvent read FOnBrandClick write FOnBrandClick;
    property OnItemClick: TBsNavbarItemEvent read FOnItemClick write FOnItemClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsNavbar]);
end;

{ TBsNavbar }

constructor TBsNavbar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // 1. Inisialisasi Objek Internal Terlebih Dahulu (WAJIB di atas)
  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;

  // 2. Setup Style LCL
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  // 3. Setup Ukuran (Memanggil Resize/WMSize/UpdateLayout secara implisit)
  Align := alTop;
  Height := 56; // Standar tinggi navbar Bootstrap
  Width := 600;

  // 4. Setup Properti Lainnya
  FThemeColor := btcDark;
  FBrandText := 'Navbar';

  FBrandHovered := False;
  FBrandPressed := False;
  FItemHoverIndex := -1;
  FItemDownIndex := -1;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  // 5. Pengisian Data Awal
  FItems.Add('Home');
  FItems.Add('Features');
  FItems.Add('Pricing');

  UpdateLayout;
end;

destructor TBsNavbar.Destroy;
begin
  if Assigned(FItems) then
    FItems.Free;
  inherited Destroy;
end;

procedure TBsNavbar.SetBrandText(const AValue: string);
begin
  if FBrandText = AValue then Exit;
  FBrandText := AValue;
  UpdateLayout;
  Invalidate;
end;

procedure TBsNavbar.SetItems(AValue: TStringList);
begin
  if Assigned(FItems) and Assigned(AValue) then
    FItems.Assign(AValue);
end;

procedure TBsNavbar.ItemsChanged(Sender: TObject);
begin
  UpdateLayout;
  Invalidate;
end;

procedure TBsNavbar.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsNavbar.UpdateLayout;
var
  Bmp: TBGRABitmap;
  i, CurrentX, TextW, PadX: Integer;
begin
  // Guard Clause: Hindari eksekusi jika komponen belum selesai di-load atau ukuran belum wajar
  if not Assigned(FItems) or (csLoading in ComponentState) then Exit;
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(1, 1);
  try
    PadX := 16;
    CurrentX := PadX;

    // Kalkulasi Brand Rect
    Bmp.FontHeight := Font.Height + 2; // Brand sedikit lebih besar
    Bmp.FontName := Font.Name;
    Bmp.FontStyle := [fsBold];

    if Length(FBrandText) > 0 then
    begin
      TextW := Bmp.TextSize(FBrandText).cx;
      FBrandRect := Rect(CurrentX, 0, CurrentX + TextW + PadX, Height);
      Inc(CurrentX, TextW + PadX * 2); // Jarak ekstra setelah brand
    end
    else
      FBrandRect := Rect(0, 0, 0, 0);

    // Kalkulasi Items Rect
    SetLength(FItemRects, FItems.Count);
    Bmp.FontHeight := Font.Height;
    Bmp.FontStyle := [];

    for i := 0 to FItems.Count - 1 do
    begin
      TextW := Bmp.TextSize(FItems[i]).cx;
      FItemRects[i] := Rect(CurrentX, 0, CurrentX + TextW + (PadX * 2), Height);
      Inc(CurrentX, TextW + PadX * 2);
    end;
  finally
    Bmp.Free;
  end;
end;

function TBsNavbar.GetItemIndexAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  // Guard Clause
  if not Assigned(FItems) then Exit;

  for i := 0 to FItems.Count - 1 do
  begin
    if PtInRect(FItemRects[i], Point(X, Y)) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TBsNavbar.WMSize(var Message: TLMSize);
begin
  inherited;
  UpdateLayout;
end;

procedure TBsNavbar.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  UpdateLayout;
  Invalidate;
end;

procedure TBsNavbar.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FBrandHovered or (FItemHoverIndex <> -1) then
  begin
    FBrandHovered := False;
    FItemHoverIndex := -1;
    Invalidate;
  end;
end;

procedure TBsNavbar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewBrandHover: Boolean;
  NewItemHover: Integer;
  NeedUpdate: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled then Exit;

  NeedUpdate := False;

  NewBrandHover := PtInRect(FBrandRect, Point(X, Y));
  if FBrandHovered <> NewBrandHover then
  begin
    FBrandHovered := NewBrandHover;
    NeedUpdate := True;
  end;

  NewItemHover := GetItemIndexAt(X, Y);
  if FItemHoverIndex <> NewItemHover then
  begin
    FItemHoverIndex := NewItemHover;
    NeedUpdate := True;
  end;

  if NeedUpdate then
  begin
    if FBrandHovered or (FItemHoverIndex <> -1) then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TBsNavbar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    if PtInRect(FBrandRect, Point(X, Y)) then
      FBrandPressed := True
    else
      FItemDownIndex := GetItemIndexAt(X, Y);

    Invalidate;
  end;
end;

procedure TBsNavbar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if Button = mbLeft then
  begin
    if FBrandPressed then
    begin
      FBrandPressed := False;
      if PtInRect(FBrandRect, Point(X, Y)) and Assigned(FOnBrandClick) then
        FOnBrandClick(Self);
    end;

    if FItemDownIndex <> -1 then
    begin
      UpIndex := GetItemIndexAt(X, Y);
      if UpIndex = FItemDownIndex then
      begin
        if Assigned(FOnItemClick) then FOnItemClick(Self, UpIndex);
      end;
      FItemDownIndex := -1;
    end;

    Invalidate;
  end;
end;

procedure TBsNavbar.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, TxtColor, BaseTxtColor, HoverTxtColor: TBGRAPixel;
  i: Integer;
  BrandFont: TFont;
begin
  // Guard Clause Utama
  if not Assigned(FItems) or (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, ColorToBGRA(clNone));
  BrandFont := TFont.Create;
  try
    BrandFont.Assign(Font);
    BrandFont.Style := [fsBold];
    BrandFont.Size := Font.Size + 2;

    // Background Nav
    BgColor := TBsTheme.GetBaseColor(FThemeColor);
    Bmp.FillRectAntialias(0, 0, Width, Height, BgColor);

    // Penentuan Kontras Teks (Navbar Light vs Navbar Dark)
    if not Enabled then
    begin
      BaseTxtColor := TBsTheme.GetDisabledTextColor;
      HoverTxtColor := BaseTxtColor;
    end
    else
    begin
      if (FThemeColor = btcLight) or (FThemeColor = btcWarning) or (FThemeColor = btcNone) then
      begin
        BaseTxtColor := BGRA(0, 0, 0, 140); // Teks gelap semi-transparan
        HoverTxtColor := BGRA(0, 0, 0, 225); // Teks hover
      end
      else
      begin
        BaseTxtColor := BGRA(255, 255, 255, 140); // Teks putih semi-transparan
        HoverTxtColor := BGRA(255, 255, 255, 225); // Teks hover putih
      end;
    end;

    // Render Brand
    if Length(FBrandText) > 0 then
    begin
      TxtColor := HoverTxtColor; // Brand selalu warna hover/terang
      if FBrandPressed then TxtColor.alpha := 128; // Efek click

      TBsGraphics.DrawText(Bmp, FBrandRect, FBrandText, BrandFont, TxtColor, bsaCenter, 0);
    end;

    // Render Items
    for i := 0 to FItems.Count - 1 do
    begin
      if (i = FItemHoverIndex) or (i = FItemDownIndex) then
        TxtColor := HoverTxtColor
      else
        TxtColor := BaseTxtColor;

      if i = FItemDownIndex then TxtColor.alpha := 128; // Efek click

      TBsGraphics.DrawText(Bmp, FItemRects[i], FItems[i], Font, TxtColor, bsaCenter, 0);
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    BrandFont.Free;
    Bmp.Free;
  end;
end;

end.
