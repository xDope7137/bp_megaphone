local STATE = 'bp_megaphone'
local COOLDOWN = 500

local active = {}
local lastUse = {}

local Lib = exports.bp_lib:Core()
local framework = exports.bp_lib:GetConfig().Framework

local function hasMegaphone(src)
    return Lib.Inventory.HasPlayerItem(src, Config.Item, 1) == true
end

local function setActive(src, on)
    active[src] = on or nil
    Player(src).state:set(STATE, on, true)
end

local function toggle(src)
    local now = GetGameTimer()
    if lastUse[src] and now - lastUse[src] < COOLDOWN then return end
    lastUse[src] = now

    if active[src] then
        setActive(src, false)
    elseif hasMegaphone(src) then
        setActive(src, true)
    end
end

Lib.Inventory.RegisterUsableItem(Config.Item, function(src) toggle(src) end)

-- Client export (ox_inventory client.export, radial menus). The item check stays here.
RegisterNetEvent('bp_megaphone:use', function()
    toggle(source)
end)

-- The client puts the megaphone away on death, vehicles, cuffs. Turning off is always allowed.
RegisterNetEvent('bp_megaphone:stop', function()
    local src = source
    if active[src] then setActive(src, false) end
end)

-- Clients may write their own state bags. Only this file turns the megaphone on.
AddStateBagChangeHandler(STATE, nil, function(bagName, _, value, _, replicated)
    if not replicated or not value then return end
    local src = GetPlayerFromStateBagName(bagName)
    if src and src ~= 0 and not active[src] then
        Player(src).state:set(STATE, false, true)
    end
end)

-- Item dropped, sold or taken while in use.
CreateThread(function()
    while true do
        Wait(2000)
        for src in pairs(active) do
            if not hasMegaphone(src) then setActive(src, false) end
        end
    end
end)

------------------------------------------------------------------------
-- Police lines
------------------------------------------------------------------------

local Lines = Config.Lines
local lastLine = {}

-- bp_lib has no duty getter, so duty is read from the framework. ESX has no duty.
local function onDuty(src)
    if framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.job.onduty
    end
    if framework == 'qb' then
        local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        return player and player.PlayerData.job.onduty
    end
    return true
end

local allowedJobs = {}
for _, name in ipairs(Lines.jobs or {}) do allowedJobs[name] = true end

local function canUseLines(src)
    if not Lines.jobs or IsPlayerAceAllowed(src, 'bp_megaphone.lines') then return true end
    local job = Lib.Framework.Job.Get(src)
    if not job or not allowedJobs[job] then return false end
    return not Lines.onDutyOnly or onDuty(src) == true
end

local function notify(src, textKey, kind)
    TriggerClientEvent('bp_megaphone:notify', src, textKey, kind or 'error')
end

RegisterNetEvent('bp_megaphone:line', function(lineIndex, voiceIndex)
    local src = source
    if not Lines.enabled then return end
    local line = type(lineIndex) == 'number' and Lines.list[lineIndex]
    local voice = type(voiceIndex) == 'number' and Lines.voices[voiceIndex]
    if not line or not voice then return end

    if not active[src] then return notify(src, 'needMegaphone') end
    if not canUseLines(src) then return notify(src, 'notAllowed') end

    local now = GetGameTimer()
    if lastLine[src] and now - lastLine[src] < Lines.cooldown * 1000 then
        return notify(src, 'wait', 'info')
    end
    lastLine[src] = now

    local origin = GetEntityCoords(GetPlayerPed(src))
    for _, id in ipairs(GetPlayers()) do
        local target = tonumber(id)
        if #(GetEntityCoords(GetPlayerPed(target)) - origin) <= Lines.range then
            TriggerClientEvent('bp_megaphone:playLine', target, src, line.speech, voice.voice)
        end
    end
end)

AddEventHandler('playerDropped', function()
    active[source] = nil
    lastUse[source] = nil
    lastLine[source] = nil
end)

-- A restart forgets who was active, so clear any state left from the last run.
for _, id in ipairs(GetPlayers()) do
    local src = tonumber(id)
    if Player(src).state[STATE] then
        Player(src).state:set(STATE, false, true)
    end
end
