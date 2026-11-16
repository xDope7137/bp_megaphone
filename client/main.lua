local STATE = 'bp_megaphone'
local Lib = exports.bp_lib:Core()
local hasPma = GetResourceState('pma-voice') == 'started'

local submix = CreateAudioSubmix('bp_megaphone')
SetAudioSubmixEffectRadioFx(submix, 0)
SetAudioSubmixEffectParamInt(submix, 0, joaat('default'), 1)
for param, value in pairs(Config.Effect) do
    SetAudioSubmixEffectParamFloat(submix, 0, joaat(param), value + 0.0)
end
AddAudioSubmixOutput(submix, 0)

------------------------------------------------------------------------
-- Listening: how other players sound to us
------------------------------------------------------------------------

local speakers = {}

local function setListener(serverId, on)
    if on then
        MumbleSetSubmixForServerId(serverId, submix)
        if Config.Volume then MumbleSetVolumeOverrideByServerId(serverId, Config.Volume + 0.0) end
    else
        MumbleSetSubmixForServerId(serverId, -1)
        if Config.Volume then MumbleSetVolumeOverrideByServerId(serverId, -1.0) end
    end
    speakers[serverId] = on or nil
end

-- pma-voice resets a player's submix after each radio or phone call, and players who
-- come into range later never saw the state change. Re-check once a second.
CreateThread(function()
    local me = PlayerId()
    while true do
        Wait(1000)
        local seen = {}
        for _, ply in ipairs(GetActivePlayers()) do
            if ply ~= me then
                local serverId = GetPlayerServerId(ply)
                if Player(serverId).state[STATE] then
                    seen[serverId] = true
                    setListener(serverId, true)
                end
            end
        end
        for serverId in pairs(speakers) do
            if not seen[serverId] then setListener(serverId, false) end
        end
    end
end)

------------------------------------------------------------------------
-- Speaking: our own megaphone
------------------------------------------------------------------------

local using = false
local prop

local function shouldStop(ped)
    return IsEntityDead(ped)
        or IsPedSwimming(ped)
        or IsPedCuffed(ped)
        or (Config.StopInVehicle and IsPedInAnyVehicle(ped, true))
end

local function removeProp()
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil
end

local function attachProp(ped)
    removeProp()
    local p = Config.Prop
    local model = lib.requestModel(p.model)
    if not model then return end
    prop = CreateObject(model, GetEntityCoords(ped), true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, p.bone),
        p.offset.x, p.offset.y, p.offset.z, p.rotation.x, p.rotation.y, p.rotation.z,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

local function stopSpeaking()
    if not using then return end
    using = false
    StopAnimTask(cache.ped, Config.Anim.dict, Config.Anim.clip, 2.0)
    removeProp()
    if hasPma then exports['pma-voice']:clearProximityOverride() end
end

local function startSpeaking()
    if using then return end
    local ped = cache.ped
    if shouldStop(ped) then
        TriggerServerEvent('bp_megaphone:stop')
        return
    end

    using = true
    if hasPma then exports['pma-voice']:overrideProximityRange(Config.Range + 0.0, true) end
    lib.requestAnimDict(Config.Anim.dict)
    attachProp(ped)

    CreateThread(function()
        while using do
            ped = cache.ped
            if shouldStop(ped) then
                TriggerServerEvent('bp_megaphone:stop')
                stopSpeaking()
                break
            end
            if not prop or not DoesEntityExist(prop) or not IsEntityAttachedToEntity(prop, ped) then
                attachProp(ped)
            end
            if not IsPedRagdoll(ped) and not IsEntityPlayingAnim(ped, Config.Anim.dict, Config.Anim.clip, 3) then
                TaskPlayAnim(ped, Config.Anim.dict, Config.Anim.clip, 3.0, 3.0, -1, 49, 0, false, false, false)
            end
            Wait(250)
        end
    end)
end

AddStateBagChangeHandler(STATE, nil, function(bagName, _, value)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply == 0 then return end
    if ply == PlayerId() then
        if value then startSpeaking() else stopSpeaking() end
    else
        setListener(GetPlayerServerId(ply), value == true)
    end
end)

------------------------------------------------------------------------
-- Police lines
------------------------------------------------------------------------

local Lines = Config.Lines
local SPEECH_PARAM = 'SPEECH_PARAMS_FORCE_MEGAPHONE'

RegisterNetEvent('bp_megaphone:playLine', function(serverId, speech, voice)
    if GetInvokingResource() then return end
    local ply = GetPlayerFromServerId(serverId)
    if ply == -1 then return end
    local ped = GetPlayerPed(ply)
    if not DoesEntityExist(ped) then return end
    StopCurrentPlayingAmbientSpeech(ped)
    PlayPedAmbientSpeechWithVoiceNative(ped, speech, voice, SPEECH_PARAM, false)
end)

local function voiceIndex()
    local i = GetResourceKvpInt('lines_voice')
    return Lines.voices[i] and i or 1
end

local function notify(textKey, kind)
    Lib.Notify(Config.Text.title, Config.Text[textKey], kind or 'error')
end

RegisterNetEvent('bp_megaphone:notify', function(textKey, kind)
    if GetInvokingResource() or type(Config.Text[textKey]) ~= 'string' then return end
    notify(textKey, kind)
end)

local function openLines()
    if not using then return notify('needMegaphone') end

    local current = voiceIndex()
    local options = {
        {
            title = Config.Text.voice:format(Lines.voices[current].label),
            description = Config.Text.voiceHint,
            icon = 'user',
            event = 'bp_megaphone:menu',
            args = { voice = true },
        },
    }
    for i, line in ipairs(Lines.list) do
        options[#options + 1] = {
            title = line.label,
            icon = 'bullhorn',
            event = 'bp_megaphone:menu',
            args = { line = i },
        }
    end
    Lib.Menu(Config.Text.linesTitle, options)
end

-- Menu picks arrive as a local event so the menu works with whichever menu bp_lib uses.
AddEventHandler('bp_megaphone:menu', function(args)
    if type(args) ~= 'table' then return end
    if args.voice then
        SetResourceKvpInt('lines_voice', voiceIndex() % #Lines.voices + 1)
    elseif type(args.line) == 'number' then
        TriggerServerEvent('bp_megaphone:line', args.line, voiceIndex())
    end
    if using then openLines() end
end)

if Lines.enabled then
    if Lines.command then RegisterCommand(Lines.command, openLines, false) end
    if Lines.key then
        lib.addKeybind({
            name = 'bp_megaphone_lines',
            description = Config.Text.keybind,
            defaultKey = Lines.key,
            onPressed = function()
                if using then openLines() end
            end,
        })
    end
end

exports('openLines', openLines)

-- For ox_inventory (client.export = 'bp_megaphone.useMegaphone') or a radial menu.
exports('useMegaphone', function()
    TriggerServerEvent('bp_megaphone:use')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopSpeaking()
    for serverId in pairs(speakers) do setListener(serverId, false) end
end)
