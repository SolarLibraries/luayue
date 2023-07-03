include guess.mk

CC = gcc
CXX = g++
LD = ld

#gets overwritten by luarocks, and we need to append to it
C_FLAGS = $(CFLAGS)
CXX_FLAGS = $(CFLAGS) -std=c++20
LD_FLAGS = -L$(LUA_LIBDIR) $(LIBFLAG)

CURL = curl
YUE_VERSION = latest
LUA = lua
LUA_INCDIR=/usr/local/include

INCLUDES = -I$(LUA_INCDIR)

ifeq ($(OS), darwin)
	RM=rm -rf
	DL = $(CURL) -fL
	UNZIP = unzip -q

#if libflag is not defined (luarocks defines it) then add -bundle -undefined dynamic_lookup

ifneq ($(LIBFLAG),)
	LD_FLAGS += -bundle -undefined dynamic_lookup
endif

	LD_FLAGS += -framework AppKit -framework Carbon -framework IOKit -framework Security -framework WebKit -framework OpenDirectory
	LD_FLAGS += -llua -lpmenergy -lpmsample
	C_FLAGS += -DSYSTEM_NATIVE_UTF8 -Wno-deprecated-declarations
	INCLUDES+=-I/usr/local/include

	LIBYUE=yue.so
else ifeq ($(OS), windows)
	RM=del /f /q
	DL = C:\\windows\\system32\\curl.exe -fL
	UNZIP = C:\\windows\\system32\\tar.exe -xf

	C_FLAGS += -D_WINDOWS -DWIN32 -DWIN32_LEAN_AND_MEAN -DNOMINMAX -D_UNICODE -DUNICODE
	LD_FLAGS += setupapi.lib powrprof.lib ws2_32.lib dbghelp.lib shlwapi.lib version.lib winmm.lib wbemuuid.lib psapi.lib dwmapi.lib propsys.lib comctl32.lib gdi32.lib gdiplus.lib urlmon.lib userenv.lib uxtheme.lib delayimp.lib runtimeobject.lib ntdll.lib shcore.lib
	LD_FLAGS += "/DELAYLOAD:setupapi.dll" "/DELAYLOAD:powrprof.dll" "/DELAYLOAD:dwmapi.dll" "/SUBSYSTEM:WINDOWS"

	LIBYUE = yue.dll
else
	RM = rm -rf
	DL = $(CURL) -fL
	UNZIP = unzip -q

  	LD_FLAGS += -lpthread -ldl -latomic $(shell pkg-config --libs fontconfig pangoft2 gtk+-3.0 gdk-3.0 glib-2.0 webkit2gtk-4.0 )
  	C_FLAGS 	+= $(shell pkg-config --cflags fontconfig pangoft2 gtk+-3.0 gdk-3.0 glib-2.0 webkit2gtk-4.0)
	C_FLAGS 	+= -DUSE_GLIB -fdata-sections -ffunction-sections -Wno-deprecated-declarations
  	LD_FLAGS	+= -Wl,--as-needed,--gc-section -fLTO
	INCLUDES+=-I/usr/include -I/usr/local/include

	LIBYUE = yue.so
endif

ARCH = x64
GIT = git
CXX_FLAGS = $(C_FLAGS) -std=c++20
AR = ar

YUE_VER = $(shell $(LUA) get-yue.lua $(YUE_VERSION) version $(CURL) $(OS))
YUE_SRC_ARCHIVE_URL = $(shell $(LUA) get-yue.lua $(YUE_VER) url $(CURL) $(OS))

.PHONY: all build install
all: $(LIBYUE)
build: yue/ $(LIBYUE)

yue-git/:
	$(GIT) clone https://github.com/yue/yue.git --recursive --branch v$(YUE_VER) $@

yue/:
	$(DL) $(YUE_SRC_ARCHIVE_URL) -o yue.zip
	$(UNZIP) yue.zip -d $@

yue/yue.a: yue/
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mMaking \033[33myue.a\n\033[0m"
	$(MAKE) -f ../Yue.mk CC="$(CC)" CXX="$(CXX)" CFLAGS="$(C_FLAGS)" CXXFLAGS="$(CXX_FLAGS)" INCDIRS="$(INCLUDES)" OS="$(OS)" -C $<

yue-git/lua/lua.a: yue-git/ yue/
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mMaking \033[33mlua.a\n\033[0m"
	$(MAKE) -f ../../Lua.mk CC="$(CC)" CXX="$(CXX)" CFLAGS="$(C_FLAGS)" CXXFLAGS="$(CXX_FLAGS)" INCDIRS="$(INCLUDES)" OS="$(OS)" -C yue-git/lua/

yue-git/lua_yue/lua_yue.a: yue-git/ yue/
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mMaking \033[33mlua_yue.a\n\033[0m"
	$(MAKE) -f ../../LuaYue.mk CC="$(CC)" CXX="$(CXX)" CFLAGS="$(C_FLAGS)" CXXFLAGS="$(CXX_FLAGS)" INCDIRS="$(INCLUDES)" OS="$(OS)" -C yue-git/lua_yue/

install: $(LIBYUE)
	cp $(LIBYUE) $(INST_LIBDIR)/$(LIBYUE)

ifeq ($(OS),darwin)
#macOS linkers use -all_load
$(LIBYUE): yue/yue.a yue-git/lua/lua.a yue-git/lua_yue/lua_yue.a
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mLinking \033[33m$@\n\033[0m"
	$(CXX) $(LD_FLAGS) -o $@ $^

else ifeq ($(OS),windows)



else
#linux linkers use --whole-archive
$(LIBYUE): yue/yue.a yue-git/lua/lua.a yue-git/lua_yue/lua_yue.a
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mLinking \033[33m$@\n\033[0m"
	$(CXX) $(LD_FLAGS) -Wl,--whole-archive -shared -o $@ $^ -Wl,--no-whole-archive
endif

.PHONY: clean
clean:
	$(RM) yue/
	$(RM) *.o
	$(RM) *.so
	$(RM) *.dll
	$(RM) yue.zip
	$(RM) lua/
	$(RM) lua_yue/
	$(RM) yue-git/
