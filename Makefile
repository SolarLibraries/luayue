# ==========================================================================
# config.mk - Portable feature detection Make macros from autoguess project
# --------------------------------------------------------------------------
# Copyright (c) 2017, 2020, 2021  William Ahern
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
# --------------------------------------------------------------------------
# PORTING NOTES
#
# MACRO:sh=) In MACRO:sh= assignments (not $(MACRO:sh) substitutions),
#   Solaris make does not subject the shell command to macro substitution.
#
# ==========================================================================

BOOL,true = true
BOOL,1 = true
BOOL,false = false
BOOL,0 = false
BOOL, = false

IF,true = true
IF,1 = true

UNLESS,false = true
UNLESS,0 = true
UNLESS, = true

OR,true,true = true
OR,true,false = true
OR,false,true = true
OR,false,false = false

MAKE.is.aix = $(BOOL,$(BOOL,$(CCC:xlC%=1)))
MAKE.is.gnu = $(BOOL,$(shell echo true 2>/dev/null))

OS.exec = uname -s | LC_ALL=C tr '[A-Z]' '[a-z]'
OS.if.MAKE.is.aix,true = aix
OS.if.MAKE.is.aix,false = $(shell $(OS.exec))$(OS.exec:sh)
OS = $(OS.if.MAKE.is.aix,$(MAKE.is.aix))
OS.eq.$(OS),$(OS) = true
OS.eq.bsd,bsd = true
OS.eq.bsd,darwin = true
OS.is.aix = $(BOOL,$(OS.eq.aix,$(OS)))
OS.is.bsd.OS.prefix = $(OS:%bsd=%)
OS.is.bsd.OS.suffix = $(OS:$(OS.is.bsd.OS.prefix)%=%)
OS.is.bsd = $(OR,$(BOOL,$(OS.eq.bsd,$(OS))),$(BOOL,$(OS.eq.bsd,$(OS.is.bsd.OS.suffix))))
OS.is.darwin = $(BOOL,$(OS.eq.darwin,$(OS)))
OS.is.freebsd = $(BOOL,$(OS.eq.freebsd,$(OS)))
OS.is.linux = $(BOOL,$(OS.eq.linux,$(OS)))
OS.is.openbsd = $(BOOL,$(OS.eq.openbsd,$(OS)))
OS.is.netbsd = $(BOOL,$(OS.eq.netbsd,$(OS)))
OS.is.sunos = $(BOOL,$(OS.eq.sunos,$(OS)))
.PHONY: $(eval OS := $(OS))

DL.libs = $(UNLESS,$(OS.is.bsd):%=-ldl)

RT.libs = $(IF,$(OS.is.linux):%=-lrt)

# Usage: $(SOFLAGS.bundle) - for creating shared objects to be dlopen'd
SOFLAGS.bundle.aix = -Wl,-G
SOFLAGS.bundle.darwin = -bundle
SOFLAGS.bundle.other = -shared
SOFLAGS.bundle.if.aix,true = $(SOFLAGS.bundle.aix)
SOFLAGS.bundle.if.aix,false = $(SOFLAGS.bundle.if.darwin,$(OS.is.darwin))
SOFLAGS.bundle.if.darwin,true = $(SOFLAGS.bundle.darwin)
SOFLAGS.bundle.if.darwin,false = $(SOFLAGS.bundle.other)
SOFLAGS.bundle = $(SOFLAGS.bundle.if.aix,$(OS.is.aix))

# Usage: $(SOFLAGS.shared) - for creating regular shared libraries
SOFLAGS.shared.darwin = -dynamiclib
SOFLAGS.shared.other = -shared
SOFLAGS.shared.if.darwin,true = $(SOFLAGS.bundle.darwin)
SOFLAGS.shared.if.darwin,false = $(SOFLAGS.bundle.other)
SOFLAGS.shared = $(SOFLAGS.shared.if.darwin,$(OS.is.darwin))

# Usage: $(SOFLAGS.soname:%=%$(SONAME))
SOFLAGS.soname.aix =
SOFLAGS.soname.darwin =
SOFLAGS.soname.other = -Wl,-soname,
SOFLAGS.soname.if.aix,true = $(SOFLAGS.soname.aix)
SOFLAGS.soname.if.aix,false = $(SOFLAGS.soname.if.darwin,$(OS.is.darwin))
SOFLAGS.soname.if.darwin,true = $(SOFLAGS.soname.darwin)
SOFLAGS.soname.if.darwin,false = $(SOFLAGS.soname.other)
SOFLAGS.soname = $(SOFLAGS.soname.if.aix,$(OS.is.aix))

# Usage: $(SOFLAGS.undefined:%=% dynamic_lookup)
SOFLAGS.undefined = $(IF,$(OS.is.darwin):%=-undefined)


# For now, just download binaries
# TODO: Build from source


LUA_VERSION = $(shell $(LUA) -e "print(_VERSION:match(\"Lua (.*)\"))")
ARCH = x64

ifeq ($(OS), darwin)
	YUE_URL = https://github.com/yue/yue/releases/download/v$(YUE_VERSION)/lua_yue_lua_$(LUA_VERSION)_v$(YUE_VERSION)_mac_$(ARCH).zip
else ifeq ($(OS), windows)
	YUE_URL = https://github.com/yue/yue/releases/download/v$(YUE_VERSION)/lua_yue_lua_$(LUA_VERSION)_v$(YUE_VERSION)_win_$(ARCH).zip
else
	YUE_URL = https://github.com/yue/yue/releases/download/v$(YUE_VERSION)/lua_yue_lua_$(LUA_VERSION)_v$(YUE_VERSION)_linux_$(ARCH).zip
endif

ifeq ($(OS), windows)
	YUE_DLL = yue.dll
	DL = C:\\windows\\system32\\curl.exe -L
else
	YUE_DLL = yue.so
	DL = $(CURL) -L
endif

UNZIP = tar -xzf

build:
	@echo "Building..."
	@echo "Downloading $(YUE_URL)..."
	$(DL) $(YUE_URL) -o yue.zip
	@echo "Done."

	@echo "Unzipping yue.zip..."
	$(UNZIP) yue.zip
	@echo "Done."

# will always be run after build
install:
	@echo "Installing..."

	cp $(YUE_DLL) $(INST_LIBDIR)/$(YUE_DLL)

	@echo "Done."


clean:
	rm -rf yue.zip $(YUE_DLL)
