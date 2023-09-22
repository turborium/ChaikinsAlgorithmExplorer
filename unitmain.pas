// 2023-2023 Turborium(c)
unit UnitMain;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Types, Math;

type

  { TFormMain }

  TFormMain = class(TForm)
    BevelC1: TBevel;
    BevelVert: TBevel;
    BevelA: TBevel;
    BevelB: TBevel;
    BevelC: TBevel;
    BevelD: TBevel;
    CheckBoxDrawNewPoints: TCheckBox;
    CheckBoxClosedPath: TCheckBox;
    LabelInfo: TLabel;
    LabelDivisionsCount: TLabel;
    LabelProportions: TLabel;
    LabelHelp: TLabel;
    LabelAbout: TLabel;
    PaintBox: TPaintBox;
    PanelParams: TPanel;
    TrackBarDivisionCount: TTrackBar;
    TrackBarProportion: TTrackBar;
    procedure CheckBoxClosedPathChange(Sender: TObject);
    procedure CheckBoxDrawNewPointsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PaintBoxChangeBounds(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxResize(Sender: TObject);
    procedure TrackBarDivisionCountChange(Sender: TObject);
    procedure TrackBarProportionChange(Sender: TObject);
  private const
    GripPointRadius = 8;
    MaxPoints = 20;
  private
    IsFirstShow: Boolean;
    Points: TArray<TPointF>;
    NewPoints: TArray<TPointF>;
    CapturedPoint: Integer;
    OldSize: TSize;
    procedure UpdateAll();
    procedure UpdateInfo();
    procedure FixPointPositions();
  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

function ChaikinPoints(Points: TArray<TPointF>; Closed: Boolean; Proportions: Single = 0.25): TArray<TPointF>;
var
  I: Integer;
  C1, C2: Single;
begin
  C1 := 1.0 - Proportions;
  C2 := Proportions;

  Result := [];

  if Closed then
  begin
    for I := 0 to High(Points) do
    begin
      Result := Result + [TPointF.Create(
        (Points[I].X * C1 + Points[(I + 1) mod Length(Points)].X * C2),
        (Points[I].Y * C1 + Points[(I + 1) mod Length(Points)].Y * C2)
      )];
      Result := Result + [TPointF.Create(
        (Points[I].X * C2 + Points[(I + 1) mod Length(Points)].X * C1),
        (Points[I].Y * C2 + Points[(I + 1) mod Length(Points)].Y * C1)
      )];
    end;
  end else
  begin
    Result := Result + [TPointF.Create(
      Points[0].X,
      Points[0].Y
    )];
    for I := 0 to High(Points) - 1 do
    begin
      Result := Result + [TPointF.Create(
        (Points[I].X * C1 + Points[I + 1].X * C2),
        (Points[I].Y * C1 + Points[I + 1].Y * C2)
      )];
      Result := Result + [TPointF.Create(
        (Points[I].X * C2 + Points[I + 1].X * C1),
        (Points[I].Y * C2 + Points[I + 1].Y * C1)
      )];
    end;
    Result := Result + [TPointF.Create(
      Points[High(Points)].X,
      Points[High(Points)].Y
    )];
  end;
end;

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  IsFirstShow := True;
  Points := [];
  CapturedPoint := -1;
end;

procedure TFormMain.CheckBoxClosedPathChange(Sender: TObject);
begin
  UpdateAll();
end;

procedure TFormMain.CheckBoxDrawNewPointsChange(Sender: TObject);
begin
  UpdateAll();
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  if not IsFirstShow then
    exit;

  IsFirstShow := False;

  Points := [
    TPointF.Create(10, 10),
    TPointF.Create(10 + PaintBox.Width / 3, 10 + PaintBox.Height / 5),
    TPointF.Create(2 * PaintBox.Width / 3 - 10, 4 * PaintBox.Height / 5 - 10),
    TPointF.Create(PaintBox.Width - 10, PaintBox.Height - 10)
  ];

  OldSize := TSize.Create(PaintBox.Width, PaintBox.Height);
  UpdateAll();
end;

procedure TFormMain.PaintBoxChangeBounds(Sender: TObject);
var
  I: Integer;
begin
  if IsFirstShow then
    exit;

  for I := 0 to High(Points) do
  begin
    Points[I].X := Points[I].X * PaintBox.Width / OldSize.Width;
    Points[I].Y := Points[I].Y * PaintBox.Height / OldSize.Height;
  end;
  OldSize := TSize.Create(PaintBox.Width, PaintBox.Height);
  UpdateAll();
end;

procedure TFormMain.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  for I := 0 to High(Points) do
  begin
    if (X >= Points[I].X - GripPointRadius) and (X <= Points[I].X + GripPointRadius) and
       (Y >= Points[I].Y - GripPointRadius) and (Y <= Points[I].Y + GripPointRadius) then
      CapturedPoint := I;
    UpdateAll();
  end;
end;

procedure TFormMain.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if CapturedPoint <> -1 then
  begin
    Points[CapturedPoint].X := X;
    Points[CapturedPoint].Y := Y;
    FixPointPositions();
    UpdateAll();
  end;
end;

procedure TFormMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Origin, Next, Prev: TPointF;
  A, B: TPointF;
begin
  if (CapturedPoint <> -1) then
  begin
    // new point
    if (Button = mbRight) and not (ssShift in Shift) and (Length(Points) < MaxPoints) then
    begin
      Origin := Points[CapturedPoint];
      Prev := Points[(CapturedPoint + Length(Points) - 1) mod Length(Points)];
      Next := Points[(CapturedPoint + 1) mod Length(Points)];

      A.X := Origin.X * 4/5 + Prev.X * 1/5;
      A.Y := Origin.Y * 4/5 + Prev.Y * 1/5;
      B.X := Origin.X * 4/5 + Next.X * 1/5;
      B.Y := Origin.Y * 4/5 + Next.Y * 1/5;

      Points[CapturedPoint] := B;
      Insert(A, Points, CapturedPoint);
    end;

    // delete point
    if (Button = mbMiddle) or ((Button = mbRight) and (ssShift in Shift)) and (Length(Points) > 3) then
    begin
      Delete(Points, CapturedPoint, 1);
    end;

    CapturedPoint := -1;

    UpdateAll();
  end;
end;

procedure TFormMain.PaintBoxPaint(Sender: TObject);
const
  BackgroundColor = $EEEEEE;
  BaseLineColor = clGray;
  LineWidth = 2;
  LineColor = clBlack;
  GripPenColor = clMaroon;
  GripBrushColor = clRed;
  PointRadius = 4;
  PointBrushColor = clFuchsia;
var
  I: Integer;
begin
  // clear
  PaintBox.Canvas.Brush.Color := BackgroundColor;
  PaintBox.Canvas.FillRect(PaintBox.BoundsRect);

  // draw base lines
  PaintBox.Canvas.Pen.Color := BaseLineColor;
  PaintBox.Canvas.Pen.Style := psDash;
  PaintBox.Canvas.Pen.Width := 1;
  PaintBox.Canvas.MoveTo(Trunc(Points[0].X), Trunc(Points[0].Y));
  for I := 1 to High(Points) do
    PaintBox.Canvas.LineTo(Trunc(Points[I].X), Trunc(Points[I].Y));
  if CheckBoxClosedPath.Checked then
    PaintBox.Canvas.LineTo(Trunc(Points[0].X), Trunc(Points[0].Y));

  // draw lines
  PaintBox.Canvas.Pen.Color := LineColor;
  PaintBox.Canvas.Pen.Width := LineWidth;
  PaintBox.Canvas.Pen.Style := psSolid;
  PaintBox.Canvas.MoveTo(Trunc(NewPoints[0].X), Trunc(NewPoints[0].Y));
  for I := 1 to High(NewPoints) do
    PaintBox.Canvas.LineTo(Trunc(NewPoints[I].X), Trunc(NewPoints[I].Y));
  if CheckBoxClosedPath.Checked then
    PaintBox.Canvas.LineTo(Trunc(NewPoints[0].X), Trunc(NewPoints[0].Y));

  // draw points
  if CheckBoxDrawNewPoints.Checked then
  begin
    PaintBox.Canvas.Pen.Style := psClear;
    PaintBox.Canvas.Brush.Color := PointBrushColor;
    for I := 0 to High(NewPoints) do
      PaintBox.Canvas.EllipseC(Trunc(NewPoints[I].X), Trunc(NewPoints[I].Y), PointRadius, PointRadius);
  end;

  // draw grip points
  PaintBox.Canvas.Pen.Style := psSolid;
  PaintBox.Canvas.Pen.Width := 1;
  PaintBox.Canvas.Pen.Color := GripPenColor;
  PaintBox.Canvas.Brush.Color := GripBrushColor;
  for I := 0 to High(Points) do
    PaintBox.Canvas.EllipseC(Trunc(Points[I].X), Trunc(Points[I].Y), GripPointRadius, GripPointRadius);
end;

procedure TFormMain.PaintBoxResize(Sender: TObject);
begin

end;

procedure TFormMain.TrackBarDivisionCountChange(Sender: TObject);
begin
  UpdateAll();
end;

procedure TFormMain.TrackBarProportionChange(Sender: TObject);
begin
  UpdateAll();
end;

procedure TFormMain.UpdateAll();
var
  I: Integer;
begin
  NewPoints := Points;
  for I := 0 to TrackBarDivisionCount.Position - 1 do
  begin
    NewPoints := ChaikinPoints(NewPoints, CheckBoxClosedPath.Checked, TrackBarProportion.Position / 100);
  end;

  PaintBox.Invalidate();
  UpdateInfo();
end;

procedure TFormMain.UpdateInfo();
begin
  LabelDivisionsCount.Caption := 'Division Count: ' + IntToStr(TrackBarDivisionCount.Position);
  LabelProportions.Caption := 'Proportion: ' + FloatToStrF(TrackBarProportion.Position / 100.0, TFloatFormat.ffGeneral, 2, 0);
  LabelInfo.Caption := Format('Point Count: %d'#10'Line Count: %d',
    [Length(Points), IfThen(CheckBoxClosedPath.Checked, Length(NewPoints), Length(NewPoints) - 1)]);
end;

procedure TFormMain.FixPointPositions();
var
  I: Integer;
begin
  for I := 0 to High(Points) do
  begin
    Points[CapturedPoint].X := EnsureRange(Points[CapturedPoint].X, 0, PaintBox.Width);
    Points[CapturedPoint].Y := EnsureRange(Points[CapturedPoint].Y, 0, PaintBox.Height);
  end;
end;

initialization
  DefaultFormatSettings.DecimalSeparator := '.';
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
    exOverflow, exUnderflow, exPrecision]);

end.

