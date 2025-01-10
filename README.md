LuaShell — запуск lua-скриптов и выражений с удобной передачей аргументов командной строки
========

В этом репозитории содержатся скрипты и [вспомогательные утилиты](UTILS.md), составляющие ядро проекта [LuaShell](docs/README.md).

Рекомендуются установить также [дополнительные](docs#Утилиты) наборы готовых скриптов/утилит:

- [std](https://github.com/FarManagerLegacy/LuaShell.std)
- [3rd-party](https://github.com/FarManagerLegacy/LuaShell.3rd-party)

Стандартное расположение скриптов проекта: `%FARPROFILE%\Macros\utils`,
а директория [`.LuaShell`](.LuaShell) должна быть в `Macros\scripts`
(можно не перемещать её, а сделать ссылку).

Структура полностью развёрнутого проекта:

```
Profile (%FARPROFILE%)
└─ Macros
   ├─ modules
   │  ├─ inspect.lua
   │  └─ le.lua
   ├─ scripts
   │  └─ .LuaShell
   └─ utils
      ├─ core
      ├─ std
      ├─ 3rd-party
      └─ ...
```

Подробнее установка описана в [документации](docs/#Установка).
