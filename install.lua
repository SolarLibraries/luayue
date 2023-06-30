local YUE_URL_FMT = "https://github.com/yue/yue/releases/download/v%s/lua_yue_lua_%s_v%s_%s_%s.zip"

---@type "build" | "install"
local action = arg[1]

---@type "mac" | "linux" | "win32"
os.name = arg[2]

--TODO: support arm64
os.arch = "x64"

---@type { [string] : string }
local env = {}

for i = 3, #arg do
    local k, v = arg[i]:match("(.+)=(.+)")
    env[k] = v
end

---Cross platform download. Must work on all platforms.
---@param url string
---@param to string
---@return boolean success, string? error, string? command
local function download(url, to)
    --Use system `curl.exe` on Windows.
    local exe = os.name == "win32" and "C:\\Windows\\System32\\curl.exe" or env.CURL

    local is_wget = false

    --if curl not found, use env.WGET
    if exe == nil or exe == "" then
        exe = env.WGET
        is_wget = true
        if exe == nil or exe == "" then
            return false, "curl or wget not found"
        end
    end

    if is_wget then
        local cmd = exe.." -L --max-redirect=5 -O "..to.." "..url
        print("$ "..cmd)
        local ok = os.execute(cmd)

        if not ok then return false, "wget failed", cmd end
    else
        local cmd = exe.." -L -o "..to.." "..url
        print("$ "..cmd)
        local ok = os.execute(cmd)

        if not ok then return false, "curl failed", cmd end
    end

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
-- local url=$(printf "$YUE_URL_FMT" "$YUE_VERSION" "$LUA_VERSION" "$YUE_VERSION" "$os" "$ARCH")

print(action.."ing Yue "..env.YUE_VERSION.." for ".._VERSION.." on "..os.name)
if action == "build" then
    local url = YUE_URL_FMT:format(env.YUE_VERSION, _VERSION:match("Lua (.*)"), env.YUE_VERSION, os.name, os.arch)

    print("Downloading Yue from "..url.." to "..yue_zip)
    local ok, err, cmd = download(url, yue_zip)
    if not ok then error(err.."\nCommand: "..cmd) end
elseif action == "install" then
    print("Installing Yue from "..yue_zip)
    local ok, err, cmd = unzip(yue_zip, "./")
    if not ok then error(err.."\nCommand: "..cmd) end

    --copy yue/yue.so to the install dir
    local yue_so = "yue.so"
    local yue_so_dest = env.INST_LIBDIR.."/yue.so"

    print("Copying "..yue_so.." to "..yue_so_dest)
    local ok, err = os.rename(yue_so, yue_so_dest)
    if not ok then error(err) end
else
    error("Unknown action: "..action)
end

print("Done!")
