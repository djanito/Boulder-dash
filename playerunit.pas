unit playerunit;

interface

uses SDL2, SDL2_image, drawunit, SysUtils, cameraunit;

type
  Player = record
      texture: PSDL_Texture;
      rect: TSDL_Rect;
      relPosition, absPosition : Point;
      score: Integer;
      lives: Integer;
      isDeath : Boolean;
      diamond: Integer;
      level : Integer;
      isOnExit : Boolean;
  end;

const
  POUSSE_BOULE_TIME = 300;


var
  spriteLeft, spriteRight : Array[1..3] of PSDL_Texture;
  spriteDown, spriteUp : Array[1..4] of PSDL_Texture;
  spriteWin, spriteDeath, spriteStanding : Array[1..2] of PSDL_Texture;

  pousseBouleTimer : Integer = 0;

  isPlayerDescending : Boolean = False;
  deathFadeRect : TSDL_Rect;
  alphaFadeValue : Integer = 255;
  isLevelTransition : Boolean = False;
  stopStarAnim : Boolean = False;

procedure initializePlayer(renderer: PSDL_Renderer; var p: Player; plate: Plateau);
procedure handlePlayerMovement(sdlKeyboardState: PUInt8; var p: Player; var plate: Plateau);
procedure drawPlayer(renderer: PSDL_Renderer; var p: Player);
procedure checkLevelFinish(renderer: PSDL_Renderer; var p: Player; var plate: Plateau);
procedure checkPlayerDeath(renderer: PSDL_Renderer; var p: Player; var plate: Plateau);

implementation

// -------------- INITIALIZE SYSTEM --------------
procedure initializePlayerPosition(var p: Player; plate: Plateau);

begin
  // initial abs & rel player position
  p.absPosition := plate.spawnCoord;
  p.relPosition := plate.spawnCoord;
end;

procedure initializeSprite(renderer: PSDL_Renderer);

var i: Integer;

begin
   for i:= 1 to High(spriteLeft) do
     begin
       spriteLeft[i] := IMG_LoadTexture(renderer, PChar('images/player/left/left-' + IntToStr(i) + '.png'));
       spriteRight[i] := IMG_LoadTexture(renderer, PChar('images/player/right/right-' + IntToStr(i) + '.png'));
     end;

   for i:= 1 to High(spriteDown) do
     begin
       spriteDown[i] := IMG_LoadTexture(renderer, PChar('images/player/down/down-' + IntToStr(i) + '.png'));
       spriteUp[i] := IMG_LoadTexture(renderer, PChar('images/player/up/up-' + IntToStr(i) + '.png'));
     end;

   for i:= 1 to High(spriteWin) do
     begin
       spriteWin[i] := IMG_LoadTexture(renderer, PChar('images/player/win/win-' + IntToStr(i) + '.png'));
       spriteDeath[i] := IMG_LoadTexture(renderer, PChar('images/player/death/death-' + IntToStr(i) + '.png'));
       spriteStanding[i] := IMG_LoadTexture(renderer, PChar('images/player/standing/standing-' + IntToStr(i) + '.png'));
     end;
end;

procedure initializePlayer(renderer: PSDL_Renderer; var p: Player; plate: Plateau);

begin
  // load textures
  initializeSprite(renderer);

  with p do
    begin
      initializePlayerPosition(p, plate);

      // initialize player rect
      rect.w := TILE_SIZE;
      rect.h := TILE_SIZE;

      // others attributes
      level := 1;
      lives := 3;
      score := 0;
      diamond := 0;
      isOnExit := False;
      isDeath := False;
    end;
end;


// -------------- UPDATE SYSTEM --------------
procedure updatePlayer(var p : Player; var plate: Plateau);

begin
  p.diamond += 1;

  if (plate.remainingDiamond > 0) then
    begin
     plate.remainingDiamond -= 1;
     p.score += 10;
    end
  else
    p.score += 15;

  if (plate.remainingDiamond = 0) then
    plate.isLevelComplete := True;
end;

procedure animatePlayer(var p: Player; xInc, yInc : Integer);

var frame: Integer;

begin
  if (p.isOnExit) then
    begin
      frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteWin);
      p.texture := spriteWin[frame + 1];
    end
  else if (p.isDeath) then
    begin
      frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteDeath);
      p.texture := spriteDeath[frame + 1];
    end
  else
    if (yInc = -1) then
      begin
       frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteUp);
       p.texture := spriteUp[frame + 1];
      end
    else if (yInc = 1) then
      begin
        frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteDown);
        p.texture := spriteDown[frame + 1];
      end
    else if (xInc = -1) then
      begin
        frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteLeft);
        p.texture := spriteLeft[frame + 1];
      end
    else if (xInc = 1) then
      begin
        frame := round(SDL_GetTicks() / TICK_INTERVAL) MOD High(spriteRight);
        p.texture := spriteRight[frame + 1];
      end
    else
      begin
       frame := round(SDL_GetTicks() / 400) MOD High(spriteStanding);
       p.texture := spriteStanding[frame + 1];
      end;
end;


// -------------- DEPLACMENT SYSTEM --------------
function canPlayerMove(plate: Plateau; var p: Player; xInc, yInc : Integer): Boolean;

begin
  if (plate.cases[p.absPosition[1] + yInc,  p.absPosition[0] + xInc].index = 'M') or (plate.cases[p.absPosition[1] + yInc,  p.absPosition[0] + xInc].index = 'S') then
    canPlayerMove := false
  else if (plate.cases[p.absPosition[1] + yInc, p.absPosition[0] + xInc].index = 'B') then
    begin
      pousseBouleTimer += TICK_INTERVAL; // add delay to move a ball
      canPlayerMove := false;
      if (pousseBouleTimer >= POUSSE_BOULE_TIME) then
        begin
          canPlayerMove := not ((plate.cases[p.absPosition[1] + 2 * yInc, p.absPosition[0] + 2 * xInc].index <> 'R') or (yInc <> 0));
          pousseBouleTimer := 0;
        end;
    end
  else if (plate.cases[p.absPosition[1] + yInc, p.absPosition[0] + xInc].index = 'L') and not plate.isLevelComplete then
     canPlayerMove := false
  else
    canPlayerMove := true;
end;

procedure checkCollisions(var plate: Plateau; var p: Player; xInc: Integer);

begin
  if (plate.cases[p.absPosition[1], p.absPosition[0]].index = 'B') then
    plate.cases[p.absPosition[1],  p.absPosition[0] + xInc].index := 'B' // move the boule of one case
  else if (plate.cases[p.absPosition[1],  p.absPosition[0]].index = 'D') then
    updatePlayer(p, plate)
  else if (plate.cases[p.absPosition[1],  p.absPosition[0]].index = 'L') then
    if (plate.islevelComplete) then
      p.isOnExit := True;

  if (plate.cases[p.absPosition[1],  p.absPosition[0]].index <> 'E') then
    plate.cases[p.absPosition[1],  p.absPosition[0]].index := 'R';
end;

procedure creuser(var plate: Plateau; var p: Player; dirX, dirY: Integer);

begin
  if (plate.cases[p.absPosition[1] + dirY, p.absPosition[0] + dirX].index = 'T') then
    plate.cases[p.absPosition[1] + dirY, p.absPosition[0] + dirX].index := 'R'
  else if (plate.cases[p.absPosition[1] + dirY, p.absPosition[0] + dirX].index = 'D') then
    begin
     plate.cases[p.absPosition[1] + dirY, p.absPosition[0] + dirX].index := 'R';
     updatePlayer(p, plate);
    end;
end;

procedure handlePlayerMovement(sdlKeyboardState: PUInt8; var p: Player; var plate: Plateau);

var
  xInc : Integer = 0;
  yInc : Integer = 0;

begin
  SDL_PumpEvents;

  if not p.isOnExit and not p.isDeath then  // if player has not completed the game
    begin
     if (sdlKeyboardState[SDL_SCANCODE_LCTRL] = 1) and (sdlKeyboardState[SDL_SCANCODE_W] = 1) then // DIG UP
       creuser(plate, p, 0, -1)
     else if (sdlKeyboardState[SDL_SCANCODE_LCTRL] = 1) and (sdlKeyboardState[SDL_SCANCODE_A] = 1) then // DIG LEFT
       creuser(plate, p, -1, 0)
     else if (sdlKeyboardState[SDL_SCANCODE_LCTRL] = 1) and (sdlKeyboardState[SDL_SCANCODE_S] = 1) then // DIG DOWN
       creuser(plate, p, 0, 1)
     else if (sdlKeyboardState[SDL_SCANCODE_LCTRL] = 1) and (sdlKeyboardState[SDL_SCANCODE_D] = 1) then // DIG RIGHT
       creuser(plate, p, 1, 0)
     else if sdlKeyboardState[SDL_SCANCODE_W] = 1 then // UP KEY PRESS
       yInc := -1
     else if sdlKeyboardState[SDL_SCANCODE_A] = 1 then // LEFT KEY PRESS
       xInc := -1
     else if sdlKeyboardState[SDL_SCANCODE_S] = 1 then // DOWN KEY PRESS
       yInc := 1
     else if sdlKeyboardState[SDL_SCANCODE_D] = 1 then // RIGHT KEY PRESS
       xInc := 1;

     if (xInc = 0) and (yInc = 0) then // if player is static
       pousseBouleTimer := 0 // reset ball pousse timer
     else // if player want to move
       if canPlayerMove(plate, p, xInc, yInc) then // if player can move
         begin
           p.absPosition[0] += xInc;
           p.relPosition[0] += xInc;
           p.absPosition[1] += yInc;
           p.relPosition[1] += yInc;

           checkCollisions(plate, p, xInc); // check for collisions
         end;
    end;

    // add the correct texture to the player
    animatePlayer(p, xInc, yInc);
end;


// -------------- DEATH SYSTEM --------------
procedure retryLevel(renderer: PSDL_Renderer; var p: Player; var plate: Plateau);

begin
  // draw the fade-out to the screen
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, alphaFadeValue);
  SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
  SDL_RenderFillRect(renderer, nil);

  if (alphaFadeValue = 255) then
    begin
      if (p.lives = 1) then // when player has lost his 3 lives
        initializePlateau(renderer, plate, 1) // go back to level 1
      else // if player lose a life
        begin
          initializePlateau(renderer, plate, p.level);
          initializePlayerPosition(p, plate);
        end;
      p.lives -= 1;
      stopStarAnim := true;
    end
  else if (alphaFadeValue = 0) then
    begin
      alphaFadeValue := 255 + 51;
      p.isDeath := false;
      isPlayerDescending := false;
      stopStarAnim := true;

      if (p.lives = 0) then
        initializePlayer(renderer, p, plate); // reinitialize player
    end;

  alphaFadeValue -= 51; // decrease the fade out
end;

procedure checkPlayerDeath(renderer: PSDL_Renderer; var p: Player; var plate: Plateau);

var i, j: Integer;

begin

  if (p.isDeath) then
    begin
      if isPlayerDescending then
        p.rect.y += 40
      else
        p.rect.y -= 40;

      if (p.rect.y < (p.relPosition[1]-3)*TILE_SIZE) then
        isPlayerDescending := True
      else if (p.rect.y >= WINDOW_HEIGHT) then // when player disappear from screen
        retryLevel(renderer, p, plate);

      if not (stopStarAnim) then
        for i := p.absPosition[1] -1 to p.absPosition[1] + 1 do
          for j := p.absPosition[0] -1 to p.absPosition[0] + 1 do
            plate.cases[i, j].index := 'X';
    end
  else if (plate.cases[p.absPosition[1], p.absPosition[0]].index = 'B') or
       (plate.cases[p.absPosition[1], p.absPosition[0]].index = 'D') or
       ((plate.timeLeft = 0) and not (p.isOnExit)) or
       (plate.cases[p.absPosition[1], p.absPosition[0]].index = 'E') then
    begin
      p.isDeath := true;
      stopStarAnim := false;
    end
end;


// -------------- CHANGE LEVEL SYSTEM --------------
procedure changeLevel(renderer: PSDL_Renderer; var p: Player; var plate: Plateau);

begin
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, alphaFadeValue);
  SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
  SDL_RenderFillRect(renderer, nil);

  if (alphaFadeValue = 255) then
    begin  // CHANGE MAP AND RESET ATTRIBUTES
     p.level += 1;
     initializePlateau(renderer, plate, p.level);
     initializePlayerPosition(p, plate);

     p.diamond := 0;
     p.isOnExit := False;
    end
  else if (alphaFadeValue = 0) then
    begin
      isLevelTransition := False;
      alphaFadeValue := 255 + 51;
    end;

  alphaFadeValue -= 51; // decrease the fade out
end;

procedure checkLevelFinish(renderer: PSDL_Renderer; var p: Player; var plate: Plateau);

begin
  if (isLevelTransition) then
    changeLevel(renderer, p, plate)
  else
    if (p.isOnExit) then
      begin
        // INCREASE THE SCORE OF PLAYER BY TIME LEFT
        if (plate.timeLeft >= 5) then
          begin
            plate.timeLeft -= 5;
            p.score += 5;
          end
        else
          begin
           p.score += plate.timeLeft;
           plate.timeLeft := 0;
           isLevelTransition := True;
          end;
      end;
end;

procedure drawPlayer(renderer: PSDL_Renderer; var p: Player);

begin
  if not (p.isDeath) then
    applyCamera(p.rect);

  SDL_RenderCopy(renderer, p.texture, nil, @p.rect);
end;

end.

