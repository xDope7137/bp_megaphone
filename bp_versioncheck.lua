--[[
    BP Development version checker. Server only, no dependencies.

    Canonical copy: store/scripts/versions/bp_versioncheck.lua.
    `node scripts/versions.mjs install` copies it into every resource, so edit
    it there, never inside a resource folder.

    On start it reads this resource's `version` from fxmanifest.lua, fetches
    https://tebex.bhavikp.in/versions/<script>.json and, when the server is
    behind, prints every release it is missing with the change notes.

    <script> is the `bp_script` fxmanifest entry, falling back to the folder
    name, so a renamed folder keeps checking against the right file.

    Server convars (server.cfg):
        set bp_versioncheck 0              turn the check off for every BP script
        set bp_versioncheck_releases 5     most releases printed per script (default 5)
        set bp_versioncheck_hours 6        re-check interval in hours, 0 = start only

    Console commands (or any principal with the matching command ACE):
        bp_versions                        one status line per running BP script
        bp_changelog <script> [count]      print a script's changelog
]]

local BASE_URL = 'https://tebex.bhavikp.in'
local SCHEMA = 1

local resource = GetCurrentResourceName()
local scriptId = GetResourceMetadata(resource, 'bp_script', 0) or resource
local current = GetResourceMetadata(resource, 'version', 0)

-- Last fetched document and the newest version a notice was printed for, so
-- the periodic re-check stays quiet until something new is published.
local latest
local noticed

local TYPES = {
    added    = { mark = '+', colour = '^2' },
    changed  = { mark = '~', colour = '^5' },
    fixed    = { mark = '*', colour = '^3' },
    removed  = { mark = '-', colour = '^1' },
    security = { mark = '!', colour = '^1' },
}

local function enabled()
    local value = GetConvar('bp_versioncheck', 'true'):lower()
    return value ~= '0' and value ~= 'false' and value ~= 'off'
end

local function out(line)
    print(line .. '^0')
end

local function tag()
    return ('^5[%s]^0 '):format(resource)
end

--- '1.2.10-beta' -> { 1, 2, 10 }. Anything after the numbers is ignored.
local function parse(version)
    if type(version) ~= 'string' then return nil end
    local core = version:match('^%s*v?([%d%.]+)')
    if not core then return nil end
    local parts = {}
    for n in core:gmatch('%d+') do parts[#parts + 1] = tonumber(n) end
    return #parts > 0 and parts or nil
end

--- -1 when a < b, 0 when equal, 1 when a > b. Missing parts count as 0.
local function compare(a, b)
    local pa, pb = parse(a), parse(b)
    if not pa or not pb then return nil end
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then return x < y and -1 or 1 end
    end
    return 0
end

local function wrap(text, width, indent)
    local lines, line = {}, ''
    for word in tostring(text):gmatch('%S+') do
        if #line > 0 and #line + 1 + #word > width then
            lines[#lines + 1] = line
            line = word
        else
            line = #line > 0 and (line .. ' ' .. word) or word
        end
    end
    if #line > 0 then lines[#lines + 1] = line end
    return table.concat(lines, '\n' .. indent)
end

local function absolute(path)
    if type(path) ~= 'string' or path == '' then return nil end
    if path:find('^https?://') then return path end
    return BASE_URL .. path
end

local function printRelease(release)
    local head = ('  ^7%s^0'):format(release.version)
    if release.date then head = head .. (' ^9(%s)^0'):format(release.date) end
    if release.critical then head = head .. '  ^1REQUIRED^0' end
    out(head)
    if release.summary and release.summary ~= '' then
        out('    ' .. wrap(release.summary, 96, '    '))
    end
    for _, change in ipairs(release.changes or {}) do
        local style = TYPES[change.type] or TYPES.changed
        out(('    %s%s^0 %s'):format(style.colour, style.mark, wrap(change.text, 92, '      ')))
    end
end

--- Releases newer than `from`, newest first, as published.
local function newerThan(doc, from)
    local list = {}
    for _, release in ipairs(doc.releases or {}) do
        if compare(release.version, from) == 1 then list[#list + 1] = release end
    end
    return list
end

local function fetch(id, cb)
    local url = ('%s/versions/%s.json'):format(BASE_URL, id)
    PerformHttpRequest(url, function(status, body)
        if status ~= 200 or not body then return cb(nil, ('HTTP %s'):format(status)) end
        local ok, doc = pcall(json.decode, body)
        if not ok or type(doc) ~= 'table' or type(doc.version) ~= 'string' then
            return cb(nil, 'unreadable response')
        end
        if (tonumber(doc.schema) or 0) > SCHEMA then
            -- A newer format: the fields read here are kept, so carry on.
            doc.newerSchema = true
        end
        cb(doc)
    end, 'GET', '', { ['Accept'] = 'application/json', ['User-Agent'] = 'bp_versioncheck/' .. SCHEMA })
end

local function report(doc)
    local cmp = compare(current, doc.version)
    if cmp == nil then
        return out(tag() .. ('^3could not compare version %s with %s^0'):format(tostring(current), doc.version))
    end
    if cmp == 0 then
        return out(tag() .. ('^2v%s is up to date^0'):format(current))
    end
    if cmp > 0 then
        return out(tag() .. ('^5v%s is newer than the published v%s^0'):format(current, doc.version))
    end

    local missing = newerThan(doc, current)
    local critical = false
    for _, release in ipairs(missing) do
        if release.critical then critical = true break end
    end

    local colour = critical and '^1' or '^3'
    local rule = colour .. ('-'):rep(72)
    out(rule)
    out(tag() .. ('%s%s: v%s -> v%s^0 (%d %s behind)'):format(
        colour, critical and 'Required update' or 'Update available', current, doc.version,
        #missing, #missing == 1 and 'release' or 'releases'))

    local limit = math.max(0, GetConvarInt('bp_versioncheck_releases', 5))
    for i = 1, math.min(limit, #missing) do printRelease(missing[i]) end
    if #missing > limit then
        out(('  ^9...and %d older %s^0'):format(#missing - limit, #missing - limit == 1 and 'release' or 'releases'))
    end

    local page, download = absolute(doc.page), absolute(doc.download)
    if page then out('  Changelog: ^4' .. page) end
    if download then out('  Download:  ^4' .. download) end
    out(rule)
end

local function check(quietWhenSame)
    if not enabled() then return end
    if not parse(current) then
        return out(tag() .. '^1no usable version in fxmanifest.lua, skipping the update check')
    end
    fetch(scriptId, function(doc, err)
        if not doc then
            if not quietWhenSame then out(tag() .. ('^9update check failed (%s)^0'):format(err)) end
            return
        end
        latest = doc
        if quietWhenSame and noticed == doc.version then return end
        if quietWhenSame and compare(current, doc.version) ~= -1 then return end
        noticed = doc.version
        report(doc)
    end)
end

-- Shared console commands. Every BP script carries this file, so only one of
-- them registers the commands and the rest answer through a local event. The
-- owner is kept in GlobalState so another copy takes over when it stops.

local OWNER_KEY = 'bp_versioncheck:owner'
local EVENT = 'bp_versioncheck:command'

local function statusLine()
    if not latest then
        return ('  ^5%-24s^0 v%-10s ^9not checked^0'):format(scriptId, tostring(current))
    end
    local cmp = compare(current, latest.version)
    local state = cmp == 0 and '^2up to date' or cmp == 1 and '^5ahead' or '^3update to v' .. latest.version
    return ('  ^5%-24s^0 v%-10s %s^0'):format(scriptId, tostring(current), state)
end

AddEventHandler(EVENT, function(kind, args)
    if kind == 'versions' then
        out(statusLine())
    elseif kind == 'changelog' and (args[1] == scriptId or args[1] == resource) then
        local count = tonumber(args[2]) or 10
        fetch(scriptId, function(doc, err)
            if not doc then return out(tag() .. '^1could not load the changelog: ' .. err) end
            latest = doc
            out(tag() .. ('%s, installed v%s, latest v%s'):format(doc.name or scriptId, tostring(current), doc.version))
            for i = 1, math.min(count, #(doc.releases or {})) do printRelease(doc.releases[i]) end
            local page = absolute(doc.page)
            if page then out('  Full changelog: ^4' .. page) end
        end)
    end
end)

local function claimCommands()
    local owner = GlobalState[OWNER_KEY]
    if owner and owner ~= resource then
        local state = GetResourceState(owner)
        if state == 'started' or state == 'starting' then return end
    end
    GlobalState[OWNER_KEY] = resource

    RegisterCommand('bp_versions', function()
        out('^5BP Development scripts^0')
        TriggerEvent(EVENT, 'versions', {})
    end, true)

    RegisterCommand('bp_changelog', function(_, args)
        if not args[1] then return out('^3usage: bp_changelog <script> [count]^0') end
        TriggerEvent(EVENT, 'changelog', args)
    end, true)
end

AddEventHandler('onResourceStop', function(stopped)
    if stopped == resource then
        if GlobalState[OWNER_KEY] == resource then GlobalState[OWNER_KEY] = nil end
    elseif stopped == GlobalState[OWNER_KEY] then
        SetTimeout(500, claimCommands)
    end
end)

CreateThread(function()
    claimCommands()
    -- Let the start-up noise scroll past so the notice is the last thing read.
    Wait(8000)
    check(false)

    local hours = GetConvarInt('bp_versioncheck_hours', 6)
    if hours <= 0 then return end
    while true do
        Wait(hours * 3600000)
        check(true)
    end
end)
