--[[
    unexpected · loader
    ------------------------------------------------------------------
    Das ist das EINZIGE Script, das du ausführen musst.

    Es lädt:
      1. src/core.lua            -> GUI + Command-Registry
      2. src/commands/*.lua      -> die Command-Packs

    Wenn du eigene Packs hinzufügen willst, einfach unten in PACKS
    eintragen. Die Packs werden mit loadstring geladen und können
    über getgenv().unexpected neue Commands registrieren.

    BASE_URL musst du auf deinen eigenen GitHub-Raw-Pfad setzen.
]]

local BASE_URL = "https://raw.githubusercontent.com/hashed-cmd/unexpected-cmd/refs/heads/main/"


Zeile 18
local CORE = "src/core.lua"

local PACKS = {
    "src/commands/movement.lua",
    "src/commands/fun.lua",
    "src/commands/utility.lua",
}

-- ------------------------------------------------------------------

local ENV = getgenv()

if ENV.unexpected_loading then
    return
end
ENV.unexpected_loading = true

-- core.lua nutzt das für keepUX (re-exec nach Teleport)
ENV.unexpected_source_url = BASE_URL .. "loader.lua"

local function buildUrl(path)
    local separator = path:find("?", 1, true) and "&" or "?"
    return BASE_URL .. path .. separator .. "t=" .. tostring(os.time())
end

local function fetch(path)
    local ok, body = pcall(function()
        return game:HttpGet(buildUrl(path))
    end)

    if not ok then
        return nil, tostring(body)
    end

    if type(body) ~= "string" or body == "" then
        return nil, "empty response"
    end

    return body
end

local function runChunk(path, source)
    if type(loadstring) ~= "function" then
        return false, "loadstring is not supported by this executor"
    end

    local chunk, err = loadstring(source, "=unexpected/" .. path)
    if not chunk then
        return false, err
    end

    local ok, result = pcall(chunk)
    if not ok then
        return false, result
    end

    return true, result
end

local function loadModule(path)
    local source, err = fetch(path)
    if not source then
        return false, err
    end
    return runChunk(path, source)
end

local coreOk, coreErr = loadModule(CORE)

if not coreOk then
    ENV.unexpected_loading = false
    return warn("[unexpected] failed to load core: " .. tostring(coreErr))
end

for _, pack in ipairs(PACKS) do
    local packOk, packErr = loadModule(pack)
    if not packOk then
        warn("[unexpected] failed to load " .. pack .. ": " .. tostring(packErr))
    end
end

ENV.unexpected_loading = false
