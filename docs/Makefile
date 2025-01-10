# https://github.com/FarManagerLegacy/HelpDown-scripts

# required user setting
BASE:=D:\repo\HelpDown-scripts
#PANDOC:=C:\Apps\pandoc\pandoc.exe
HTMLTOFARHELP:="$(FARPROFILE)\tools\HtmlToFarHelp\HtmlToFarHelp.exe"

# plug base Makefile
include $(BASE)/Makefile
.DEFAULT_GOAL:=hlf

# optional local customization
%.hlfhtml: FLAGS+=--lua-filter addRefs.lua
%: FLAGS+= --toc --lua-filter SetextH3.lua

README.md: LuaShell.ru.md
	@echo $@
	@if exist $@ del $@
	@ren $< $@

.PHONY: all post
all: hlf forum README.md
	@move *.hlf ../.LuaShell >nul

post: LuaShell.ru.forum
	@env \
	  PASSWORD=$(shell KeePassCommand.cmd getfieldraw forum.farmanager.com Password) \
	  USERNAME="John Doe" \
	  POST_ID=145804 \
	  FILE="$<" \
	  CLEANUP=false \
	  $(BASE)/update_post.sh
