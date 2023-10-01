local YUE_VERSION = "0.14.1"
package = "luayue"
version = YUE_VERSION..".bin-1"
source = {
   url = "git+https://github.com/Frityet/luayue",
   branch = "compile",
   tag = "v"..YUE_VERSION.."-bin"
}
description = {
   detailed = "Binary releases for yue",
   homepage = "https://github.com/yue/yue",
   license = "LGPLv3"
}
dependencies = {
   "lua >= 5.1, < 5.5"
}
build = {
   type = "make",
   build_variables = {
      CC = "$(CC)",
      CFLAGS = "$(CFLAGS)",
      CURL = "$(CURL)",
      CXX = "$(CXX)",
      LIBFLAG = "$(LIBFLAG)",
      LUA = "$(LUA)",
      LUA_BINDIR = "$(LUA_BINDIR)",
      LUA_INCDIR = "$(LUA_INCDIR)",
      LUA_LIBDIR = "$(LUA_LIBDIR)",
      YUE_VERSION = YUE_VERSION
   },
   install_variables = {
      INST_BINDIR = "$(BINDIR)",
      INST_CONFDIR = "$(CONFDIR)",
      INST_LIBDIR = "$(LIBDIR)",
      INST_LUADIR = "$(LUADIR)",
      INST_PREFIX = "$(PREFIX)"
   },
   makefile = "Makefile",

   build_target = "download-bin",
   install_target = "install-bin"
}
