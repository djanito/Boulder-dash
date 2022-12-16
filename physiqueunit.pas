unit physiqueunit;

interface

uses drawunit;

var
  delayChute : Integer = 0;
  delayGlisse : Integer = 0;

const
  ENTITY_CHUTE_TIME = 150;
  ENTITY_GLISSE_TIME = 140;

procedure updateEntities(xEntity, yEntity: Integer; var plate: Plateau; playerAbsPosition: Point);

implementation

procedure makeEntityFall(xEntity, yEntity: Integer; var plate: Plateau);

begin
  delayChute += TICK_INTERVAL;

  if (delayChute >= ENTITY_CHUTE_TIME) then
    begin
      plate.cases[yEntity+1, xEntity].index := plate.cases[yEntity, xEntity].index;
      plate.cases[yEntity+1, xEntity].fallingDistance += 1;

      plate.cases[yEntity, xEntity].index := 'R';
      plate.cases[yEntity, xEntity].fallingDistance := 0;

      delayChute := 0;
    end;
end;

procedure makeEntitySlip(xEntity, yEntity, sens : Integer; var plate: Plateau);

begin
  delayGlisse += TICK_INTERVAL;

  if (delayGlisse >= ENTITY_GLISSE_TIME) then
    begin
      plate.cases[yEntity, xEntity + sens].index := plate.cases[yEntity, xEntity].index;
      plate.cases[yEntity, xEntity].index := 'R';

      delayGlisse := 0;
    end;
end;


procedure updateEntities(xEntity, yEntity: Integer; var plate: Plateau; playerAbsPosition: Point);

begin

  if (plate.cases[yEntity+1, xEntity].index <> 'R') then
    plate.cases[yEntity, xEntity].fallingDistance := 0; // reset falling distance when ball is on a ground

  if (plate.cases[yEntity+1, xEntity].index = 'R') then // if nothing below
    if (xEntity = playerAbsPosition[0]) and (yEntity+1 = playerAbsPosition[1]) then // if player is below the ball
      begin
        if (plate.cases[yEntity, xEntity].fallingDistance <> 0) then // ball can fall only if it has minimum 1 falling distance
          makeEntityFall(xEntity, yEntity, plate);
      end
    else
      makeEntityFall(xEntity, yEntity, plate)
  else if (plate.cases[yEntity+1, xEntity].index <> 'T') then // if the ball can slip
    begin
      if (plate.cases[yEntity, xEntity-1].index = 'R') and (plate.cases[yEntity+1, xEntity-1].index = 'R') then // if there is no dirt in the 2 left tiles
        begin
          if not ((xEntity-1 = playerAbsPosition[0]) and (yEntity+1 = playerAbsPosition[1])) and not ((xEntity-1 = playerAbsPosition[0]) and (yEntity = playerAbsPosition[1])) then
            makeEntitySlip(xEntity, yEntity, -1, plate);
        end
      else if (plate.cases[yEntity, xEntity+1].index = 'R') and (plate.cases[yEntity+1, xEntity+1].index = 'R') then // if there is no dirt in the 2 right tiles
        begin
          if not ((xEntity+1 = playerAbsPosition[0]) and (yEntity+1 = playerAbsPosition[1])) and not ((xEntity+1 = playerAbsPosition[0]) and (yEntity = playerAbsPosition[1])) then
            makeEntitySlip(xEntity, yEntity, +1, plate);
        end;
    end;
end;

end.

