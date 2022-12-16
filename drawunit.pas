unit drawunit;

interface

uses SDL2;

const
  TICK_INTERVAL = 100;

  TILE_SIZE = 32;

  WINDOW_WIDTH_TILE_NUMBER = 22;
  WINDOW_HEIGHT_TILE_NUMBER = 16;

  WINDOW_WIDTH = TILE_SIZE * WINDOW_WIDTH_TILE_NUMBER;
  WINDOW_HEIGHT = TILE_SIZE * (WINDOW_HEIGHT_TILE_NUMBER + 1); // +1 for HUD

  PLATEAU_WIDTH_TILE_NUMBER = 40;
  PLATEAU_HEIGHT_TILE_NUMBER = 22;

  PLATEAU_WIDTH = TILE_SIZE * PLATEAU_WIDTH_TILE_NUMBER;
  PLATEAU_HEIGHT = TILE_SIZE * PLATEAU_HEIGHT_TILE_NUMBER;

  GAME_VIEWPORT: TSDL_Rect = (x: 0; y: 0; w: WINDOW_WIDTH; h: WINDOW_HEIGHT);
  HUD_VIEWPORT: TSDL_Rect = (x: 0; y: 0; w: WINDOW_WIDTH; h: TILE_SIZE);
  WINDOW_RECT: TSDL_Rect = (x: 0; y: 0; w: WINDOW_WIDTH; h: WINDOW_HEIGHT);

type
  Point = array [0..1] of Integer;
  Map = Array[1..PLATEAU_HEIGHT_TILE_NUMBER, 1..PLATEAU_WIDTH_TILE_NUMBER] of char;

  Direction = (haut, bas, gauche, droite);

  Tile = record
      rect: TSDL_Rect;
      index: Char;
      fallingDistance : Integer; // for ball & diamonds
      dir : Direction; // for ennemies
  end;

  Plateau = record
      rect: TSDL_Rect;
      cases: Array[1..PLATEAU_HEIGHT_TILE_NUMBER, 1..PLATEAU_WIDTH_TILE_NUMBER] of Tile;
      remainingDiamond : Integer;
      spawnCoord, exitCoord : Point;
      islevelComplete : Boolean;
      name: String;
      timeLeft: Integer;
  end;

procedure initializePlateau(renderer: PSDL_Renderer; var plate: Plateau; level : Integer);
procedure drawPlateau(renderer: PSDL_Renderer; plate: Plateau);
procedure drawGrid(renderer: PSDL_Renderer);
procedure showPlateauText(plate: Plateau);
procedure destroyPlateTextures();

implementation

uses SDL2_image, cameraunit, SysUtils;

var
  strongMur,
  mur,
  terre,
  rien: PSDL_Texture;

  spriteDiamond, spriteStone, spriteExit, spriteEnemy : Array[1..4] of PSDL_Texture;
  spriteDeathStar :  Array[1..2] of PSDL_Texture;

// -------------- LOAD MAP SYSTEM --------------
function loadMapFromFile(filename : String; var plate: Plateau): Map;

var m : Map;
    fichier: Text;
    i, j: Integer;
    ligne: String;

begin
  assign(fichier, filename);
  reset(fichier);

  readln(fichier, plate.name);
  readln(fichier, plate.remainingDiamond);
  readln(fichier, plate.timeLeft);

  for i := 1 to PLATEAU_HEIGHT_TILE_NUMBER do
    begin
     readln(fichier, ligne);
     for j := 1 to PLATEAU_WIDTH_TILE_NUMBER do
       begin
        m[i][j] := ligne[j];

        case ligne[j] of
          'P' :
            begin
             plate.spawnCoord[0] := j;
             plate.spawnCoord[1] := i;
             m[i,j] := 'R'; // replace with recolted when player spawn is read
            end;
          'E':
            begin
             plate.exitCoord[0] := j;
             plate.exitCoord[1] := i;
            end;
        end;
       end;
    end;

  close(fichier);
  loadMapFromFile := m;
end;

// -------------- INITIALIZE MAP SYSTEM --------------
procedure initializeCase(renderer: PSDL_Renderer; var plate: Plateau; level : Integer);

var x, y : Integer;
    t : Tile;
    m : Map;
    spriteIndex : Integer;

begin
  // Load textures & sprites
  if (level = 1) or (level = 5) then
    begin
      if (level = 1) then
        begin
          mur := IMG_LoadTexture(renderer, PChar('images/wall.png'));

          for spriteIndex := 1 to High(spriteDeathStar) do
            spriteDeathStar[spriteIndex] := IMG_LoadTexture(renderer, PChar('images/player/death/anim/star-' + IntToStr(spriteIndex) + '.png'));

          for spriteIndex := 1 to High(spriteDiamond) do
            begin
              spriteDiamond[spriteIndex] := IMG_LoadTexture(renderer, PChar('images/diamond/diamond-' + IntToStr(spriteIndex) + '.png'));
              spriteExit[spriteIndex] := IMG_LoadTexture(renderer, PChar('images/exit/exit-' + IntToStr(spriteIndex) + '.png'));
            end;
        end;

      strongMur := IMG_LoadTexture(renderer, PChar('images/wall/' + IntToStr(level) + '.png'));
      terre := IMG_LoadTexture(renderer, PChar('images/dirt/' + IntToStr(level) + '.png'));
      rien := IMG_LoadTexture(renderer, PChar('images/recolted/' + IntToStr(level) + '.png'));

      for spriteIndex := 1 to High(spriteStone) do
        begin
          spriteStone[spriteIndex] := IMG_LoadTexture(renderer, PChar('images/stone/' + IntToStr(level) + '/stone-' + IntToStr(spriteIndex) + '.png'));
          spriteEnemy[spriteIndex] := IMG_LoadTexture(renderer, PChar('images/enemies/' + IntToStr(level) + '/enemy-' + IntToStr(spriteIndex) + '.png'));
        end;
    end;

  // get file data of the map
  m := loadMapFromFile('maps/map' + IntToStr(level) + '.txt', plate);

  // initialize all the cases
  t.rect.w := TILE_SIZE;
  t.rect.h := TILE_SIZE;
  t.fallingDistance := 0;
  t.dir := gauche;

   for y := Low(plate.cases) to PLATEAU_HEIGHT_TILE_NUMBER do
     for x := Low(plate.cases) to PLATEAU_WIDTH_TILE_NUMBER do
       begin
         t.index := m[y][x];
         t.rect.x := (x-1) * TILE_SIZE;
         t.rect.y := (y-1) * TILE_SIZE;

         plate.cases[y][x] := t;
       end;
end;

procedure initializePlateau(renderer: PSDL_Renderer; var plate: Plateau; level : Integer);
begin
  plate.rect.x := 0;
  plate.rect.y := 0;
  plate.rect.w := PLATEAU_WIDTH;
  plate.rect.h := PLATEAU_HEIGHT;

  plate.islevelComplete := False;
  initializeCase(renderer, plate, level);
end;

// -------------- DRAW SYSTEM --------------
procedure drawPlateau(renderer: PSDL_Renderer; plate: Plateau);

var i, j : Integer;
    texture : PSDL_Texture;
    frame: Integer = 0;

begin
  for i := Low(plate.cases) to PLATEAU_HEIGHT_TILE_NUMBER do
    for j := Low(plate.cases) to PLATEAU_WIDTH_TILE_NUMBER do
      begin
        applyCamera(plate.cases[i][j].rect);
        if SDL_HasIntersection(@plate.cases[i][j].rect, @WINDOW_RECT) = SDL_TRUE then // render only visible tiles
          begin
            case plate.cases[i][j].index of
              'S' : texture := strongMur;
              'M' : texture := mur;
              'T' : texture := terre;
              'R', 'P' : texture := rien;
              'D' :
                begin
                 frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteDiamond);
                 texture := spriteDiamond[frame + 1];
                end;
              'E' :
                begin
                 frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteEnemy);
                 texture := spriteEnemy[frame + 1];
                end;
              'B' :
                begin
                 frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteStone);
                 texture := spriteStone[frame + 1];
                end;
              'X' :
                begin
                 frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteDeathStar);
                 texture := spriteDeathStar[frame + 1];
                end;
              'L' :
                if (plate.isLevelComplete = False) then
                  texture := strongMur
                else
                  begin
                    frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteExit);
                    texture := spriteExit[frame + 1];
                  end;
              else texture := terre;
            end;
            SDL_RenderCopy(renderer, texture, nil, @plate.cases[i][j].rect);
          end;
        end;
end;

procedure drawGrid(renderer: PSDL_Renderer);

var longueur, largeur : Integer;

begin
   SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);

   for longueur := 1 to WINDOW_WIDTH_TILE_NUMBER do
     SDL_RenderDrawLine(renderer, longueur * TILE_SIZE, 0, longueur * TILE_SIZE, WINDOW_HEIGHT);
   for largeur := 1 to WINDOW_HEIGHT_TILE_NUMBER do
     SDL_RenderDrawLine(renderer, 0, largeur * TILE_SIZE, WINDOW_WIDTH, largeur * TILE_SIZE);
end;

procedure showPlateauText(plate: Plateau);

var longueur, largeur : Integer;

begin
  for largeur := 1 to PLATEAU_HEIGHT_TILE_NUMBER do
    begin
     for longueur := 1 to PLATEAU_WIDTH_TILE_NUMBER do
       write(plate.cases[largeur, longueur].index + ' ');
     writeln('');
    end;


end;

// -------------- CLEAR TEXTURES --------------
procedure destroyPlateTextures();

var spriteIndex : Integer;

begin
  SDL_DestroyTexture(strongMur);
  SDL_DestroyTexture(mur);
  SDL_DestroyTexture(terre);
  SDL_DestroyTexture(rien);

  for spriteIndex := 1 to High(spriteDeathStar) do
    SDL_DestroyTexture(spriteDeathStar[spriteIndex]);

  for spriteIndex := 1 to High(spriteDiamond) do
    begin
      SDL_DestroyTexture(spriteDiamond[spriteIndex]);
      SDL_DestroyTexture(spriteExit[spriteIndex]);
    end;

  for spriteIndex := 1 to High(spriteStone) do
    begin
      SDL_DestroyTexture(spriteStone[spriteIndex]);
      SDL_DestroyTexture(spriteEnemy[spriteIndex]);
    end;
end;

end.

