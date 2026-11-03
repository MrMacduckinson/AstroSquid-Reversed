# Происхождение и уведомления

- Оригинальная AstroSquid 1.1 — Lost Minds. Графика, уровни, музыка и звуки
  извлечены из оригинального приложения и сохраняют авторство своих создателей.
  Проект не является официальным выпуском Lost Minds. Источник архивов:
  https://macintoshgarden.org/games/astrosquid . Варианты .sit и .zip,
  исследованные при восстановлении, содержали одинаковый код и resource fork;
  более поздняя дата архива сама по себе не означает новую версию игры.
- Исходники здесь — реконструкция C/Objective-C, не оригинальный FutureBASIC-проект.
- В `src/ppc_math.c` сохранены уведомления Apple для использованного числового
  кода. Текст Apple Public Source License 1.1 находится в
  `licenses/Apple-Libm-APSL-1.1.txt` и включён в обе сборки.
- Этот пакет не назначает новую общую лицензию оригинальным игровым ресурсам
  или всему реконструированному проекту. Наличие файлов в Git не означает,
  что весь пакет лицензирован как MIT или public domain.
- Оригинальные модели Infini-D — отдельные исходные материалы художников;
  для запуска и сборки не нужны. Исходный PEF и частные материалы анализа
  не включены в передаваемый репозиторий.

## LLVM BlocksRuntime (Intel-Tiger only)

`src/tiger/vendor/BlocksRuntime` — runtime.c, data.c, Block.h, Block_private.h
из LLVM compiler-rt llvmorg-3.8.0 (убраны пробелы в конце строк); config.h — локальная конфигурация.
Источник: https://github.com/llvm/llvm-project/tree/llvmorg-3.8.0/compiler-rt/lib/BlocksRuntime
Лицензия Apple включена в `licenses/BlocksRuntime.txt` и в Tiger bundle.
Apple SDK в репозиторий и релиз не включается.
