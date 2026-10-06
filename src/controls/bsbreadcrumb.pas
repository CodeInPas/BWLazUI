unit bsbreadcrumb;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsBreadcrumbItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  { TBsBreadcrumb: Navigasi Breadcrumb bergaya Bootstrap 5 }
  TBsBreadcrumb = class(TCustomControl)
  private
    FItems: TStringList;
    FThemeColor: TBsThemeColor;
    FSeparator: string;

    FItemRects: array of TRect;
    FHoverIndex: Integer;
    FDownIndex: Integer;

    FOnItemClick: TBsBreadcrumbItemEvent;

    procedure SetItems(AValue: TStringList);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetSeparator(const AValue: string);

    procedure ItemsChanged(Sender: TObject);
    function GetIndexAt(X, Y: Integer): Integer;

    { LCL Messages }
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TStringList read FItems write SetItems;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property Separator: string read FSeparator write SetSeparator;

    { Properti Bawaan }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property ShowHint;
    property Visible;

    { Events }
    property OnItemClick: TBsBreadcrumbItemEvent read FOnItemClick write FOnItemClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsBreadcrumb]);
end;

{ TBsBreadcrumb }

constructor TBsBreadcrumb.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  Width := 300;
  Height := 38;
  Color := clWindow;

  FThemeColor := btcPrimary;
  FSeparator := '/';
  FHoverIndex := -1;
  FDownIndex := -1;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;
  FItems.Add('Home');
  FItems.Add('Library');
  FItems.Add('Data');
end;

destructor TBsBreadcrumb.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TBsBreadcrumb.SetItems(AValue: TStringList);
begin
  FItems.Assign(AValue);
end;

procedure TBsBreadcrumb.ItemsChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TBsBreadcrumb.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsBreadcrumb.SetSeparator(const AValue: string);
begin
  if FSeparator = AValue then Exit;
  FSeparator := AValue;
  Invalidate;
end;

procedure TBsBreadcrumb.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

function TBsBreadcrumb.GetIndexAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (Y < 0) or (Y > Height) then Exit;

  for i := 0 to High(FItemRects) do
  begin
    // Tidak izinkan interaksi pada item terakhir (Active Item)
    if (i < FItems.Count - 1) and PtInRect(FItemRects[i], Point(X, Y)) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TBsBreadcrumb.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Invalidate;
  end;
end;

procedure TBsBreadcrumb.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIndex: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled then Exit;

  NewIndex := GetIndexAt(X, Y);
  if FHoverIndex <> NewIndex then
  begin
    FHoverIndex := NewIndex;
    if FHoverIndex <> -1 then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TBsBreadcrumb.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownIndex := GetIndexAt(X, Y);
    if FDownIndex <> -1 then Invalidate;
  end;
end;

procedure TBsBreadcrumb.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (FDownIndex <> -1) then
  begin
    UpIndex := GetIndexAt(X, Y);
    if UpIndex = FDownIndex then
    begin
      if Assigned(FOnItemClick) then FOnItemClick(Self, UpIndex);
    end;
    FDownIndex := -1;
    Invalidate;
  end;
end;

procedure TBsBreadcrumb.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, LinkColor, ActiveColor, HoverColor, SepColor: TBGRAPixel;
  i, CurrentX, TextW, TextH, SepW: Integer;
  HoverFont, ActiveFont: TFont;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  HoverFont := TFont.Create;
  ActiveFont := TFont.Create;
  try
    HoverFont.Assign(Font);
    HoverFont.Style := [fsUnderline]; // Gaya hover link
    ActiveFont.Assign(Font);

    if not Enabled then
    begin
      LinkColor := TBsTheme.GetDisabledTextColor;
      ActiveColor := TBsTheme.GetDisabledTextColor;
      SepColor := TBsTheme.GetDisabledTextColor;
      HoverColor := LinkColor;
    end
    else
    begin
      LinkColor := TBsTheme.GetBaseColor(FThemeColor);
      HoverColor := TBsTheme.GetHoverColor(FThemeColor);
      ActiveColor := TBsTheme.GetTextColor(btcSecondary, bssSolid); // #6c757d
      SepColor := ActiveColor;
    end;

    // Persiapkan wadah perhitungan area interaktif
    SetLength(FItemRects, FItems.Count);
    CurrentX := 16; // Padding kiri bawaan 16px

    // Perhitungan ukuran separator
    Bmp.FontHeight := Font.Height;
    Bmp.FontName := Font.Name;
    SepW := Bmp.TextSize(FSeparator).cx;
    TextH := Bmp.TextSize('Wg').cy;

    for i := 0 to FItems.Count - 1 do
    begin
      TextW := Bmp.TextSize(FItems[i]).cx;

      // Simpan rect untuk event mouse
      FItemRects[i] := Rect(CurrentX, (Height - TextH) div 2, CurrentX + TextW, ((Height - TextH) div 2) + TextH);

      // Render Item
      if i = FItems.Count - 1 then
      begin
        // Item Terakhir (Active / Current Page)
        TBsGraphics.DrawText(Bmp, FItemRects[i], FItems[i], ActiveFont, ActiveColor, bsaStart, 0);
      end
      else
      begin
        // Item Link (Bisa diklik)
        if (i = FHoverIndex) or (i = FDownIndex) then
          TBsGraphics.DrawText(Bmp, FItemRects[i], FItems[i], HoverFont, HoverColor, bsaStart, 0)
        else
          TBsGraphics.DrawText(Bmp, FItemRects[i], FItems[i], Font, LinkColor, bsaStart, 0);

        Inc(CurrentX, TextW + 8);

        // Render Separator
        TBsGraphics.DrawText(Bmp, Rect(CurrentX, 0, CurrentX + SepW, Height), FSeparator, Font, SepColor, bsaStart, 0);
        Inc(CurrentX, SepW + 8);
      end;
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    HoverFont.Free;
    ActiveFont.Free;
    Bmp.Free;
  end;
end;

end.

