unit hudunit;

interface

uses
  SDL2, SDL2_ttf, SDL2_image, playerunit, drawunit, SysUtils, strUtils;

var
  font : PTTF_Font;
  colorYellow, colorWhite : TSDL_Color;

  // LEVEL & PLAYER INFO
  textureLevelName, texturePlayerLife : PSDL_Texture;
  surfaceLevelName, surfacePlayerLife: PSDL_Surface;
  rectLevelName, rectPlayerLife : TSDL_Rect;

  // HUD
  surfaceTimeText, surfaceDiamondText, surfaceScoreText: PSDL_Surface;
  textureTimeText, textureDiamondText, textureScoreText : PSDL_Texture;
  rectTimeText, rectDiamondText, rectScoreText : TSDL_Rect;

  // BOARD
  textureTimeBoard, textureDiamondBoard, textureScoreBoard : PSDL_Texture;
  rectTimeBoard, rectDiamondBoard, rectScoreBoard : TSDL_Rect;


procedure initializeHUD(renderer: PSDL_Renderer);

procedure drawInfos(renderer: PSDL_Renderer; p: Player; levelName: String);
procedure drawHUD(renderer: PSDL_Renderer; plate: Plateau; p: Player);

implementation

procedure initializeHUD(renderer: PSDL_Renderer);

begin
  // initialization of TrueType font engine
  if TTF_Init = -1 then HALT;

  // load the HUD font
  font := TTF_OpenFont('fonts/hud.ttf', Trunc(TILE_SIZE/1.3333));

  // define the text color by RGB values
  colorYellow.r := 255; colorYellow.g := 255; colorYellow.b := 0;
  colorWhite.r := 255; colorWhite.g := 255; colorWhite.b := 255;

  // initialize level info & player lives
  rectLevelName.x := 0;
  rectLevelName.y := 0;
  rectLevelName.h := TILE_SIZE;

  rectPlayerLife.x := rectLevelName.x + rectLevelName.w;
  rectPlayerLife.y := 0;
  rectPlayerLife.h := TILE_SIZE;

  // initialize HUD
  textureScoreBoard := IMG_LoadTexture(renderer, PChar('images/board/scoreBoard2.png'));
  rectScoreBoard.w := 140;
  rectScoreBoard.h := TILE_SIZE;
  rectScoreBoard.y := TILE_SIZE;
  rectScoreBoard.x := round(WINDOW_WIDTH/2 - rectScoreBoard.w/2);

  rectScoreText.h := rectScoreBoard.h - 10;
  rectScoreText.w := rectScoreBoard.w - 20;
  rectScoreText.y := rectScoreBoard.y + round(rectScoreBoard.h/2) - round(rectScoreText.h/2) - 1;
  rectScoreText.x := rectScoreBoard.x + round(rectScoreBoard.w/2) - round(rectScoreText.w/2) + 2;

  textureDiamondBoard := IMG_LoadTexture(renderer, PChar('images/board/diamondBoard2.png'));
  rectDiamondBoard.w := 106;
  rectDiamondBoard.h := TILE_SIZE;
  rectDiamondBoard.y := 2 * TILE_SIZE;
  rectDiamondBoard.x := 5;

  rectDiamondText.h := rectDiamondBoard.h - 10;
  rectDiamondText.w := rectDiamondBoard.w - 50;
  rectDiamondText.y := rectDiamondBoard.y + round(rectDiamondBoard.h/2) - round(rectDiamondText.h/2) - 1;
  rectDiamondText.x := rectDiamondBoard.x + 40;

  textureTimeBoard := IMG_LoadTexture(renderer, PChar('images/board/timeBoard2.png'));
  rectTimeBoard.w := 106;
  rectTimeBoard.h := TILE_SIZE;
  rectTimeBoard.y := 3 * TILE_SIZE;
  rectTimeBoard.x := 5;

  rectTimeText.h := rectTimeBoard.h - 10;
  rectTimeText.w := rectTimeBoard.w - 50;
  rectTimeText.y := rectTimeBoard.y + round(rectTimeBoard.h/2) - round(rectTimeText.h/2) - 1;
  rectTimeText.x := rectTimeBoard.x + 40;

  SDL_FreeSurface(surfaceLevelName);
end;


procedure drawInfos(renderer: PSDL_Renderer; p: Player; levelName: String);

begin;
  // -- PLAYER LIVES --
  if (p.lives > 1) then
    begin
        surfacePlayerLife := TTF_RenderUTF8_Blended(font, PChar(IntToStr(p.lives) + ' vies'), colorWhite);
        rectPlayerLife.w := Length(IntToStr(p.lives) + ' vies') * TILE_SIZE;
    end
  else
    begin
      surfacePlayerLife := TTF_RenderUTF8_Blended(font, PChar(IntToStr(p.lives) + ' vie'), colorWhite);
      rectPlayerLife.w := Length(IntToStr(p.lives) + ' vie') * TILE_SIZE;
    end;

  texturePlayerLife := SDL_CreateTextureFromSurface(renderer, surfacePlayerLife);

  rectLevelName.x -= TILE_SIZE;
  rectPlayerLife.x -= TILE_SIZE;

  if (rectLevelName.x <=  - rectLevelName.w) then
    rectLevelName.x := WINDOW_WIDTH
  else if (rectPlayerLife.x <=  - rectPlayerLife.w) then
    rectPlayerLife.x := rectLevelName.x + rectLevelName.w;

  // -- LEVEL INFO --
  surfaceLevelName := TTF_RenderUTF8_Blended(font, PChar('Level ' + IntToStr(p.level) + ': ' + levelName + ' / '), colorWhite);
  textureLevelName := SDL_CreateTextureFromSurface(renderer, surfaceLevelName);

  rectLevelName.w := Length('Level ' + IntToStr(p.level) + ': ' + levelName + ' / ') * TILE_SIZE;

  // draw
  SDL_RenderCopy(renderer, textureLevelName, nil, @rectLevelName);
  SDL_RenderCopy(renderer, texturePlayerLife, nil, @rectPlayerLife);

  // avoid memory leak by cleaning memory
  SDL_FreeSurface(surfacePlayerLife);
  SDL_FreeSurface(surfaceLevelName);

  SDL_DestroyTexture(texturePlayerLife);
  SDL_DestroyTexture(textureLevelName);
end;

procedure drawHUD(renderer: PSDL_Renderer; plate: Plateau; p: Player);

begin

  // -- PLAYER SCORE --
  SDL_RenderCopy(renderer, textureScoreBoard, nil, @rectScoreBoard); // draw player score board

  // draw player score text
  surfaceScoreText := TTF_RenderUTF8_Blended(font, PChar(DupeString('0', 6 - Length(intToStr(p.score))) + intToStr(p.score)), colorWhite);
  textureScoreText := SDL_CreateTextureFromSurface(renderer, surfaceScoreText);

  SDL_RenderCopy(renderer, textureScoreText, nil, @rectScoreText);


  // -- REMAINING DIAMOND --
  SDL_RenderCopy(renderer, textureDiamondBoard, nil, @rectDiamondBoard); // draw diamond board

  // draw remaining diamond text
  surfaceDiamondText := TTF_RenderUTF8_Blended(font, PChar(DupeString('0', 3 - Length(intToStr(plate.remainingDiamond))) + intToStr(plate.remainingDiamond)), colorWhite);
  textureDiamondText := SDL_CreateTextureFromSurface(renderer, surfaceDiamondText);

  SDL_RenderCopy(renderer, textureDiamondText, nil, @rectDiamondText);


  // -- TIME LEFT --
  SDL_RenderCopy(renderer, textureTimeBoard, nil, @rectTimeBoard); // draw time board

  // draw remaining time text
  surfaceTimeText := TTF_RenderUTF8_Blended(font, PChar(DupeString('0', 3 - Length(intToStr(plate.timeLeft))) + intToStr(plate.timeLeft)), colorWhite);
  textureTimeText := SDL_CreateTextureFromSurface(renderer, surfaceTimeText);

  SDL_RenderCopy(renderer, textureTimeText, nil, @rectTimeText);

  // avoid memory leak by cleaning memory
  SDL_FreeSurface(surfaceScoreText);
  SDL_FreeSurface(surfaceDiamondText);
  SDL_FreeSurface(surfaceTimeText);

  SDL_DestroyTexture(textureScoreText);
  SDL_DestroyTexture(textureDiamondText);
  SDL_DestroyTexture(textureTimeText);
end;

end.

