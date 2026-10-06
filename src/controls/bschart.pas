unit bschart;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, LMessages, LCLType, Types,
  Math, BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsChartType = (bctBar, bctLine, bctPie, bctDonut, bctGauge);

  TBsChartItem = class(TCollectionItem)
  private
    FCaption: string;
    FValue: Double;
    FColor: TColor;
    procedure SetCaption(const AValue: string);
    procedure SetValue(AValue: Double);
    procedure SetColor(AValue: TColor);
  public
    constructor Create(ACollection: TCollection); override;
  published
    property Caption: string read FCaption write SetCaption;
    property Value: Double read FValue write SetValue;
    property Color: TColor read FColor write SetColor default clHighlight;
  end;

  TBsChartItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TBsChartItem;
    procedure SetItem(Index: Integer; AValue: TBsChartItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TBsChartItem;
    property Items[Index: Integer]: TBsChartItem read GetItem write SetItem; default;
  end;

  TBsChart = class(TCustomControl)
  private
    FTitle: string;
    FChartType: TBsChartType;
    FItems: TBsChartItems;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FShowGrid: Boolean;
    FShowValues: Boolean;

    procedure SetTitle(const AValue: string);
    procedure SetChartType(AValue: TBsChartType);
    procedure SetItems(AValue: TBsChartItems);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetShowGrid(AValue: Boolean);
    procedure SetShowValues(AValue: Boolean);
    procedure OnItemsChange(Sender: TObject);

    // Helper untuk menggambar potongan chart pie/donut
    procedure DrawPieSlice(Bmp: TBGRABitmap; Cx, Cy, Radius, StartAngle, EndAngle: Double; AColor: TBGRAPixel);

    procedure DrawBarChart(Bmp: TBGRABitmap; PlotRect: TRect);
    procedure DrawLineChart(Bmp: TBGRABitmap; PlotRect: TRect);
    procedure DrawPieDonutChart(Bmp: TBGRABitmap; PlotRect: TRect; IsDonut: Boolean);
    procedure DrawGaugeChart(Bmp: TBGRABitmap; PlotRect: TRect);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddData(const ACaption: string; AValue: Double; AColor: TColor = clNone);
    procedure ClearData;
  published
    property Title: string read FTitle write SetTitle;
    property ChartType: TBsChartType read FChartType write SetChartType default bctBar;
    property Items: TBsChartItems read FItems write SetItems;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property ShowGrid: Boolean read FShowGrid write SetShowGrid default True;
    property ShowValues: Boolean read FShowValues write SetShowValues default True;

    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  // Dikosongkan agar pendaftaran ditangani terpusat oleh bootstrapui_register.pas
end;

{ TBsChartItem }

constructor TBsChartItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FCaption := 'Item ' + IntToStr(Index + 1);
  FValue := (Index + 1) * 10.0;
  FColor := RGBToColor(40 + (Index * 50) mod 200, 120 + (Index * 30) mod 130, 220);
end;

procedure TBsChartItem.SetCaption(const AValue: string);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  TBsChartItems(Collection).Update(Self);
end;

procedure TBsChartItem.SetValue(AValue: Double);
begin
  if FValue = AValue then Exit;
  FValue := AValue;
  TBsChartItems(Collection).Update(Self);
end;

procedure TBsChartItem.SetColor(AValue: TColor);
begin
  if FColor = AValue then Exit;
  FColor := AValue;
  TBsChartItems(Collection).Update(Self);
end;

{ TBsChartItems }

constructor TBsChartItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TBsChartItem);
end;

function TBsChartItems.Add: TBsChartItem;
begin
  Result := TBsChartItem(inherited Add);
end;

function TBsChartItems.GetItem(Index: Integer): TBsChartItem;
begin
  Result := TBsChartItem(inherited GetItem(Index));
end;

procedure TBsChartItems.SetItem(Index: Integer; AValue: TBsChartItem);
begin
  inherited SetItem(Index, AValue);
end;

{ TBsChart }

constructor TBsChart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  FItems := TBsChartItems.Create(Self);
  FTitle := 'Performance Analytics';
  FChartType := bctBar;
  FThemeColor := btcPrimary;
  FCornerType := bctSmall;
  FShowGrid := True;
  FShowValues := True;

  Width := 340;
  Height := 220;
  Color := clWindow;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  // Data Awal untuk Sampel Tampilan
  AddData('Jan', 45, RGBToColor(13, 110, 253));
  AddData('Feb', 75, RGBToColor(25, 135, 84));
  AddData('Mar', 30, RGBToColor(255, 193, 7));
  AddData('Apr', 90, RGBToColor(220, 53, 69));
end;

destructor TBsChart.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TBsChart.OnItemsChange(Sender: TObject);
begin
  Invalidate;
end;

procedure TBsChart.SetTitle(const AValue: string);
begin
  if FTitle = AValue then Exit;
  FTitle := AValue;
  Invalidate;
end;

procedure TBsChart.SetChartType(AValue: TBsChartType);
begin
  if FChartType = AValue then Exit;
  FChartType := AValue;
  Invalidate;
end;

procedure TBsChart.SetItems(AValue: TBsChartItems);
begin
  FItems.Assign(AValue);
  Invalidate;
end;

procedure TBsChart.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsChart.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsChart.SetShowGrid(AValue: Boolean);
begin
  if FShowGrid = AValue then Exit;
  FShowGrid := AValue;
  Invalidate;
end;

procedure TBsChart.SetShowValues(AValue: Boolean);
begin
  if FShowValues = AValue then Exit;
  FShowValues := AValue;
  Invalidate;
end;

procedure TBsChart.AddData(const ACaption: string; AValue: Double; AColor: TColor);
var
  NewItem: TBsChartItem;
begin
  NewItem := FItems.Add;
  NewItem.Caption := ACaption;
  NewItem.Value := AValue;
  if AColor <> clNone then
    NewItem.Color := AColor;
  Invalidate;
end;

procedure TBsChart.ClearData;
begin
  FItems.Clear;
  Invalidate;
end;

{ Drawing Logic }

procedure TBsChart.DrawPieSlice(Bmp: TBGRABitmap; Cx, Cy, Radius, StartAngle, EndAngle: Double; AColor: TBGRAPixel);
var
  Pts: array of TPointF;
  i, Steps: Integer;
  Theta: Double;
begin
  if Abs(EndAngle - StartAngle) <= 0.001 then Exit;

  // Hitung jumlah langkah (vertices) agar kurva tetap mulus sesuai besaran sudut
  Steps := Max(15, Round(Abs(EndAngle - StartAngle) * 0.6));
  SetLength(Pts, Steps + 2);

  // Titik pertama selalu pusat lingkaran
  Pts[0] := PointF(Cx, Cy);

  for i := 0 to Steps do
  begin
    Theta := DegToRad(StartAngle + (i / Steps) * (EndAngle - StartAngle));
    Pts[i + 1] := PointF(Cx + Cos(Theta) * Radius, Cy + Sin(Theta) * Radius);
  end;

  // Render array titik menjadi poligon tertutup
  Bmp.FillPolyAntialias(Pts, AColor);
end;

procedure TBsChart.DrawBarChart(Bmp: TBGRABitmap; PlotRect: TRect);
var
  i, Count: Integer;
  MaxVal, BarW, Gap, AvailableW, BarH: Double;
  X, Y: Double;
  BarRect: TRect;
  TextCol, GridCol: TBGRAPixel;
begin
  Count := FItems.Count;
  if Count = 0 then Exit;

  MaxVal := 0.0001;
  for i := 0 to Count - 1 do
    if FItems[i].Value > MaxVal then MaxVal := FItems[i].Value;

  TextCol := ColorToBGRA(RGBToColor(108, 117, 125));
  GridCol := ColorToBGRA(RGBToColor(233, 236, 239));

  if FShowGrid then
  begin
    Bmp.DrawLineAntialias(PlotRect.Left, PlotRect.Bottom, PlotRect.Right, PlotRect.Bottom, GridCol, 1);
    Bmp.DrawLineAntialias(PlotRect.Left, PlotRect.Top + (PlotRect.Height div 2), PlotRect.Right, PlotRect.Top + (PlotRect.Height div 2), GridCol, 1);
  end;

  AvailableW := PlotRect.Width;
  BarW := (AvailableW / Count) * 0.6;
  Gap := (AvailableW - (BarW * Count)) / (Count + 1);

  for i := 0 to Count - 1 do
  begin
    BarH := (FItems[i].Value / MaxVal) * (PlotRect.Height - 20);
    X := PlotRect.Left + Gap + i * (BarW + Gap);
    Y := PlotRect.Bottom - BarH;

    BarRect := Rect(Round(X), Round(Y), Round(X + BarW), PlotRect.Bottom);
    Bmp.FillRoundRectAntialias(BarRect.Left, BarRect.Top, BarRect.Right, BarRect.Bottom, 4, 4, ColorToBGRA(ColorToRGB(FItems[i].Color)));

    if FShowValues then
      TBsGraphics.DrawText(Bmp, Rect(Round(X - 5), Round(Y - 18), Round(X + BarW + 5), Round(Y)),
        FloatToStrF(FItems[i].Value, ffGeneral, 4, 0), Font, TextCol, TBsAlignment(0), 0);

    TBsGraphics.DrawText(Bmp, Rect(Round(X - 5), PlotRect.Bottom + 4, Round(X + BarW + 5), PlotRect.Bottom + 20),
      FItems[i].Caption, Font, TextCol, TBsAlignment(0), 0);
  end;
end;

procedure TBsChart.DrawLineChart(Bmp: TBGRABitmap; PlotRect: TRect);
var
  i, Count: Integer;
  MaxVal, StepX, PtX, PtY: Double;
  Pts: array of TPointF;
  TextCol, GridCol, LineCol: TBGRAPixel;
begin
  Count := FItems.Count;
  if Count = 0 then Exit;

  MaxVal := 0.0001;
  for i := 0 to Count - 1 do
    if FItems[i].Value > MaxVal then MaxVal := FItems[i].Value;

  TextCol := ColorToBGRA(RGBToColor(108, 117, 125));
  GridCol := ColorToBGRA(RGBToColor(233, 236, 239));
  LineCol := TBsTheme.GetBaseColor(FThemeColor);

  if FShowGrid then
  begin
    Bmp.DrawLineAntialias(PlotRect.Left, PlotRect.Bottom, PlotRect.Right, PlotRect.Bottom, GridCol, 1);
    Bmp.DrawLineAntialias(PlotRect.Left, PlotRect.Top + (PlotRect.Height div 2), PlotRect.Right, PlotRect.Top + (PlotRect.Height div 2), GridCol, 1);
  end;

  SetLength(Pts, Count);
  if Count > 1 then StepX := PlotRect.Width / (Count - 1) else StepX := PlotRect.Width;

  for i := 0 to Count - 1 do
  begin
    PtX := PlotRect.Left + (i * StepX);
    PtY := PlotRect.Bottom - ((FItems[i].Value / MaxVal) * (PlotRect.Height - 20));
    Pts[i] := PointF(PtX, PtY);

    if i > 0 then
      Bmp.DrawLineAntialias(Pts[i-1].X, Pts[i-1].Y, Pts[i].X, Pts[i].Y, LineCol, 2.5);

    Bmp.FillEllipseAntialias(PtX, PtY, 4, 4, LineCol);
    Bmp.FillEllipseAntialias(PtX, PtY, 2, 2, BGRA(255, 255, 255));

    TBsGraphics.DrawText(Bmp, Rect(Round(PtX - 20), PlotRect.Bottom + 4, Round(PtX + 20), PlotRect.Bottom + 20),
      FItems[i].Caption, Font, TextCol, TBsAlignment(0), 0);
  end;
end;

procedure TBsChart.DrawPieDonutChart(Bmp: TBGRABitmap; PlotRect: TRect; IsDonut: Boolean);
var
  i, Count: Integer;
  Total, StartAngle, SweepAngle, Cx, Cy, Radius: Double;
  BgCol: TBGRAPixel;
begin
  Count := FItems.Count;
  if Count = 0 then Exit;

  Total := 0;
  for i := 0 to Count - 1 do Total := Total + FItems[i].Value;
  if Total = 0 then Total := 1;

  Cx := PlotRect.Left + (PlotRect.Width / 2);
  Cy := PlotRect.Top + (PlotRect.Height / 2);
  Radius := Min(PlotRect.Width, PlotRect.Height) / 2 - 10;

  StartAngle := -90; // Mulai dari atas (jam 12)

  for i := 0 to Count - 1 do
  begin
    SweepAngle := (FItems[i].Value / Total) * 360;

    // Gunakan fungsi Helper DrawPieSlice yang baru
    DrawPieSlice(Bmp, Cx, Cy, Radius, StartAngle, StartAngle + SweepAngle, ColorToBGRA(ColorToRGB(FItems[i].Color)));

    StartAngle := StartAngle + SweepAngle;
  end;

  if IsDonut then
  begin
    BgCol := ColorToBGRA(ColorToRGB(Color));
    Bmp.FillEllipseAntialias(Cx, Cy, Radius * 0.55, Radius * 0.55, BgCol);
  end;
end;

procedure TBsChart.DrawGaugeChart(Bmp: TBGRABitmap; PlotRect: TRect);
var
  ValPercent, Cx, Cy, Radius, Angle: Double;
  BgTrack, FillCol, TextCol: TBGRAPixel;
begin
  ValPercent := 0;
  if FItems.Count > 0 then ValPercent := Min(100, Max(0, FItems[0].Value));

  Cx := PlotRect.Left + (PlotRect.Width / 2);
  Cy := PlotRect.Bottom - 10;
  Radius := Min(PlotRect.Width / 2, PlotRect.Height) - 15;

  BgTrack := ColorToBGRA(RGBToColor(222, 226, 230));
  FillCol := TBsTheme.GetBaseColor(FThemeColor);
  TextCol := TBsTheme.GetTextColor(btcDark, bssSolid);

  // Busur Latar Belakang (180 Derajat) menggunakan Helper DrawPieSlice
  DrawPieSlice(Bmp, Cx, Cy, Radius, 180, 360, BgTrack);

  // Busur Nilai Target
  Angle := 180 + (ValPercent / 100) * 180;
  DrawPieSlice(Bmp, Cx, Cy, Radius, 180, Angle, FillCol);

  // Masking Dalam agar membentuk lengkungan Gauge
  DrawPieSlice(Bmp, Cx, Cy, Radius * 0.65, 175, 365, ColorToBGRA(ColorToRGB(Color)));

  // Teks Persentase
  TBsGraphics.DrawText(Bmp, Rect(Round(Cx - 50), Round(Cy - 30), Round(Cx + 50), Round(Cy)),
    FloatToStrF(ValPercent, ffFixed, 7, 1) + '%', Font, TextCol, TBsAlignment(0), 0);
end;

procedure TBsChart.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, BorderCol, TextCol: TBGRAPixel;
  Radius, HeaderH: Integer;
  PlotRect, HeaderRect: TRect;
begin
  if (csLoading in ComponentState) or (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

 // Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  Bmp := TBGRABitmap.Create(Width, Height);
  try
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);
    HeaderH := 32;

    BorderCol := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
    TextCol := TBsTheme.GetTextColor(btcDark, bssSolid);

    Bmp.FillRoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, ColorToBGRA(ColorToRGB(Color)));
    Bmp.RoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, BorderCol, 1);

    HeaderRect := Rect(12, 0, Width - 12, HeaderH);
    TBsGraphics.DrawText(Bmp, HeaderRect, FTitle, Font, TextCol, TBsAlignment(0), 0);
    Bmp.DrawLineAntialias(0, HeaderH, Width - 1, HeaderH, BorderCol, 1);

    PlotRect := Rect(16, HeaderH + 12, Width - 16, Height - 24);

    case FChartType of
      bctBar: DrawBarChart(Bmp, PlotRect);
      bctLine: DrawLineChart(Bmp, PlotRect);
      bctPie: DrawPieDonutChart(Bmp, PlotRect, False);
      bctDonut: DrawPieDonutChart(Bmp, PlotRect, True);
      bctGauge: DrawGaugeChart(Bmp, PlotRect);
    end;

    Bmp.Draw(Canvas, 0, 0, False);
   // Bmp.Draw(Canvas, 0, 0, True);
  finally
    Bmp.Free;
  end;
end;

end.
