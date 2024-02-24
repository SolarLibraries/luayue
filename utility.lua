local json = require("json")
local pprint = require("pprint")

local function print(...)
    for _, v in ipairs({...}) do
        if type(v) == "table" then
            pprint(v)
        else
            io.stderr:write(tostring(v), "\n")
        end
    end
end

---Write to stdout, so it can be piped
local function output(...) return io.stdout:write(..., "\n") end

---@alias Command
---| "download" Download the latest release and extract it
---| "install"  Install the latest release
---| "version"  Print the latest release version
---| "url"      Print the latest release url

---@type Command
local action = arg[1]

--TODO: support arm64
os.arch = "x64"

local GITHUB_API_KEY = os.getenv("GITHUB_API_KEY")
if GITHUB_API_KEY then print(("Using your github api key (%s) to stop ratelimiting"):format(GITHUB_API_KEY)) end

---@alias LuaVersion
---| "5.1"
---| "5.2"
---| "5.3"
---| "5.4"


---@type LuaVersion
local LUA_VERSION = _VERSION:match("Lua (.*)")

---@type { [string] : string }
local env = {}

for i = 2, #arg do
    local k, v = arg[i]:match("(.+)=(.+)")

    if k and v then env[k] = v end
end

env.YUE_VERSION = env.YUE_VERSION or "latest"
if env.YUE_VERSION ~= "latest" then env.YUE_VERSION = "v"..env.YUE_VERSION end

---@type "win" | "linux" | "mac"
local osname = env.OS
-- osname = osname == "darwin" and "mac" or osname
if osname == "darwin" then osname = "mac" elseif osname == "windows" then osname = "win" end

---@param cmd string
---@param ... string
---@return string? body, string? error, string? command
local function execute(cmd, ...)
    cmd = cmd.." "..table.concat({...}, " ")
    print("$ "..cmd)
    local f, err = io.popen(cmd, "r")
    if not f then return nil, err, cmd end
    local body = f:read("*a")
    local ok, err, code = f:close()
    if not ok then return nil, err end
    return body
end


---Cross platform GET
---@param url string
---@param headers table<string, string>?
---@param to string?
---@return string? body, string? error, string? command
local function get(url, headers, to)
    local is_wget = false
    local exe = env.DL
    if exe == nil or exe == "" then
        exe = env.CURL or (osname == "win" and "curl.exe" or "curl")

        --check, if not use WGET
        if not execute(exe, "--version") then
            exe = env.WGET or (osname == "win" and "wget.exe" or "wget")
            is_wget = true
        end
    end

    headers = headers or {}

    local cmd
    if is_wget then
        cmd = exe.." -L --max-redirect=5 "..url
        for k, v in pairs(headers) do
            cmd = cmd.." --header \""..k..": "..v.."\""
        end
        if to then cmd = cmd.." -o "..to end
    else
        cmd = exe.." -L "..url
        for k, v in pairs(headers) do
            cmd = cmd.." -H \""..k..": "..v.."\""
        end
        if to then cmd = cmd.." -o "..to end
    end

    return execute(cmd)
end

---Cross platform download. Must work on all platforms.
---@param url string
---@param to string
---@return boolean success, string? error, string? command
local function download(url, to)
    local ok, err, cmd = get(url, nil, to) 
    if not ok then return false, err, cmd end
    return true
    -- local body, err, cmd = get(url)
    -- if not body then return false, err, cmd end

    -- local f = io.open(to, "w+b")
    -- if not f then return false, "Failed to open file "..to.." for writing" end
    -- f:write(body)
    -- f:close()

    -- return true
end

---@param file string Archive to unzip
---@param to string? Location to unzip to
---@return boolean success, string? error, string? command
local function unzip(file, to)
    to = to or "./"
    execute("mkdir", to)
    local tar = env.TAR or "tar"
    local ok, err, cmd = execute(tar, "-xzvf", file, "-C", to)
    if not ok then return false, err, cmd end

    if not ok then
        print("Tar failed, trying unzip")

        local unzip = env.UNZIP or "unzip"
        local ok, err, cmd = execute(unzip, file, "-d", to)
        if not ok then return false, err, cmd end
    end

    return true
end

---@param from string
---@param to string
---@return boolean ok, string? err
local function copy(from, to)
    local from_f, err = io.open(from, "rb")
    if not from_f then return false, err end
    local to_f, err = io.open(to, "w+b")
    if not to_f then return false, err end

    local from_contents, err = from_f:read("a")
    if not from_contents then return false, err end

    local ok, err = to_f:write(from_contents)
    if not ok then return false, err end

    return true
end

local API_ENDPOINT = "https://api.github.com/repos/yue/yue/releases"

local releases = assert(json.decode(assert(get(API_ENDPOINT, {
    ["Accept"] = "application/vnd.github+json",
    ["Authorization"] = GITHUB_API_KEY and "Bearer "..GITHUB_API_KEY or ""
}))))
if releases.message then error("Failed to get releases: "..releases.message) end

---@type { [Command] : fun(args: string[]) }
local commands = {
    download = function (...)
        local release = releases
        if env.YUE_VERSION and env.YUE_VERSION ~= "latest" then
            for _, r in ipairs(releases) do
                if r.tag_name == env.YUE_VERSION then
                    release = r
                    break
                end
            end
        else
            release = releases[1]
            env.YUE_VERSION = release.tag_name
            print("Using latest release: "..env.YUE_VERSION)
        end


        ---@type any
        local asset do
            for _, a in ipairs(release.assets) do
                local s = string.format("lua_yue_lua_%s_%s_%s_%s.zip", LUA_VERSION, env.YUE_VERSION, osname, os.arch)
                print("Checking "..a.name.." against "..s)
                local ok = a.name:match(s)
                if ok then
                    asset = a
                    break
                end
            end
        end

        if not asset then
            error("Failed to find asset")
        end

        assert(download(asset.browser_download_url, asset.name))

        -- if osname == "win" then
        --     execute("rmdir", "/S", "yue-bin")
        -- else
        --     execute("rm", "-r", "yue-bin")
        -- end
        execute("rmdir", osname == "win" and "/S /Q" or "--ignore-fail-on-non-empty", "yue-bin")
        assert(unzip(asset.name, "yue-bin"))
    end;

    install = function (args)
        local to = args[1] or env.LUA_LIBDIR or "./"
        local from = "./yue.so"

        assert(copy(from, to))
    end;

    version = function (...)
    --- YUE_TAG = $(shell $(LUA) utility.lua version "YUE_VERSION=$(YUE_VERSION)" "DL=$(CURL)" "OS=$(OS)")
        if env.YUE_VERSION == "latest" then
            output(releases[1].tag_name)
        else
            output(env.YUE_VERSION)
        end
    end;

    url = function (...)
        local release = releases
        if env.YUE_VERSION and env.YUE_VERSION ~= "latest" then
            for _, r in ipairs(releases) do
                if r.tag_name == env.YUE_VERSION then
                    release = r
                    break
                end
            end
        else
            release = releases[1]
            env.YUE_VERSION = release.tag_name
        end


        ---@type string
        local asset do
            for _, a in ipairs(release.assets) do
                --example :libyue_v0.14.1_mac.zip
                local s = string.format("libyue_%s_%s.zip", env.YUE_VERSION, osname)
                local ok = a.name:match(s)
                if ok then
                    asset = a --[[@as string]]
                    break
                end
            end
        end

        if not asset then error("Failed to find asset") end

        output(asset.browser_download_url)
    end;
}

-- if osname == "windows" then
--     return require("download-bin-windows")(
--         env.YUE_VERSION,
--         LUA_VERSION,
--         releases,
--         {
--             copy = copy,
--             execute = execute,
--             download = download,
--             get = get
--         }
--     )
-- end

--all non KEY=VALUE args are passed to the command
local args = {}
for i = 2, #arg do
    local k, v = arg[i]:match("(.+)=(.+)")

    if not k or not v then
        table.insert(args, arg[i])
    end
end

commands[action](args)
