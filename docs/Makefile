# https://github.com/FarManagerLegacy/HelpDown-scripts

# required user setting
BASE:=D:\repo\HelpDown-scripts
PANDOC:=C:\Apps\pandoc\pandoc.exe
HTMLTOFARHELP:=$(FARPROFILE)\tools\HtmlToFarHelp\HtmlToFarHelp.exe

# plug base Makefile
include $(BASE)\Makefile
.DEFAULT_GOAL:=hlf

# optional local customization
%.hlfhtml: FLAGS+= --lua-filter addRefs.lua
%: FLAGS+= --lua-filter SetextH3.lua --toc

README.md: LuaShell.ru.md
	@echo $@
	@if exist $@ del $@
	@ren $< $@

.PHONY: all
all: hlf forum README.md
