local json = require("json")

---@type "build" | "install"
local action = arg[1]

---@type "mac" | "linux" | "win32"
os.name = arg[2]

--TODO: support arm64
os.arch = "x64"

---@type string
local LUA_VERSION = _VERSION:match("Lua (.*)")

---@type { [string] : string }
local env = {}

for i = 3, #arg do
    local k, v = arg[i]:match("(.+)=(.+)")
    env[k] = v
end

---Cross platform GET
---@param url string
---@return string? body, string? error, string? command
local function get(url)
    --Use system `curl.exe` on Windows because its ACTUALLY curl
    local exe = os.name == "win32" and "C:\\Windows\\System32\\curl.exe" or env.CURL
    local is_wget = false

    if exe == nil or exe == "" then
        exe = env.WGET
        is_wget = true
        if exe == nil or exe == "" then
            return nil, "curl or wget not found"
        end
    end

    --io popen
    if is_wget then
        local cmd = exe.." -L --max-redirect=5 "..url
        print("$ "..cmd)
        local f = assert(io.popen(cmd))
        local body = f:read("*a")
        f:close()

        return body
    else
        local cmd = exe.." -L "..url
        print("$ "..cmd)
        local f = assert(io.popen(cmd))
        local body = f:read("*a")
        f:close()

        return body
    end
end

---Cross platform download. Must work on all platforms.
---@param url string
---@param to string
---@return boolean success, string? error, string? command
local function download(url, to)
    local body, err, cmd = get(url)
    if not body then return false, err, cmd end

    local f = assert(io.open(to, "wb"))
    f:write(body)
    f:close()

    return true
end

---@param file string Archive to unzip
---@param to string Location to unzip to
---@return boolean success, string? error, string? command
local function unzip(file, to)
    local tar = env.TAR
    if not tar then tar = "tar" end

    local cmd = tar.." -xf "..file.." -C "..to
    print("$ "..cmd)
    local ok = os.execute(cmd)

    if not ok then return false, "tar failed", cmd end

    return true
end


local yue_zip = "yue.zip"

print(action.."ing Yue "..env.YUE_VERSION.." for ".._VERSION.." on "..os.name)
if action == "build" then
    local tag = "v"
    if env.YUE_VERSION == "latest" then
        local url = "https://api.github.com/repos/yue/yue/releases/latest"
        local body, err, cmd = get(url)
        if not body then error(err.."\nCommand: "..cmd) end

        local data = json.decode(body)
        if not data then error("Failed to decode JSON") end

        tag = data.tag_name:match("v(.+)")

        env.YUE_VERSION = tag
    end

    local url = "https://api.github.com/repos/yue/yue/releases/tags/v"..tag

    local body, err, cmd = get(url)
    if not body then error(err.."\nCommand: "..cmd) end

    local data = json.decode(body)
    if not data then error("Failed to decode JSON") end

    local assets = data.assets

    --we only want the binary releases, so search through the assets for one that matches our lua ver, os, and arch
    ---@type string
    local url
    do
        for _, asset in ipairs(assets) do
            --Example: https://github.com/yue/yue/releases/download/v0.13.13/lua_yue_lua_5.4_v0.13.13_linux_x64.zip
            local asset_url = asset.browser_download_url

            local yue_ver, lua_ver, osname, arch =
                asset_url:match("https://github.com/yue/yue/releases/download/v(%d+.%d+.%d+)/lua_yue_lua_(.+)_v%d+.%d+.%d+_(.+)_(.+).zip")

            local matching = lua_ver == LUA_VERSION and yue_ver == env.YUE_VERSION and osname == os.name and arch == os.arch
            if matching then
                url = asset_url
                break
            end
        end


        if not url then error("Failed to find a matching release") end
    end
    print("Downloading Yue from "..url.." to "..yue_zip)

    local ok, err, cmd = download(url, yue_zip)

    if not ok then error(err.."\nCommand: "..cmd) end
elseif action == "install" then
    print("Installing Yue from "..yue_zip)
    local ok, err, cmd = unzip(yue_zip, "./")
    if not ok then error(err.."\nCommand: "..cmd) end

    local yue_so = "yue.so"
    local yue_so_dest = env.INST_LIBDIR.."/yue.so"

    print("Copying "..yue_so.." to "..yue_so_dest)
    local ok, err = os.rename(yue_so, yue_so_dest)
    if not ok then error(err) end
else
    error("Unknown action: "..action)
end

print("Done!")
