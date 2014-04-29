program demo1;
  //{$mode delphi}
//  {$apptype console}

uses
  tinyglr, glrMath, ogl, sys_win;

type

  { TGame }

  TGame = class(TglrGame)
  public
    procedure OnFinish; override;
    procedure OnInput(aType: TglrInputType; aKey: TglrKey; X, Y,
      aOtherParam: Integer); override;
    procedure OnPause; override;
    procedure OnRender; override;
    procedure OnResume; override;
    procedure OnResize(aNewWidth, aNewHeight: Integer); override;
    procedure OnStart; override;
    procedure OnUpdate(const dt: Double); override;
  end;

{ TGame }

procedure TGame.OnFinish;
begin
  WriteLn('End');
end;

procedure TGame.OnInput(aType: TglrInputType; aKey: TglrKey; X, Y,
  aOtherParam: Integer);
begin
  if (aKey <> kNoInput) then
    WriteLn('Input : ' + Core.Input.GetInputTypeName(aType) + ' : ' + Core.Input.GetKeyName(aKey));
end;

procedure TGame.OnPause;
begin
  WriteLn('Pause');
end;

procedure TGame.OnRender;
begin

end;

procedure TGame.OnResume;
begin
  WriteLn('Resume');
end;

procedure TGame.OnResize(aNewWidth, aNewHeight: Integer);
begin
  WriteLn('Resize');
end;

procedure TGame.OnStart;
begin
  WriteLn('Start');
end;

procedure TGame.OnUpdate(const dt: Double);
begin

end;

var
  Game: TGame;
  InitParams: TglrInitParams;

begin
  with InitParams do
  begin
    Width := 800;
    Height := 600;
    X := 100;
    Y := 100;
    Caption := 'tiny glr яд';
    vSync := True;
  end;

  Game := TGame.Create();
  Core.Init(Game, InitParams);
  Core.Loop();
  Core.DeInit();
end.

