unit bscarousel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, LMessages, LCLType, Types, Math,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsCarousel = class;

  { TBsCarouselItem: Data untuk satu slide di Carousel }
  TBsCarouselItem = class(TCollectionItem)
  private
    FPicture: TPicture;
    FTitle: string;
    FCaption: string;
    procedure SetPicture(AValue: TPicture);
    procedure SetTitle(const AValue: string);
    procedure SetCaption(const AValue: string);
    procedure PictureChanged(Sender: TObject);
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Picture: TPicture read FPicture write SetPicture;
    property Title: string read FTitle write SetTitle;
    property Caption: string read FCaption write SetCaption;
  end;

  { TBsCarouselItems: Koleksi slide }
  TBsCarouselItems = class(TCollection)
  private
    FCarousel: TBsCarousel;
    function GetItem(Index: Integer): TBsCarouselItem;
    procedure SetItem(Index: Integer; Value: TBsCarouselItem);
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(ACarousel: TBsCarousel);
    property Items[Index: Integer]: TBsCarouselItem read GetItem write SetItem; default;
  end;

  { TBsCarousel: Komponen Slideshow gambar/konten bergaya Bootstrap }
  TBsCarousel = class(TCustomControl)
  private
    FItems: TBsCarouselItems;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FAutoPlay: Boolean;
    FInterval: Integer;
    FShowIndicators: Boolean;
    FShowControls: Boolean;

    FCurrentIndex: Integer;
    FNextIndex: Integer;
    FAnimProgress: Integer; // 0..100
    FAnimDirection: Integer; // 1 (Next), -1 (Prev)
    FIsAnimating: Boolean;

    FAutoPlayTimer: TTimer;
    FAnimTimer: TTimer;

    FIsHovered: Boolean;
    FHoverElement: Integer; // 0=None, 1=Prev, 2=Next
    FDownElement: Integer;

    procedure SetItems(AValue: TBsCarouselItems);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetAutoPlay(AValue: Boolean);
    procedure SetInterval(AValue: Integer);
    procedure SetCurrentIndex(AValue: Integer);

    procedure OnAutoPlayTick(Sender: TObject);
    procedure OnAnimTick(Sender: TObject);

    function GetPrevRect: TRect;
    function GetNextRect: TRect;
    function GetIndicatorsRect: TRect;
    function GetElementAt(X, Y: Integer): Integer;

    { LCL Messages }
    procedure CMMouseEnter(var Message: TLMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Next;
    procedure Prev;
    procedure GoToSlide(Index: Integer);
    procedure ItemsChanged;
  published
    property Items: TBsCarouselItems read FItems write SetItems;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcLight;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property AutoPlay: Boolean read FAutoPlay write SetAutoPlay default True;
    property Interval: Integer read FInterval write SetInterval default 5000;
    property ShowIndicators: Boolean read FShowIndicators write FShowIndicators default True;
    property ShowControls: Boolean read FShowControls write FShowControls default True;
    property CurrentIndex: Integer read FCurrentIndex write SetCurrentIndex default 0;

    { Properti Bawaan }
    property Align;
    property Anchors;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property Visible;

    { Events }
    property OnClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsCarousel]);
end;

{ TBsCarouselItem }

constructor TBsCarouselItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FPicture := TPicture.Create;
  FPicture.OnChange := @PictureChanged;
  FTitle := '';
  FCaption := '';
end;

destructor TBsCarouselItem.Destroy;
begin
  FPicture.Free;
  inherited Destroy;
end;

procedure TBsCarouselItem.Assign(Source: TPersistent);
begin
  if Source is TBsCarouselItem then
  begin
    FPicture.Assign(TBsCarouselItem(Source).Picture);
    FTitle := TBsCarouselItem(Source).Title;
    FCaption := TBsCarouselItem(Source).Caption;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

procedure TBsCarouselItem.SetPicture(AValue: TPicture);
begin
  FPicture.Assign(AValue);
end;

procedure TBsCarouselItem.SetTitle(const AValue: string);
begin
  if FTitle = AValue then Exit;
  FTitle := AValue;
  Changed(False);
end;

procedure TBsCarouselItem.SetCaption(const AValue: string);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  Changed(False);
end;

procedure TBsCarouselItem.PictureChanged(Sender: TObject);
begin
  Changed(False);
end;

{ TBsCarouselItems }

constructor TBsCarouselItems.Create(ACarousel: TBsCarousel);
begin
  inherited Create(TBsCarouselItem);
  FCarousel := ACarousel;
end;

function TBsCarouselItems.GetOwner: TPersistent;
begin
  Result := FCarousel;
end;

function TBsCarouselItems.GetItem(Index: Integer): TBsCarouselItem;
begin
  Result := TBsCarouselItem(inherited GetItem(Index));
end;

procedure TBsCarouselItems.SetItem(Index: Integer; Value: TBsCarouselItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TBsCarouselItems.Update(Item: TCollectionItem);
begin
  if Assigned(FCarousel) then FCarousel.ItemsChanged;
end;

{ TBsCarousel }

constructor TBsCarousel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  Width := 600;
  Height := 300;
  Color := clBlack;

  FThemeColor := btcLight;
  FCornerType := bctSmall;
  FAutoPlay := True;
  FInterval := 5000;
  FShowIndicators := True;
  FShowControls := True;

  FCurrentIndex := 0;
  FIsAnimating := False;
  FAnimProgress := 0;
  FHoverElement := 0;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  FItems := TBsCarouselItems.Create(Self);

  FAutoPlayTimer := TTimer.Create(Self);
  FAutoPlayTimer.Interval := FInterval;
  FAutoPlayTimer.OnTimer := @OnAutoPlayTick;
  FAutoPlayTimer.Enabled := not (csDesigning in ComponentState) and FAutoPlay;

  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Interval := 16;
  FAnimTimer.OnTimer := @OnAnimTick;
  FAnimTimer.Enabled := False;
end;

destructor TBsCarousel.Destroy;
begin
  FAutoPlayTimer.Free;
  FAnimTimer.Free;
  FItems.Free;
  inherited Destroy;
end;

procedure TBsCarousel.SetItems(AValue: TBsCarouselItems);
begin
  FItems.Assign(AValue);
end;

procedure TBsCarousel.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsCarousel.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsCarousel.SetAutoPlay(AValue: Boolean);
begin
  if FAutoPlay = AValue then Exit;
  FAutoPlay := AValue;
  if not (csDesigning in ComponentState) then
    FAutoPlayTimer.Enabled := FAutoPlay and not FIsHovered;
end;

procedure TBsCarousel.SetInterval(AValue: Integer);
begin
  if FInterval = AValue then Exit;
  FInterval := AValue;
  FAutoPlayTimer.Interval := FInterval;
end;

procedure TBsCarousel.SetCurrentIndex(AValue: Integer);
begin
  if FItems.Count = 0 then Exit;
  if AValue < 0 then AValue := FItems.Count - 1;
  if AValue >= FItems.Count then AValue := 0;

  if FCurrentIndex = AValue then Exit;
  GoToSlide(AValue);
end;

procedure TBsCarousel.ItemsChanged;
begin
  if FCurrentIndex >= FItems.Count then
    FCurrentIndex := Max(0, FItems.Count - 1);
  Invalidate;
end;

function TBsCarousel.GetPrevRect: TRect;
begin
  Result := Rect(0, 0, Width div 8, Height);
end;

function TBsCarousel.GetNextRect: TRect;
begin
  Result := Rect(Width - (Width div 8), 0, Width, Height);
end;

function TBsCarousel.GetIndicatorsRect: TRect;
begin
  Result := Rect(0, Height - 40, Width, Height);
end;

function TBsCarousel.GetElementAt(X, Y: Integer): Integer;
var
  Pt: TPoint;
begin
  Result := 0;
  if not FShowControls then Exit;

  Pt := Point(X, Y);
  if PtInRect(GetPrevRect, Pt) then Result := 1
  else if PtInRect(GetNextRect, Pt) then Result := 2;
end;

procedure TBsCarousel.WMSize(var Message: TLMSize);
begin
  inherited;
  Invalidate;
end;

procedure TBsCarousel.Next;
begin
  if FItems.Count <= 1 then Exit;
  GoToSlide((FCurrentIndex + 1) mod FItems.Count);
end;

procedure TBsCarousel.Prev;
begin
  if FItems.Count <= 1 then Exit;
  if FCurrentIndex = 0 then
    GoToSlide(FItems.Count - 1)
  else
    GoToSlide(FCurrentIndex - 1);
end;

procedure TBsCarousel.GoToSlide(Index: Integer);
begin
  if (Index = FCurrentIndex) or FIsAnimating or (FItems.Count <= 1) then Exit;

  FNextIndex := Index;
  // Tentukan arah geser
  if (Index > FCurrentIndex) or ((FCurrentIndex = FItems.Count - 1) and (Index = 0)) then
  begin
    if (Index = FItems.Count - 1) and (FCurrentIndex = 0) then
      FAnimDirection := -1
    else
      FAnimDirection := 1;
  end
  else
    FAnimDirection := -1;

  FAnimProgress := 0;
  FIsAnimating := True;

  if FAutoPlayTimer.Enabled then
  begin
    FAutoPlayTimer.Enabled := False;
    FAutoPlayTimer.Enabled := True; // Reset timer
  end;

  FAnimTimer.Enabled := True;
end;

procedure TBsCarousel.OnAutoPlayTick(Sender: TObject);
begin
  if not FIsAnimating and not FIsHovered then
    Next;
end;

procedure TBsCarousel.OnAnimTick(Sender: TObject);
begin
  Inc(FAnimProgress, 6); // Kecepatan animasi
  if FAnimProgress >= 100 then
  begin
    FAnimProgress := 100;
    FIsAnimating := False;
    FAnimTimer.Enabled := False;
    FCurrentIndex := FNextIndex;
  end;
  Invalidate;
end;

procedure TBsCarousel.CMMouseEnter(var Message: TLMessage);
begin
  inherited;
  FIsHovered := True;
  if FAutoPlay and not (csDesigning in ComponentState) then
    FAutoPlayTimer.Enabled := False;
  Invalidate;
end;

procedure TBsCarousel.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  FIsHovered := False;
  FHoverElement := 0;
  if FAutoPlay and not (csDesigning in ComponentState) then
    FAutoPlayTimer.Enabled := True;
  Invalidate;
end;

procedure TBsCarousel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHover: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  NewHover := GetElementAt(X, Y);
  if FHoverElement <> NewHover then
  begin
    FHoverElement := NewHover;
    if FHoverElement > 0 then Cursor := crHandPoint else Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TBsCarousel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  IndRect: TRect;
  IndCount, IndW, IndSpc, StartX, i: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownElement := GetElementAt(X, Y);

    // Cek klik pada indicator
    if FShowIndicators and (FItems.Count > 1) and not FIsAnimating then
    begin
      IndRect := GetIndicatorsRect;
      if PtInRect(IndRect, Point(X, Y)) then
      begin
        IndCount := FItems.Count;
        IndW := 30;
        IndSpc := 8;
        StartX := (Width - (IndCount * IndW + (IndCount - 1) * IndSpc)) div 2;

        for i := 0 to IndCount - 1 do
        begin
          if (X >= StartX) and (X <= StartX + IndW) then
          begin
            if i <> FCurrentIndex then GoToSlide(i);
            Break;
          end;
          Inc(StartX, IndW + IndSpc);
        end;
      end;
    end;

    Invalidate;
  end;
end;

procedure TBsCarousel.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpElement: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and (FDownElement <> 0) then
  begin
    UpElement := GetElementAt(X, Y);
    if UpElement = FDownElement then
    begin
      if UpElement = 1 then Prev
      else if UpElement = 2 then Next;
    end;
    FDownElement := 0;
    Invalidate;
  end;
end;

procedure TBsCarousel.Paint;
var
  Bmp, ViewBmp, SlideBmp: TBGRABitmap;
  BgColor, ControlColor, IndColor: TBGRAPixel;
  Radius, SlideOffset, i, IndCount, IndW, IndSpc, StartX: Integer;
  TitleFont, CapFont: TFont;

  procedure DrawSlide(TargetBmp: TBGRABitmap; SlideIndex, OffsetX: Integer);
  var
    Item: TBsCarouselItem;
    TempBmp: TBGRABitmap;
    DestRect: TRect;
  begin
    if (SlideIndex < 0) or (SlideIndex >= FItems.Count) then Exit;
    Item := FItems[SlideIndex];

    // Background Dasar
    TargetBmp.FillRectAntialias(OffsetX, 0, OffsetX + Width, Height, ColorToBGRA(ColorToRGB(Color)));

    // Gambar (Jika Ada)
    if Assigned(Item.Picture.Graphic) and not Item.Picture.Graphic.Empty then
    begin
      TempBmp := TBGRABitmap.Create;
      try
        TempBmp.Assign(Item.Picture.Graphic);
        // Cover / Proportional stretch ke DestRect
        DestRect := Rect(OffsetX, 0, OffsetX + Width, Height);
        TempBmp.Draw(TargetBmp.Canvas, DestRect, True);
      finally
        TempBmp.Free;
      end;
    end;

    // Overlay Gradien Bawah (Untuk visibilitas teks)
    if (Length(Item.Title) > 0) or (Length(Item.Caption) > 0) then
    begin
      TargetBmp.GradientFill(OffsetX, Height - 120, OffsetX + Width, Height,
        BGRA(0,0,0,0), BGRA(0,0,0,180), gtLinear, PointF(0, Height - 120), PointF(0, Height), dmDrawWithTransparency);

      TBsGraphics.DrawText(TargetBmp, Rect(OffsetX + 40, Height - 90, OffsetX + Width - 40, Height - 50), Item.Title, TitleFont, BGRA(255,255,255,255), bsaCenter, 0);
      TBsGraphics.DrawText(TargetBmp, Rect(OffsetX + 40, Height - 50, OffsetX + Width - 40, Height - 10), Item.Caption, CapFont, BGRA(255,255,255,200), bsaCenter, 0);
    end;
  end;

begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  ViewBmp := TBGRABitmap.Create(Width, Height, ColorToBGRA(clNone));
  TitleFont := TFont.Create;
  CapFont := TFont.Create;
  try
    TitleFont.Assign(Font); TitleFont.Size := Font.Size + 4; TitleFont.Style := [fsBold];
    CapFont.Assign(Font); CapFont.Size := Font.Size;

    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    if FItems.Count = 0 then
    begin
      // Tampilan Kosong
      ViewBmp.FillRectAntialias(0, 0, Width, Height, TBsTheme.GetDisabledColor);
      TBsGraphics.DrawText(ViewBmp, ClientRect, 'No Slides Available', Font, TBsTheme.GetDisabledTextColor, bsaCenter, 0);
    end
    else
    begin
      // Render Slides
      if not FIsAnimating then
      begin
        DrawSlide(ViewBmp, FCurrentIndex, 0);
      end
      else
      begin
        // Kalkulasi posisi offset
        SlideOffset := Round(Width * (FAnimProgress / 100));

        if FAnimDirection = 1 then
        begin
          // Next: Current geser ke kiri, Next masuk dari kanan
          DrawSlide(ViewBmp, FCurrentIndex, -SlideOffset);
          DrawSlide(ViewBmp, FNextIndex, Width - SlideOffset);
        end
        else
        begin
          // Prev: Current geser ke kanan, Next masuk dari kiri
          DrawSlide(ViewBmp, FCurrentIndex, SlideOffset);
          DrawSlide(ViewBmp, FNextIndex, -Width + SlideOffset);
        end;
      end;

      // Render Controls (Prev/Next)
      if FShowControls and (FItems.Count > 1) then
      begin
        ControlColor := BGRA(255, 255, 255, 128); // Putih semi-transparan

        // Prev Chevron
        if FHoverElement = 1 then ControlColor.alpha := 255 else ControlColor.alpha := 128;
        ViewBmp.DrawLineAntialias(40, (Height div 2) - 15, 20, Height div 2, ControlColor, 3);
        ViewBmp.DrawLineAntialias(20, Height div 2, 40, (Height div 2) + 15, ControlColor, 3);

        // Next Chevron
        if FHoverElement = 2 then ControlColor.alpha := 255 else ControlColor.alpha := 128;
        ViewBmp.DrawLineAntialias(Width - 40, (Height div 2) - 15, Width - 20, Height div 2, ControlColor, 3);
        ViewBmp.DrawLineAntialias(Width - 20, Height div 2, Width - 40, (Height div 2) + 15, ControlColor, 3);
      end;

      // Render Indicators
      if FShowIndicators and (FItems.Count > 1) then
      begin
        IndCount := FItems.Count;
        IndW := 30; // Lebar standar indicator Bootstrap
        IndSpc := 6; // Jarak
        StartX := (Width - (IndCount * IndW + (IndCount - 1) * IndSpc)) div 2;

        for i := 0 to IndCount - 1 do
        begin
          IndColor := BGRA(255, 255, 255, 128);
          // Highlight active, jika animasi sedang jalan, highlight next
          if (not FIsAnimating and (i = FCurrentIndex)) or
             (FIsAnimating and (i = FNextIndex)) then
            IndColor.alpha := 255;

          ViewBmp.FillRoundRectAntialias(StartX, Height - 20, StartX + IndW, Height - 16, 2, 2, IndColor);
          Inc(StartX, IndW + IndSpc);
        end;
      end;
    end;

    // Masking Corner Radius pada keseluruhan ViewBmp
    if Radius > 0 then
    begin
      SlideBmp := TBGRABitmap.Create(Width, Height, BGRA(0,0,0,0));
      try
        SlideBmp.FillRoundRectAntialias(0, 0, Width, Height, Radius, Radius, BGRA(255,255,255,255));
        ViewBmp.ApplyMask(SlideBmp);
      finally
        SlideBmp.Free;
      end;
    end;

    // Blend ke Background
    Bmp.PutImage(0, 0, ViewBmp, dmDrawWithTransparency);

    // Draw Focus Ring (opsional)
    if Focused then
      TBsGraphics.DrawFocusRing(Bmp, ClientRect, Radius, TBsTheme.GetFocusRingColor(FThemeColor), 3);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    TitleFont.Free;
    CapFont.Free;
    ViewBmp.Free;
    Bmp.Free;
  end;
end;

end.
