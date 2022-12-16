unit cameraunit;

interface

uses SDL2, drawunit, SysUtils, math;

procedure initCamera(width, height : Integer);
procedure applyCamera(var entityRect : TSDL_Rect);
procedure updateCamera(targetRect : TSDL_Rect);

implementation

var
  cam_width, cam_height : Integer;
  camera : TSDL_Rect;

const
  CAM_OFFSET = 2;

procedure initCamera(width, height : Integer);

begin
  camera.x := 0;
  camera.y := 0;
  camera.w := width;
  camera.h := height;

  cam_width := width;
  cam_height := height;
end;

procedure applyCamera(var entityRect : TSDL_Rect);

begin
  entityRect.x += camera.x;
  entityRect.y += camera.y;
end;

procedure updateCamera(targetRect : TSDL_Rect);

var x, y : Integer;

begin
  x := - targetRect.x + trunc(WINDOW_WIDTH_TILE_NUMBER/2) * 32;
  y := - targetRect.y + trunc(WINDOW_HEIGHT_TILE_NUMBER/2) * 32;

  // limit scrolling to map size
  x := min(0 + CAM_OFFSET * TILE_SIZE, x);  // left
  y := min(0 + CAM_OFFSET * TILE_SIZE, y);  // top
  x := max(-(cam_width - WINDOW_WIDTH + TILE_SIZE), x);  // right
  y := max(-(cam_height - WINDOW_HEIGHT + TILE_SIZE), y);  // bottom


  writeln(IntToStr(x));

  camera.x := x;
  camera.y := y;
end;

end.

