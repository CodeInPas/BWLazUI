unit bscollapse;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Math, Graphics;

type
  { TBsCollapse: Panel kontainer yang dapat diperluas/disusutkan dengan animasi }
  TBsCollapse = class(TCustomPanel)
  private
    FExpanded: Boolean;
    FAnimated: Boolean;
    FExpandedHeight: Integer;
    FTimer: TTimer;
    FAnimationSpeed: Integer;

    FOnExpand: TNotifyEvent;
    FOnCollapse: TNotifyEvent;

    procedure SetExpanded(AValue: Boolean);
    procedure SetAnimated(AValue: Boolean);
    procedure SetExpandedHeight(AValue: Integer);

    procedure OnTimerTick(Sender: TObject);
  protected
    procedure Resize; override;
    procedure DoExpand; virtual;
    procedure DoCollapse; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Toggle;
  published
    property Expanded: Boolean read FExpanded write SetExpanded default True;
    property Animated: Boolean read FAnimated write SetAnimated default True;
    property ExpandedHeight: Integer read FExpandedHeight write SetExpandedHeight;
    property AnimationSpeed: Integer read FAnimationSpeed write FAnimationSpeed default 15; // Kecepatan pixel per tick

    { Properti Bawaan TCustomPanel }
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
    property Font;
    property ParentBackground default False;
    property ParentColor default False;
    property ParentFont;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;

    { Events }
    property OnExpand: TNotifyEvent read FOnExpand write FOnExpand;
    property OnCollapse: TNotifyEvent read FOnCollapse write FOnCollapse;
    property OnResize;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsCollapse]);
end;

{ TBsCollapse }

constructor TBsCollapse.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];

  BevelInner := bvNone;
  BevelOuter := bvNone;
  Color := clWindow;

  Width := 300;
  Height := 150;

  FExpanded := True;
  FAnimated := True;
  FExpandedHeight := 150;
  FAnimationSpeed := 15;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 16; // ~60 FPS
  FTimer.Enabled := False;
  FTimer.OnTimer := @OnTimerTick;
end;

destructor TBsCollapse.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TBsCollapse.SetExpanded(AValue: Boolean);
begin
  if FExpanded = AValue then Exit;
  FExpanded := AValue;

  if (csDesigning in ComponentState) or not FAnimated then
  begin
    if FExpanded then
    begin
      Height := FExpandedHeight;
      Visible := True;
      DoExpand;
    end
    else
    begin
      Height := 0;
      Visible := False;
      DoCollapse;
    end;
  end
  else
  begin
    if FExpanded then Visible := True; // Pastikan terlihat sebelum animasi mulai
    FTimer.Enabled := True;
  end;
end;

procedure TBsCollapse.SetAnimated(AValue: Boolean);
begin
  FAnimated := AValue;
end;

procedure TBsCollapse.SetExpandedHeight(AValue: Integer);
begin
  if FExpandedHeight = AValue then Exit;
  FExpandedHeight := AValue;
  if FExpanded and not FTimer.Enabled then Height := FExpandedHeight;
end;

procedure TBsCollapse.Toggle;
begin
  SetExpanded(not FExpanded);
end;

procedure TBsCollapse.Resize;
begin
  inherited Resize;
  if FExpanded and not FTimer.Enabled and not (csLoading in ComponentState) then
    FExpandedHeight := Height;
end;

procedure TBsCollapse.DoExpand;
begin
  if Assigned(FOnExpand) then FOnExpand(Self);
end;

procedure TBsCollapse.DoCollapse;
begin
  if Assigned(FOnCollapse) then FOnCollapse(Self);
end;

procedure TBsCollapse.OnTimerTick(Sender: TObject);
var
  NewHeight: Integer;
begin
  if FExpanded then
  begin
    // Animasi Perluas
    NewHeight := Height + FAnimationSpeed;
    if NewHeight >= FExpandedHeight then
    begin
      Height := FExpandedHeight;
      FTimer.Enabled := False;
      DoExpand;
    end
    else
      Height := NewHeight;
  end
  else
  begin
    // Animasi Susut
    NewHeight := Height - FAnimationSpeed;
    if NewHeight <= 0 then
    begin
      Height := 0;
      FTimer.Enabled := False;
      Visible := False; // Sembunyikan sepenuhnya jika tinggi 0
      DoCollapse;
    end
    else
      Height := NewHeight;
  end;
end;

end.
