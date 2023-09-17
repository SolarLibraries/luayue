local YUE_VERSION = "0.14.0"
package = "luayue"
version = YUE_VERSION..".bin-1"
source = {
   url = "git+https://github.com/Frityet/luayue",
   branch = "main",
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
   type = "command",
   platforms = {
      macosx = {
         build_command = "'$(LUA)' install.lua download mac \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" ",
         install_command = "'$(LUA)' install.lua install mac \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" "
      },
      mingw32 = {
         build_command = "cmd /c '$(LUA)' install.lua download win \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" ",
         install_command = "cmd /c '$(LUA)' install.lua install win \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" "
      },
      unix = {
         build_command = "'$(LUA)' install.lua download linux \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" ",
         install_command = "'$(LUA)' install.lua install linux \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" "
      },
      win32 = {
         build_command = "cmd /c '$(LUA)' install.lua download win \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" ",
         install_command = "cmd /c '$(LUA)' install.lua install win \"CURL=$(CURL)\" \"YUE_VERSION="..YUE_VERSION.."\" \"INST_LIBDIR=$(LIBDIR)\" \"WGET=$(WGET)\" \"TAR=$(TAR)\" \"UNZIP=$(UNZIP)\" "
      }
   }
}
