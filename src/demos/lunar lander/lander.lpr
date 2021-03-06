{
  TODO:
  + Редактор - добавление новых точек
  + Редактор - добавление точек посадки с множителем

  + GUI: Отображение точек посадки
  - GUI: отображение вектора скорости

  + Физическая реакция на включение топлива

  + Обработка столкновения корабля с луной:
  +   В случае большой скорости или неправильного угла - проигрыш, перезапуск игры
  +   В случае малой скорости и верного угла - "вы победили" + очки + флаг

  + Расчет очков на основе оставшегося топлива и множителя

  + Приближение/удаление в зависимости от скорости корабля и близости к поверхности
  + Изменение цвета скорости при достижении оптимального значения для посадки
  + При нуле топлива - не давать включать двигатель
  + При покидании границ уровня - проигрыш, перезапуск игры
  + Текстура луны
  + Флаг!
}

program lander;

uses
  heaptrc,
  glr_core,
  glr_tween,
  glr_utils,
  uMain;

var
  InitParams: TglrInitParams;

begin
  SetHeapTraceOutput('heaptrace.log');
  with InitParams do
  begin
    Width := 1000;
    Height := 600;
    X := 100;
    Y := 100;
    Caption := '«Lunar Lander» © Atari, 1979. Remake by perfect.daemon [tiny-glr ' + TINYGLR_VERSION + ']';
    vSync := True;
    PackFilesPath := '';
    UseDefaultAssets := True;
  end;

  Game := TGame.Create();
  Core.Init(Game, InitParams);
  Core.Loop();
  Core.DeInit();
  Game.Free();
  DumpHeap();
end.

