local INSTALL_FILE = "install.lua"

package = "luayue-bin"
version = "dev-6"
source = {
    url = "git+https://github.com/Frityet/luayue",
    branch = "main"
}
description = {
    homepage = "https://github.com/yue/yue",
    license = "LGPLv3",
    detailed = "Binary releases for yue"
}
dependencies = {
    "lua >= 5.1, < 5.5"
}

local env = {
    "CURL=$(CURL)",
    "YUE_VERSION=latest",
    "INST_LIBDIR=$(LIBDIR)",
    "WGET=$(WGET)",
    "TAR=$(TAR)",
    "UNZIP=$(UNZIP)",
}

local env_str = ""
for i = 1, #env do env_str = env_str..'"'..env[i]..'" ' end

---@param plat string
---@return { build_command: string, install_command: string }
local function getcmd(plat)
    local function decorate(cmd)
        if plat == "win" then
            return "cmd /c "..cmd
        else
            return cmd
        end
    end

    return {
        build_command   = decorate "'$(LUA)' "..INSTALL_FILE.." download "..plat.." "..env_str,
        install_command = decorate "'$(LUA)' "..INSTALL_FILE.." install "..plat.." "..env_str
    }
end

build = {
    type = "command",
    platforms = {
        unix = getcmd "linux",
        macosx = getcmd "mac",
        win32 = getcmd "win",
        mingw32 = getcmd "win"
    }
}