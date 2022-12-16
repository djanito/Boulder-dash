unit enemiesUnit;

interface

uses drawunit;

const
  ENEMY_MOVE_TIME = 200;

var
  delayEnemyMovement : Integer;

procedure updateEnemy(Xboule, Yboule: Integer; var plate: Plateau);

implementation

function isMurInFace(Xboule, Yboule: Integer; var xInc : Integer; var yInc : Integer; var plate : Plateau) : Boolean;

begin
  xInc := 0;
  yInc := 0;

  case plate.cases[Yboule, Xboule].dir of
    haut :
      begin
        if (plate.cases[Yboule - 1, Xboule].index = 'R') then
          begin
            isMurInFace := False;
            yInc := -1;
          end
        else
          isMurInFace := True;
      end;
    bas :
      begin
        if (plate.cases[Yboule + 1, Xboule].index = 'R') then
          begin
            isMurInFace := False;
            yInc := 1;
          end
        else
          isMurInFace := True;
      end;
    gauche :
      begin
        if (plate.cases[Yboule, Xboule - 1].index = 'R') then
          begin
            isMurInFace := False;
            xInc := -1;
          end
        else
          isMurInFace := True;
      end;
    droite :
      begin
        if (plate.cases[Yboule, Xboule + 1].index = 'R') then
          begin
            isMurInFace := False;
            xInc := 1;
          end
        else
          isMurInFace := True;
      end;
    else isMurInFace := True;
  end;
end;

procedure updateEnemy(Xboule, Yboule: Integer; var plate: Plateau);

var
  xInc : Integer = 0;
  yInc : Integer = 0;

begin
  delayEnemyMovement += TICK_INTERVAL;

  if (delayEnemyMovement >= ENEMY_MOVE_TIME) then
    begin

      while isMurInFace(Xboule, Yboule, xInc, yInc, plate) do
        case plate.cases[Yboule, Xboule].dir of
          haut : plate.cases[Yboule, Xboule].dir := gauche;
          bas : plate.cases[Yboule, Xboule].dir := droite;
          gauche : plate.cases[Yboule, Xboule].dir := bas;
          droite : plate.cases[Yboule, Xboule].dir := haut;
        end;

      plate.cases[Yboule + yInc, Xboule + xInc].dir := plate.cases[Yboule, Xboule].dir;
      plate.cases[Yboule + yInc, Xboule + xInc].index := 'E';
      plate.cases[Yboule, Xboule].index := 'R';

      case plate.cases[Yboule + yInc , Xboule + xInc].dir of
        haut : if plate.cases[Yboule + yInc, Xboule + 1 + xInc].index = 'R' then plate.cases[Yboule + yInc, Xboule + xInc].dir := droite;
        bas : if plate.cases[Yboule + yInc, Xboule - 1 + xInc].index = 'R' then plate.cases[Yboule + yInc, Xboule + xInc].dir := gauche;
        gauche : if plate.cases[Yboule - 1 + yInc, Xboule + xInc].index = 'R' then plate.cases[Yboule + yInc, Xboule + xInc].dir := haut;
        droite : if plate.cases[Yboule + 1 + yInc, Xboule + xInc].index = 'R' then plate.cases[Yboule + yInc, Xboule + xInc].dir := bas;
      end;

      delayEnemyMovement := 0;
    end;
end;

end.

