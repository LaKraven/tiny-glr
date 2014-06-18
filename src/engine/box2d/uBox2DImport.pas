unit uBox2DImport;

interface

uses
  tinyglr, glrMath,
  UPhysics2D, UPhysics2DTypes;

const
  //����������� ����������� �������� ���������� �������� � �������� �� ������
  //(��� ���������� ��������)
  //������������� �� ������������� �������� ��� ���������, �����
  C_COEF = 1 / 40;

type

  {����� box2d-����}

  Tglrb2World = class;

  Tglrb2SimulationEvent = procedure (const FixedDeltaTime: Double);

  Tglrb2OnContactEvent   = procedure (var contact: Tb2Contact) of object;
  Tglrb2OnPreSolveEvent  = procedure (var contact: Tb2Contact; const oldManifold: Tb2Manifold) of object;
  Tglrb2OnPostSolveEvent = procedure (var contact: Tb2Contact; const impulse: Tb2ContactImpulse) of object;

  Tglrb2ContactListener = class(Tb2ContactListener)
  private
    world: Tglrb2World;
  public
    procedure BeginContact(var contact: Tb2Contact); override;
    procedure EndContact(var contact: Tb2Contact); override;
    procedure PreSolve(var contact: Tb2Contact; const oldManifold: Tb2Manifold); override;
    procedure PostSolve(var contact: Tb2Contact; const impulse: Tb2ContactImpulse); override;
  end;

  Tglrb2World = class(Tb2World)
  private
    FContactListener: Tglrb2ContactListener;

    FOnBeginContact, FOnEndContact: array of Tglrb2OnContactEvent;

    FBefore, FAfter: Tglrb2SimulationEvent;
    FStep, FPhysicTime, FSimulationTime: Single;
    FIter: Integer;
  public
    constructor Create(const gravity: TVector2; doSleep: Boolean;
      aStep: Single; aIterations: Integer); reintroduce;

    procedure Update(const DeltaTime: Double);

    property OnAfterSimulation: Tglrb2SimulationEvent read FAfter write FAfter;
    property OnBeforeSimulation: Tglrb2SimulationEvent read FBefore write FBefore;

    //todo:  add/remove for pre and post solves
    procedure AddOnBeginContact(aEvent: Tglrb2OnContactEvent);
    procedure AddOnEndContact(aEvent: Tglrb2OnContactEvent);

    procedure RemoveOnBeginContact(aEvent: Tglrb2OnContactEvent);
    procedure RemoveOnEndContact(aEvent: Tglrb2OnContactEvent);
  end;

  { box2d }

  Box2D = class
  public
    class procedure SyncObjects(b2Body: Tb2Body; renderObject: TglrSprite);

    class function ConvertB2ToGL(aVec: TVector2): TdfVec2f;
    class function ConvertGLToB2(aVec: TdfVec2f): TVector2;

    class function Box(b2World: Tb2World; const aSprite: TglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
    class function Box(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;

    class function BoxSensor(b2World: Tb2World; aPos: TdfVec2f; aSize: TdfVec2f; aRot: Single; mask, cat: Word; IsStatic: Boolean): Tb2Body;

    class function BoxStatic(b2World: Tb2World; const aSprite: TglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
    class function BoxStatic(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;

    class function Circle(b2World: Tb2World; aRad: Double; aPos: TdfVec2f; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
    class function Circle(b2World: Tb2World; const aSprite: TglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;

    class function CircleSensor(b2World: Tb2World; aPos: TdfVec2f; aSize: Single; mask, cat: Word; IsStatic: Boolean): Tb2Body;

    class function ChainStatic(b2World: Tb2World; aPos: TdfVec2f; aVertices: array of TdfVec2f; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
  end;



implementation

{ Tdfb2World }

procedure Tglrb2World.AddOnBeginContact(aEvent: Tglrb2OnContactEvent);
var
  l: Integer;
begin
  if not Assigned(aEvent) then
    Exit();
  l := Length(FOnBeginContact);
  SetLength(FOnBeginContact, l + 1);
  FOnBeginContact[l] := aEvent;
end;

procedure Tglrb2World.AddOnEndContact(aEvent: Tglrb2OnContactEvent);
var
  l: Integer;
begin
  if not Assigned(aEvent) then
    Exit();
  l := Length(FOnEndContact);
  SetLength(FOnEndContact, l + 1);
  FOnEndContact[l] := aEvent;
end;

constructor Tglrb2World.Create(const gravity: TVector2; doSleep: Boolean;
  aStep: Single; aIterations: Integer);
begin
  inherited Create(gravity{, doSleep});
  FStep := aStep;
  FIter := aIterations;
  FContactListener := Tglrb2ContactListener.Create();
  FContactListener.world := Self;
  Self.SetContactListener(FContactListener);
end;

procedure Tglrb2World.RemoveOnBeginContact(aEvent: Tglrb2OnContactEvent);
var
  i: Integer;
begin
  //todo: test it
  for i := 0 to High(FOnBeginContact) do
    if @FOnBeginContact[i] = @aEvent then
    begin
      FOnBeginContact[i] := nil;
      if i <> High(FOnBeginContact) then
        Move(FOnBeginContact[i + 1], FOnBeginContact[i],
          SizeOf(Tglrb2OnContactEvent) * (Length(FOnBeginContact) - (i + 1)));
      SetLength(FOnBeginContact, Length(FOnBeginContact) - 1);
    end;
end;

procedure Tglrb2World.RemoveOnEndContact(aEvent: Tglrb2OnContactEvent);
var
  i: Integer;
begin
  //todo: test it
  for i := 0 to High(FOnEndContact) do
    if @FOnEndContact[i] = @aEvent then
    begin
      FOnEndContact[i] := nil;
      if i <> High(FOnEndContact) then
        Move(FOnEndContact[i + 1], FOnEndContact[i],
          SizeOf(Tglrb2OnContactEvent) * (Length(FOnEndContact) - (i + 1)));
      SetLength(FOnEndContact, Length(FOnEndContact) - 1);
    end;
end;

procedure Tglrb2World.Update(const DeltaTime: Double);
begin
  FPhysicTime := FPhysicTime + DeltaTime;
  while FSimulationTime <= FPhysicTime do
  begin
    FSimulationTime := FSimulationTime + FStep;

    if Assigned(FBefore) then
      FBefore(FStep);

    Step(FStep, FIter, FIter, False);

    if Assigned(FAfter) then
      FAfter(FStep);
  end;
end;



class procedure Box2D.SyncObjects(b2Body: Tb2Body; renderObject: TglrSprite);
var
  pos2d: TdfVec2f;
begin
  pos2d := dfVec2f(b2Body.GetPosition.x, b2Body.GetPosition.y) * (1 / C_COEF);
  renderObject.Position.x := pos2d.x;
  renderObject.Position.y := pos2d.y;
  renderObject.Rotation := b2Body.GetAngle * rad2deg;
end;

class function Box2D.ConvertB2ToGL(aVec: TVector2): TdfVec2f;
begin
  Result := dfVec2f(aVec.x, aVec.y);
end;

class function Box2D.ConvertGLToB2(aVec: TdfVec2f): TVector2;
begin
  Result.SetValue(aVec.x, aVec.y);
end;


class function Box2D.Box(b2World: Tb2World; const aSprite: TglrSprite; d, f,
  r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_dynamicBody;
    position := ConvertGLToB2(dfVec2f(aSprite.Position) * C_COEF);
    angle := aSprite.Rotation * deg2rad;
  end;

  with ShapeDef do
  begin
    SetAsBox(aSprite.Width / 2 * C_COEF, aSprite.Height / 2 * C_COEF);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;
{var
  aCenter: TdfVec2f;
begin
  case aSprite.PivotPoint of
    ppTopLeft: ;
    ppTopRight: ;
    ppBottomLeft: ;
    ppBottomRight: ;
    ppCenter: aCenter := dfVec2f(0, 0);
    ppTopCenter: ;
    ppBottomCenter: ;
    ppCustom: ;
  end;
  Result := dfb2InitBox(b2World, aSprite.Position, dfVec2f(aSprite.Width * 0.5, aSprite.Height * 0.5), aSprite.Rotation, d, f, r, mask, category, group);
end;          }


class function Box2D.Box(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aPos * C_COEF);
    angle := aRot * deg2rad;
  end;

  with ShapeDef do
  begin
    SetAsBox(aSize.x * 0.5 * C_COEF, aSize.y * 0.5 * C_COEF);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;

class function Box2D.Circle(b2World: Tb2World; aRad: Double; aPos: TdfVec2f; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2CircleShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2CircleShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aPos * C_COEF);
  end;

  with ShapeDef do
  begin
    m_radius := aRad * C_COEF;
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;

class function Box2D.Circle(b2World: Tb2World; const aSprite: TglrSprite; d, f,
  r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
begin
  Result := Circle(b2World, aSprite.Width / 2, dfVec2f(aSprite.Position), d, f, r, mask, Category, group);
end;

class function Box2D.BoxStatic(b2World: Tb2World; const aSprite: TglrSprite; d,
  f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
begin
  Result := BoxStatic(b2World, dfVec2f(aSprite.Position), dfVec2f(aSprite.Width, aSprite.Height), aSprite.Rotation, d, f, r, mask, category, group);
end;

class function Box2D.BoxStatic(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_staticBody;
    position := ConvertGLToB2(aPos * C_COEF);
    angle := aRot * deg2rad;
  end;

  with ShapeDef do
  begin
    SetAsBox(aSize.x * 0.5 * C_COEF, aSize.y * 0.5 * C_COEF);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(True);
end;

class function Box2D.ChainStatic(b2World: Tb2World; aPos: TdfVec2f; aVertices: array of TdfVec2f;
  d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2ChainShape;
  FixtureDef: Tb2FixtureDef;
  Ar: TVectorArray;
  i: Integer;
begin
  FixtureDef := Tb2FixtureDef.Create;
  //ShapeDef := Tb2ChainShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_staticBody;
    position := ConvertGLToB2(aPos * C_COEF);
    angle := 0;
  end;

  SetLength(Ar, Length(aVertices));
  for i := 0 to High(aVertices) do
    Ar[i] := ConvertGLToB2(aVertices[i] * C_COEF);

  ShapeDef := Tb2ChainShape.CreateChain(@Ar[0], Length(Ar));

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(True);
end;

class function Box2D.BoxSensor(b2World: Tb2World; aPos: TdfVec2f; aSize: TdfVec2f;
  aRot: Single; mask, cat: Word; IsStatic: Boolean): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    if IsStatic then
      bodyType := b2_staticBody
    else
      bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aPos * C_COEF);
    angle := aRot * deg2rad;
  end;

  with ShapeDef do
  begin
    SetAsBox(aSize.x * 0.5 * C_COEF, aSize.y * 0.5 * C_COEF);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    isSensor := True;
    filter.maskBits := mask;
    filter.categoryBits := cat;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;

class function Box2D.CircleSensor(b2World: Tb2World; aPos: TdfVec2f; aSize: Single;
  mask, cat: Word; IsStatic: Boolean): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2CircleShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2CircleShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    if IsStatic then
      bodyType := b2_staticBody
    else
      bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aPos * C_COEF);
  end;

  with ShapeDef do
  begin
    m_radius := aSize * C_COEF;
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    isSensor := True;
    filter.maskBits := mask;
    filter.categoryBits := cat;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(True);
end;

{ Tglrb2ContactListener }

procedure Tglrb2ContactListener.BeginContact(var contact: Tb2Contact);
var
  i: Integer;
begin
  inherited;
  for i := 0 to High(world.FOnBeginContact) do
    world.FOnBeginContact[i](contact);
end;

procedure Tglrb2ContactListener.EndContact(var contact: Tb2Contact);
var
  i: Integer;
begin
  inherited;
  for i := 0 to High(world.FOnBeginContact) do
    world.FOnEndContact[i](contact);
end;

procedure Tglrb2ContactListener.PostSolve(var contact: Tb2Contact;
  const impulse: Tb2ContactImpulse);
begin
  inherited;

end;

procedure Tglrb2ContactListener.PreSolve(var contact: Tb2Contact;
  const oldManifold: Tb2Manifold);
begin
  inherited;

end;

end.
