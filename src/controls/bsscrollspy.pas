unit bsscrollspy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Forms, Math, Types,
  bsnavtabs, bslistgroup;

type
  TBsScrollSpy = class;

  { TBsScrollSpyItem: Pemetaan antara Control target dan Index di Navigasi }
  TBsScrollSpyItem = class(TCollectionItem)
  private
    FTargetControl: TControl;
    FNavIndex: Integer;
    procedure SetTargetControl(AValue: TControl);
  public
    procedure Assign(Source: TPersistent); override;
  published
    property TargetControl: TControl read FTargetControl write SetTargetControl;
    property NavIndex: Integer read FNavIndex write FNavIndex default -1;
  end;

  { TBsScrollSpyItems: Koleksi item scrollspy }
  TBsScrollSpyItems = class(TCollection)
  private
    FScrollSpy: TBsScrollSpy;
    function GetItem(Index: Integer): TBsScrollSpyItem;
    procedure SetItem(Index: Integer; Value: TBsScrollSpyItem);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AScrollSpy: TBsScrollSpy);
    property Items[Index: Integer]: TBsScrollSpyItem read GetItem write SetItem; default;
  end;

  TBsSpyActiveEvent = procedure(Sender: TObject; ActiveIndex: Integer) of object;

  { TBsScrollSpy: Komponen untuk memonitor scroll dan memperbarui navigasi (NavTabs / ListGroup) }
  TBsScrollSpy = class(TComponent)
  private
    FContainer: TWinControl;
    FNavTabs: TBsNavTabs;
    FListGroup: TBsListGroup;
    FItems: TBsScrollSpyItems;
    FOffset: Integer;
    FActiveIndex: Integer;
    FTimer: TTimer;

    FOnActiveChanged: TBsSpyActiveEvent;

    procedure SetContainer(AValue: TWinControl);
    procedure SetItems(AValue: TBsScrollSpyItems);
    procedure SetActiveIndex(AValue: Integer);

    procedure OnCheckScroll(Sender: TObject);
    procedure UpdateNavigation;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Refresh;
  published
    property Container: TWinControl read FContainer write SetContainer;
    property NavTabs: TBsNavTabs read FNavTabs write FNavTabs;
    property ListGroup: TBsListGroup read FListGroup write FListGroup;
    property Items: TBsScrollSpyItems read FItems write SetItems;
    property Offset: Integer read FOffset write FOffset default 10;
    property ActiveIndex: Integer read FActiveIndex; // Read-only pada runtime

    property OnActiveChanged: TBsSpyActiveEvent read FOnActiveChanged write FOnActiveChanged;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsScrollSpy]);
end;

{ TBsScrollSpyItem }

procedure TBsScrollSpyItem.SetTargetControl(AValue: TControl);
begin
  if FTargetControl = AValue then Exit;
  FTargetControl := AValue;
end;

procedure TBsScrollSpyItem.Assign(Source: TPersistent);
begin
  if Source is TBsScrollSpyItem then
  begin
    FTargetControl := TBsScrollSpyItem(Source).TargetControl;
    FNavIndex := TBsScrollSpyItem(Source).NavIndex;
  end
  else
    inherited Assign(Source);
end;

{ TBsScrollSpyItems }

constructor TBsScrollSpyItems.Create(AScrollSpy: TBsScrollSpy);
begin
  inherited Create(TBsScrollSpyItem);
  FScrollSpy := AScrollSpy;
end;

function TBsScrollSpyItems.GetOwner: TPersistent;
begin
  Result := FScrollSpy;
end;

function TBsScrollSpyItems.GetItem(Index: Integer): TBsScrollSpyItem;
begin
  Result := TBsScrollSpyItem(inherited GetItem(Index));
end;

procedure TBsScrollSpyItems.SetItem(Index: Integer; Value: TBsScrollSpyItem);
begin
  inherited SetItem(Index, Value);
end;

{ TBsScrollSpy }

constructor TBsScrollSpy.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TBsScrollSpyItems.Create(Self);
  FOffset := 10;
  FActiveIndex := -1;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 50; // 20 FPS polling untuk performa optimal tanpa lag scroll
  FTimer.OnTimer := @OnCheckScroll;
  FTimer.Enabled := not (csDesigning in ComponentState);
end;

destructor TBsScrollSpy.Destroy;
begin
  FTimer.Free;
  FItems.Free;
  inherited Destroy;
end;

procedure TBsScrollSpy.SetContainer(AValue: TWinControl);
begin
  if FContainer = AValue then Exit;
  FContainer := AValue;
end;

procedure TBsScrollSpy.SetItems(AValue: TBsScrollSpyItems);
begin
  FItems.Assign(AValue);
end;

procedure TBsScrollSpy.SetActiveIndex(AValue: Integer);
begin
  if FActiveIndex = AValue then Exit;
  FActiveIndex := AValue;
  UpdateNavigation;
  if Assigned(FOnActiveChanged) then FOnActiveChanged(Self, FActiveIndex);
end;

procedure TBsScrollSpy.Refresh;
begin
  OnCheckScroll(Self);
end;

procedure TBsScrollSpy.UpdateNavigation;
begin
  if Assigned(FNavTabs) and (FActiveIndex >= 0) then
    FNavTabs.TabIndex := FActiveIndex;

  if Assigned(FListGroup) and (FActiveIndex >= 0) then
    FListGroup.ItemIndex := FActiveIndex;
end;

procedure TBsScrollSpy.OnCheckScroll(Sender: TObject);
var
  i, BestIndex, BestDiff, CurrentDiff: Integer;
  TargetPt, ContainerPt: TPoint;
  Item: TBsScrollSpyItem;
begin
  if not Assigned(FContainer) or (FItems.Count = 0) then Exit;
  if csDesigning in ComponentState then Exit;
  if not FContainer.HandleAllocated then Exit;

  BestIndex := -1;
  BestDiff := Low(Integer); // Cari nilai terdekat dengan Offset tetapi <= Offset

  ContainerPt := FContainer.ClientToScreen(Point(0, 0));

  for i := 0 to FItems.Count - 1 do
  begin
    Item := FItems[i];
    if not Assigned(Item.TargetControl) then Continue;
    if not Item.TargetControl.Visible then Continue;

    // Kalkulasi posisi Y absolut untuk kontrol target relatif terhadap Container
    TargetPt := Item.TargetControl.ClientToScreen(Point(0, 0));
    CurrentDiff := TargetPt.Y - ContainerPt.Y;

    // Jika posisi elemen melewati atau sama dengan batas Offset (dari atas)
    if (CurrentDiff <= FOffset) then
    begin
      // Elemen yang paling mendekati batas atas adalah yang aktif
      if CurrentDiff > BestDiff then
      begin
        BestDiff := CurrentDiff;
        BestIndex := Item.NavIndex;
      end;
    end;
  end;

  // Jika scroll belum mencapai elemen pertama, set indeks ke item pertama (atau -1)
  if (BestIndex = -1) and (FItems.Count > 0) then
  begin
    // Pastikan posisi scroll benar-benar di paling atas
    Item := FItems[0];
    if Assigned(Item.TargetControl) then
    begin
      TargetPt := Item.TargetControl.ClientToScreen(Point(0, 0));
      if (TargetPt.Y - ContainerPt.Y) > FOffset then
        BestIndex := Item.NavIndex;
    end;
  end;

  if (BestIndex <> -1) and (BestIndex <> FActiveIndex) then
    SetActiveIndex(BestIndex);
end;

end.
