include guess.mk

CC = gcc
CXX = g++
LD = ld

#CFLAGS, LDFLAGS, etc gets overwritten by luarocks
C_FLAGS = $(CFLAGS) -w
LD_FLAGS = -L$(LUA_LIBDIR) $(LIBFLAG)

CURL = curl
YUE_VERSION = latest
LUA = lua
LUA_INCDIR=/usr/local/include

INCLUDES = -I$(LUA_INCDIR)

ifndef OS
	OS=windows
endif

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
	C_FLAGS += -DOS_MAC -DSYSTEM_NATIVE_UTF8 -Wno-deprecated-declarations -U__weak -D__weak=__unsafe_unretained
	INCLUDES += -I/usr/local/include
	LD_FLAGS += -L/usr/local/lib

	LIBYUE = yue.so
else ifeq ($(OS), windows)
	RM=del /f /q
	DL = C:\\windows\\system32\\curl.exe -fL
	UNZIP = C:\\windows\\system32\\tar.exe -xf

	C_FLAGS += -D_WINDOWS -DWIN32 -DWIN32_LEAN_AND_MEAN -DNOMINMAX -D_UNICODE -DUNICODE -DOS_WIN
	LD_FLAGS += setupapi.lib powrprof.lib ws2_32.lib dbghelp.lib shlwapi.lib version.lib winmm.lib wbemuuid.lib psapi.lib dwmapi.lib propsys.lib comctl32.lib gdi32.lib gdiplus.lib urlmon.lib userenv.lib uxtheme.lib delayimp.lib runtimeobject.lib ntdll.lib shcore.lib
	LD_FLAGS += "/DELAYLOAD:setupapi.dll" "/DELAYLOAD:powrprof.dll" "/DELAYLOAD:dwmapi.dll" "/SUBSYSTEM:WINDOWS"

	LIBYUE = yue.dll
else
	RM = rm -rf
	DL = $(CURL) -fL
	UNZIP = unzip -q

	LD_FLAGS += -L/usr/lib -L/usr/local/lib -L/usr/lib/x86_64-linux-gnu -L/usr/local/lib/x86_64-linux-gnu
  	LD_FLAGS += -lpthread -ldl -latomic $(shell pkg-config --libs fontconfig pangoft2 gtk+-3.0 gdk-3.0 glib-2.0 webkit2gtk-4.0 )
  	C_FLAGS += $(shell pkg-config --cflags fontconfig pangoft2 gtk+-3.0 gdk-3.0 glib-2.0 webkit2gtk-4.0)
	C_FLAGS += -DUSE_GLIB -fdata-sections -ffunction-sections -Wno-deprecated-declarations

	C_FLAGS	+= -D_GNU_SOURCE -DOS_LINUX -DSYSTEM_NATIVE_UTF8
  	# LD_FLAGS cl+= -Wl,--as-needed,--gc-section
	INCLUDES += -I/usr/include -I/usr/local/include

	LIBYUE = yue.so
endif

ARCH = x64
GIT = git
CXX_FLAGS = $(C_FLAGS) -std=gnu++2a
AR = ar

YUE_TAG = $(shell $(LUA) utility.lua version "YUE_VERSION=$(YUE_VERSION)" "DL=$(CURL)" "OS=$(OS)")
YUE_SRC_ARCHIVE_URL = $(shell $(LUA) utility.lua url "YUE_VERSION=$(YUE_VERSION)" "DL=$(CURL)" "OS=$(OS)")

.PHONY: all build install
all: $(LIBYUE)
build: yue/ $(LIBYUE)

yue-git/:
	$(GIT) clone https://github.com/yue/yue.git --recursive --branch $(YUE_TAG) $@

yue/:
	$(DL) $(YUE_SRC_ARCHIVE_URL) -o yue.zip
	$(UNZIP) yue.zip -d $@

yue/yue.a: yue/
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mMaking \033[33m$@\n\033[0m"
	$(MAKE) -f ../Yue.mk CC="$(CC)" CXX="$(CXX)" CFLAGS="$(C_FLAGS)" CXXFLAGS="$(CXX_FLAGS)" INCDIRS="$(INCLUDES)" OS="$(OS)" -C $<

yue-git/lua/lua.a: yue-git/ yue/
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mMaking \033[33m$@\n\033[0m"
	$(MAKE) -f ../../Lua.mk CC="$(CC)" CXX="$(CXX)" CFLAGS="$(C_FLAGS)" CXXFLAGS="$(CXX_FLAGS)" INCDIRS="$(INCLUDES)" OS="$(OS)" -C yue-git/lua/

yue-git/lua_yue/lua_yue.a: yue-git/ yue/
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mMaking \033[33m$@\n\033[0m"
	$(MAKE) -f ../../LuaYue.mk CC="$(CC)" CXX="$(CXX)" CFLAGS="$(C_FLAGS)" CXXFLAGS="$(CXX_FLAGS)" INCDIRS="$(INCLUDES)" OS="$(OS)" -C yue-git/lua_yue/

download-bin:
	$(LUA) utility.lua download "YUE_VERSION=$(YUE_VERSION)" "OS=$(OS)" "UNZIP=$(UNZIP)" "TAR=$(TAR)"

install-bin:
ifeq ($(OS),windows)
	if not exist "$(INST_LIBDIR)" mkdir "$(INST_LIBDIR)"
	copy "yue-bin\$(LIBYUE)" "$(INST_LIBDIR)\$(LIBYUE)"
else
	mkdir -p $(INST_LIBDIR)
	cp yue-bin/$(LIBYUE) $(INST_LIBDIR)/$(LIBYUE)
endif


install: $(LIBYUE)
	cp $(LIBYUE) $(INST_LIBDIR)/$(LIBYUE)

ifeq ($(OS),darwin)
#macOS linkers use -all_load
$(LIBYUE): yue/yue.a yue-git/lua/lua.a yue-git/lua_yue/lua_yue.a
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mLinking \033[33m$@\n\033[0m"
	$(CXX) -o $@ $^ $(LD_FLAGS)

else ifeq ($(OS),windows)

#If we are using windows, then just install binaries
# $(LIBYUE):
# 	$(LUA) install.lua $(YUE_VERSION) bin-download $(CURL) $(OS) $(LUA_INCDIR) $(LUA_LIBDIR) $(UNZIP)
# 	cp yue.dll $(INST_LIBDIR)/yue.dll

else
#linux linkers use --whole-archive
$(LIBYUE): yue/yue.a yue-git/lua/lua.a yue-git/lua_yue/lua_yue.a
	@/usr/bin/printf "[\033[1;35mLua-Yue\033[0m] \033[32mLinking \033[33m$@\n\033[0m"
	$(CXX) -Wl,--whole-archive -shared -o $@ $^ -Wl,--no-whole-archive $(LD_FLAGS)
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
