program main;

uses SDL2, SDL2_image, drawunit, sysutils, playerunit, hudunit, physiqueunit, enemiesunit, cameraunit;

var
  window: PSDL_Window;
  renderer: PSDL_Renderer;
  Running: Boolean = True;

  sdlEvent: PSDL_Event;

  plate: Plateau;
  p: Player;

  nextTime, starting_tick : Uint32;
  updateTimerId : TSDL_TimerID;

  i, j : Integer;

function timeLeft(): Uint32;

var now : Uint32;

begin
  now := SDL_GetTicks;

  if(nextTime <= now) then
    timeLeft := 0
  else
    timeLeft := nextTime - now;

end;

function updateTimer(intervalle: Uint32): Uint32;

begin
  if not p.isOnExit then
    if (plate.timeLeft > 0) then
      plate.timeLeft -= 1;

  updateTimer := intervalle;
end;

begin

  //initilization of video subsystem
  if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER) < 0 then Halt;

  // set-up window & renderer
  window := SDL_CreateWindow('Boulder Dash', 100, 100, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN);
  SDL_SetWindowIcon(window, SDL_LoadBMP('images/icon.bmp'));

  renderer := SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC or SDL_RENDERER_ACCELERATED);

  if window = nil then Halt;
  if renderer = nil then Halt;

  // initialize the plateau & player
  initializePlateau(renderer, plate, 1);
  initializePlayer(renderer, p, plate);

  initCamera(PLATEAU_WIDTH, PLATEAU_HEIGHT);
  initializeHUD(renderer);

  // update timer every second
  updateTimerId := SDL_AddTimer(1000, TSDL_TimerCallback(@updateTimer), nil);

  // program loop
  new(sdlEvent);
  nextTime := SDL_GetTicks() + TICK_INTERVAL;
  while Running do
    begin
      starting_tick := SDL_GetTicks();
      while SDL_PollEvent(sdlEvent) = 1 do
          case sdlEvent^.type_ of
            SDL_WINDOWEVENT:
              case sdlEvent^.window.event of
                SDL_WINDOWEVENT_CLOSE: Running := false;
              end;
          end;

      handlePlayerMovement(SDL_GetKeyboardState(nil), p, plate);

      for i:= Low(plate.cases) + 1 to PLATEAU_HEIGHT_TILE_NUMBER-1 do
        for j:= Low(plate.cases) + 1 to PLATEAU_WIDTH_TILE_NUMBER-1 do
          if (plate.cases[i, j].index = 'B') or (plate.cases[i, j].index = 'D') then
            updateEntities(j, i, plate, p.absPosition)
          else if (plate.cases[i, j].index = 'E') then
            updateEnemy(j, i, plate);

      if not p.isDeath then
        begin
          p.rect.x := (p.relPosition[0]-1) * TILE_SIZE;
          p.rect.y := (p.relPosition[1]-1) * TILE_SIZE;
          updateCamera(p.rect);
        end;


      // SET HUD VIEWPORT
      SDL_RenderClear(renderer);

      SDL_RenderSetViewport(renderer, @HUD_VIEWPORT);
      SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
      SDL_RenderFillRect(renderer, nil);

      //drawInfos(renderer, p, plate.name);

      // SET MAIN VIEWPORT
      SDL_RenderSetViewport(renderer, @GAME_VIEWPORT);
      if (p.level = 5) then
        SDL_SetRenderDrawColor(renderer, 0, 0, 138, SDL_ALPHA_OPAQUE);

      // DRAW ENTITIES
      drawPlateau(renderer, plate);
      drawPlayer(renderer, p);

      drawHUD(renderer, plate, p);

      checkPlayerDeath(renderer, p, plate);
      checkLevelFinish(renderer, p, plate);

      // draw to screen
      SDL_RenderPresent(renderer);

      //writeln(IntToStr(round(1000/(timeLeft + (SDL_GetTicks() - starting_tick)))));

      // constant frame rate (8 FPS)
      SDL_Delay(TICK_INTERVAL);
      nextTime += TICK_INTERVAL;
    end;

  // clear events
  dispose(sdlEvent);

  // remove timer
  SDL_RemoveTimer(updateTimerId);

  // clear texture
  SDL_DestroyTexture(p.texture);
  destroyPlateTextures();

  // clear memory
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);

  //closing SDL2
  SDL_Quit;

end.

