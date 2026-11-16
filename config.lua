Config = {}

-- Inventory item that turns the megaphone on and off.
Config.Item = 'megaphone'

-- How far your voice carries while the megaphone is up, in metres (needs pma-voice).
Config.Range = 30.0

-- How loud others hear you, 0.0 to 1.0. Set to false to keep normal voice falloff.
Config.Volume = 0.9

-- Put the megaphone away when the player gets in a vehicle.
Config.StopInVehicle = true

-- Voice filter. Lower freq_low / higher freq_hi sounds cleaner, a narrower band sounds harsher.
Config.Effect = {
    freq_low = 300.0,
    freq_hi = 5000.0,
}

-- Police lines: stock GTA cop megaphone speech, played from the speaker for everyone in range.
-- Open the menu while the megaphone is up (key below, players can rebind it in FiveM settings).
Config.Lines = {
    enabled = true,
    key = 'J',
    command = 'megaphonelines',

    -- Jobs that may use the lines. false lets anyone with a megaphone use them.
    -- ACE permission bp_megaphone.lines always allows it.
    jobs = { 'police', 'sheriff', 'lspd', 'bcso', 'sasp', 'state' },
    onDutyOnly = true, -- QBCore/Qbox duty check, ignored on ESX

    cooldown = 3, -- seconds between lines
    range = 60.0, -- metres the line is heard

    -- Every voice below has every line below. The player picks one in the menu.
    voices = {
        { label = 'Officer (male)', voice = 'S_M_Y_COP_01_WHITE_FULL_01' },
        { label = 'Officer (male 2)', voice = 'S_M_Y_COP_01_BLACK_FULL_01' },
        { label = 'Officer (female)', voice = 'S_F_Y_COP_01_WHITE_FULL_01' },
        { label = 'Officer (female 2)', voice = 'S_F_Y_COP_01_BLACK_FULL_01' },
        { label = 'Highway patrol', voice = 'S_M_Y_HWAYCOP_01_WHITE_FULL_01' },
        { label = 'Sheriff', voice = 'S_M_Y_SHERIFF_01_WHITE_FULL_01' },
    },

    -- Each line plays a random take from the game's set, so repeats sound different.
    list = {
        { label = 'Pull over', speech = 'STOP_VEHICLE_CAR_MEGAPHONE' },
        { label = 'Pull over, final warning', speech = 'STOP_VEHICLE_CAR_WARNING_MEGAPHONE' },
        { label = 'Stop the vehicle', speech = 'STOP_VEHICLE_GENERIC_MEGAPHONE' },
        { label = 'Stop the vehicle, final warning', speech = 'STOP_VEHICLE_GENERIC_WARNING_MEGAPHONE' },
        { label = 'Stop the boat', speech = 'STOP_VEHICLE_BOAT_MEGAPHONE' },
        { label = 'Stop, police (on foot)', speech = 'STOP_ON_FOOT_MEGAPHONE' },
        { label = 'Vehicle pursuit', speech = 'CHASE_VEHICLE_MEGAPHONE' },
        { label = 'Clear the area', speech = 'CLEAR_AREA_MEGAPHONE' },
        { label = 'Clear the area, urgent', speech = 'CLEAR_AREA_PANIC_MEGAPHONE' },
        { label = 'No loitering', speech = 'NO_LOITERING_MEGAPHONE' },
    },
}

Config.Text = {
    title = 'Megaphone',
    linesTitle = 'Megaphone lines',
    voice = 'Voice: %s',
    voiceHint = 'Select to change voice',
    needMegaphone = 'Use your megaphone first',
    notAllowed = 'Only on-duty police can use megaphone lines',
    wait = 'Wait a moment before the next line',
    keybind = 'Megaphone: police lines',
}

Config.Anim = {
    dict = 'molly@megaphone',
    clip = 'megaphone_clip',
}

Config.Prop = {
    model = 'prop_megaphone_01',
    bone = 28422,
    offset = vec3(0.05, 0.054, -0.006),
    rotation = vec3(-71.885, -13.089, -16.024),
}
