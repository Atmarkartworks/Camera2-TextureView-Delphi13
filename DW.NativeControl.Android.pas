unit DW.NativeControl.Android;

{$I DW.GlobalDefines.inc}

interface

uses
  // RTL
  System.Types, System.Classes,
  // Android
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Widget,
  // FMX
  FMX.Controls;

type
  TNativeControl = class(TControl)
  private
    FBounds: TRect;
    FNativeLayout: JFrameLayout;
    FNativeLayoutParams: JFrameLayout_LayoutParams;
    FRootView: JViewGroup;
    FScale: Single;
    procedure DoHide;
    procedure DoResize;
    procedure DoShow;
    procedure FinaliseLayout;
    procedure Initialise;
    procedure InitialiseLayout;
    procedure UpdateBounds;
    function GetNativeControl: Pointer;
  protected
    FNativeControl: JView;
    function CreateNativeControl: JView; virtual;
    function GetIsVisible: Boolean;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Hide; override;
    procedure Show; override;
    property NativeControl: Pointer read GetNativeControl;
  end;

implementation

uses
  // RTL
  System.SysUtils,
  // Android
  Androidapi.Helpers, Androidapi.JNIBridge, Androidapi.JNI.App,
  // FMX
  FMX.Helpers.Android, FMX.Types, FMX.Forms, FMX.Platform, FMX.Platform.Android;

type
  TOpenControl = class(TControl);

{ TNativeControl }

constructor TNativeControl.Create(AOwner: TComponent);
begin
  inherited;
  Initialise;
end;

destructor TNativeControl.Destroy;
begin
  if (FNativeControl <> nil) and (FNativeLayout <> nil) then
    CallInUIThreadAndWaitFinishing(FinaliseLayout);
  inherited;
end;

procedure TNativeControl.FinaliseLayout;
begin
  if FNativeControl <> nil then
    FNativeControl.setVisibility(TJView.JavaClass.INVISIBLE);
  if (FNativeLayout <> nil) and (FNativeControl <> nil) then
    FNativeLayout.removeView(FNativeControl);
  if (FRootView <> nil) and (FNativeLayout <> nil) then
    FRootView.removeView(FNativeLayout);
end;

function TNativeControl.CreateNativeControl: JView;
begin
  Result := nil;
end;

procedure TNativeControl.Initialise;
var
  LScreenService: IFMXScreenService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXScreenService, LScreenService) then
    FScale := LScreenService.GetScreenScale
  else
    FScale := 1;
  CallInUIThreadAndWaitFinishing(InitialiseLayout);
end;

procedure TNativeControl.InitialiseLayout;
var
  LRootLayoutParams: JViewGroup_LayoutParams;
begin
  FNativeControl := CreateNativeControl;
  if FNativeControl <> nil then
  begin
    FNativeLayout := TJFrameLayout.JavaClass.init(TAndroidHelper.Activity);
    FRootView := TJViewGroup.Wrap((MainActivity.getWindow.getDecorView as ILocalObject).GetObjectID);
    if FRootView <> nil then
    begin
      LRootLayoutParams := TJViewGroup_LayoutParams.JavaClass.init(
        TJViewGroup_LayoutParams.JavaClass.MATCH_PARENT,
        TJViewGroup_LayoutParams.JavaClass.MATCH_PARENT
      );
      FRootView.addView(FNativeLayout, LRootLayoutParams);
      FNativeLayoutParams := TJFrameLayout_LayoutParams.JavaClass.init(1, 1);
      FNativeLayout.addView(FNativeControl, FNativeLayoutParams);
    end;
  end;
end;

procedure TNativeControl.UpdateBounds;
var
  LPoint: TPointF;
  LControl: IControl;
begin
  if Parent is TCommonCustomForm then
    LPoint := Position.Point
  else if Supports(ParentControl, IControl, LControl) then
    LPoint := LControl.LocalToScreen(Position.Point)
  else
    Exit; // <======
  FBounds := Rect(Round(LPoint.X * FScale), Round(LPoint.Y * FScale), Round(Width * FScale), Round(Height * FScale));
end;

procedure TNativeControl.DoResize;
begin
  if (FNativeControl = nil) or (FNativeLayoutParams = nil) then
    Exit;
  UpdateBounds;
  FNativeLayoutParams.width := FBounds.Right;
  FNativeLayoutParams.height := FBounds.Bottom;
  FNativeControl.setLayoutParams(FNativeLayoutParams);
  FNativeControl.setX(FBounds.Left);
  FNativeControl.setY(FBounds.Top);
end;

procedure TNativeControl.Resize;
begin
  inherited;
  CallInUIThread(DoResize);
end;

function TNativeControl.GetIsVisible: Boolean;
begin
  Result := (FNativeControl <> nil) and (FNativeControl.getVisibility = TJView.JavaClass.VISIBLE);
end;

function TNativeControl.GetNativeControl: Pointer;
begin
  Result := FNativeControl;
end;

procedure TNativeControl.DoHide;
begin
  if (FNativeControl <> nil) and (FNativeControl.getVisibility <> TJView.JavaClass.INVISIBLE) then
    FNativeControl.setVisibility(TJView.JavaClass.INVISIBLE);
end;

procedure TNativeControl.Hide;
begin
  inherited;
  CallInUIThread(DoHide);
end;

procedure TNativeControl.DoShow;
begin
  if (FNativeControl <> nil) and (FNativeControl.getVisibility <> TJView.JavaClass.VISIBLE) then
  begin
    DoResize;
    FNativeControl.setVisibility(TJView.JavaClass.VISIBLE);
  end;
end;

procedure TNativeControl.Show;
begin
  inherited;
  CallInUIThread(DoShow);
end;

end.