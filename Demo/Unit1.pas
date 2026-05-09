unit Unit1;

(*

  DelphiWorlds cross-platform Camera project
  ------------------------------------------

  A (potentially) cross-platform Camera, aimed at supporting newer APIs

  Demo app that does basic preview and capture on face detection

*)

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, Permissions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox, FMX.Memo, FMX.TabControl,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.DialogService,
  FMX.Memo.Types,
  DW.Camera
  ;

type
  TForm1 = class(TForm)
    ButtonsLayout: TLayout;
    StartCameraButton: TButton;
    MemoLayout: TLayout;
    LogMemo: TMemo;
    TabControl: TTabControl;
    PreviewTab: TTabItem;
    CaptureTab: TTabItem;
    CaptureImage: TImage;
    procedure StartCameraButtonClick(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FCamera: TCamera;
    procedure CameraDetectedFacesHandler(Sender: TObject; const AImage: TBitmap; const AFaces: TFacesArray);
    procedure CameraStatusChangeHandler(Sender: TObject);
    procedure DoActualRequest(const APermissions: TArray<string>; const AOnGranted: TProc);
    procedure RequestCameraPermission;
    procedure StartCameraPreview;
  public
    //constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  FMX.Media;  // For TDevicePosition.Front / Back : insted of DW.Camera.Android

const
  cStartCaptions: array[Boolean] of string = ('Start', 'Stop');

{ TForm1 }

// Standardize actual request processing
procedure TForm1.DoActualRequest(const APermissions: TArray<string>; const AOnGranted: TProc);
begin
  PermissionsService.RequestPermissions(APermissions,
    procedure(const APermissions: TClassicStringDynArray;
              const AGrantResults: TClassicPermissionStatusDynArray)
    var
      LGranted: Boolean;
      I: Integer;
    begin
      LGranted := Length(AGrantResults) = Length(APermissions);
      if LGranted then
      begin
        for I := 0 to Length(AGrantResults) - 1 do
        begin
          if AGrantResults[I] <> TPermissionStatus.Granted then
          begin
            LGranted := False;
            Break;
          end;
        end;
      end;

      if LGranted then
      begin
        if Assigned(AOnGranted) then
          AOnGranted;
      end
      else
      begin
        TDialogService.ShowMessage('The CAMERA permission is required to launch the camera.');
      end;
    end);
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  inherited;
  TabControl.ActiveTab := PreviewTab;
  FCamera := TCamera.Create;
  FCamera.FaceDetectMode := TFaceDetectMode.Full;
  FCamera.CameraPosition := TDevicePosition.Front;
  FCamera.OnStatusChange := CameraStatusChangeHandler;
  FCamera.OnDetectedFaces := CameraDetectedFacesHandler;
end;



procedure TForm1.RequestCameraPermission;
var
  Permissions: TArray<string>;
  TargetPermission: string;
begin
  {$IFDEF ANDROID}
  TargetPermission := 'android.permission.CAMERA';
  Permissions := [TargetPermission];

  if PermissionsService.IsPermissionGranted(TargetPermission) then
    StartCameraPreview
  else
    DoActualRequest(Permissions, StartCameraPreview);
  {$ELSE}
  StartCameraPreview;
  {$ENDIF}
end;

procedure TForm1.StartCameraPreview;
begin
  FCamera.PreviewControl.Parent := PreviewTab;
  FCamera.Active := True;
end;

//constructor TForm1.Create(AOwner: TComponent);
//begin
//  inherited;
//  TabControl.ActiveTab := PreviewTab;
//  FCamera := TCamera.Create;
//  FCamera.FaceDetectMode := TFaceDetectMode.Full;
//  FCamera.CameraPosition := TDevicePosition.Front;
//  FCamera.OnStatusChange := CameraStatusChangeHandler;
//  FCamera.OnDetectedFaces := CameraDetectedFacesHandler;
//end;

destructor TForm1.Destroy;
begin
(*  FCamera.Free; *)
  FreeAndNil(FCamera);
  inherited;
end;

procedure TForm1.StartCameraButtonClick(Sender: TObject);
begin
  if FCamera.Active then
  begin
    FCamera.Active := False;
    Exit;
  end;
  RequestCameraPermission;
end;

procedure TForm1.CameraStatusChangeHandler(Sender: TObject);
begin
  if Assigned(FCamera) and Assigned(FCamera.PreviewControl) then
    StartCameraButton.Text := cStartCaptions[FCamera.Active];
end;

procedure TForm1.CameraDetectedFacesHandler(Sender: TObject; const AImage: TBitmap; const AFaces: TFacesArray);
var
  I: Integer;
  LBounds: TRectF;
begin
  for I := 0 to Length(AFaces) - 1 do
  begin
    LBounds := AFaces[I].Bounds;
    LogMemo.Lines.Add(Format('Detected face at: %.0f, %0.f, %0.f, %0.f', [LBounds.Left, LBounds.Top, LBounds.Right, LBounds.Bottom]));
    AImage.Canvas.BeginScene;
    try
      AImage.Canvas.Stroke.Color := TAlphaColorRec.Red;
      AImage.Canvas.Stroke.Thickness := 2;
      AImage.Canvas.DrawEllipse(LBounds, 1);
    finally
      AImage.Canvas.EndScene;
    end;
  end;
  CaptureImage.Bitmap.Assign(AImage);
  TabControl.ActiveTab := CaptureTab;
end;




(*
Crash before Forme Construction  
*)

//procedure TForm1.TabControlChange(Sender: TObject);
//begin
//  // This is necessary because the native preview will otherwise show over the top of the FMX controls
//  FCamera.PreviewControl.Visible := TabControl.ActiveTab = PreviewTab;
//end;

procedure TForm1.TabControlChange(Sender: TObject);
begin
  // This is necessary because the native preview will otherwise show over the top of the FMX controls
  if Assigned(FCamera) and Assigned(FCamera.PreviewControl) then
    FCamera.PreviewControl.Visible := TabControl.ActiveTab = PreviewTab;
end;





end.

