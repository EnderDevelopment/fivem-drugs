Config = {}

-- General settings
Config.Framework = 'esx' -- 'esx', 'qb' or 'standalone'
Config.Command = 'drug'
Config.ProgressBar = true -- Use progress bars (requires progressbar resource or qb progress)

-- Item database
-- Each drug has: item (inventory item), effect time, sell value
Config.Drugs = {
    { item = 'weed',          label = 'Weed',          effectTime = 60,  sellValue = 120,  effect = 'high'   },
    { item = 'cocaine',       label = 'Cocaine',       effectTime = 90,  sellValue = 250,  effect = 'hyper'  },
    { item = 'meth',          label = 'Meth',          effectTime = 120, sellValue = 320,  effect = 'hyper'  },
    { item = 'lsd',           label = 'LSD',           effectTime = 150, sellValue = 400,  effect = 'trippy' },
    { item = 'heroin',        label = 'Heroin',        effectTime = 45,  sellValue = 380,  effect = 'nod'    },
    { item = 'mushrooms',     label = 'Mushrooms',     effectTime = 100, sellValue = 180,  effect = 'trippy' },
    { item = 'ecstasy',       label = 'Ecstasy',       effectTime = 80,  sellValue = 200,  effect = 'energy' },
    { item = 'oxycodone',     label = 'Oxycodone',     effectTime = 55,  sellValue = 300,  effect = 'painkiller' },
    { item = 'adderall',      label = 'Adderall',      effectTime = 110, sellValue = 150,  effect = 'focus'  },
    { item = 'ketamine',      label = 'Ketamine',      effectTime = 40,  sellValue = 350,  effect = 'nod'    },
}

-- Crops / harvesting locations
-- Each zone lets the player harvest a raw material drug
Config.CropZones = {
    {
        coords = vector3(2219.76, 5577.26, 54.14),
        radius = 5.0,
        drug = 'weed',          -- which item gets harvested
        amount = 1,             -- how many items per harvest
        time = 5000,            -- ms to harvest
    },
    {
        coords = vector3(-1124.43, 4925.77, 220.00),
        radius = 5.0,
        drug = 'cocaine',
        amount = 1,
        time = 5000,
    },
    {
        coords = vector3(1392.58, 3606.61, 35.03),
        radius = 5.0,
        drug = 'meth',
        amount = 1,
        time = 5000,
    },
}

-- Processing stations
-- Raw items get turned into sellable drugs at these locations
Config.ProcessingZones = {
    {
        coords = vector3(1393.70, 3608.01, 35.03),
        radius = 2.0,
        input = 'meth',       -- raw item required
        output = 'meth',      -- item produced
        time = 8000,
        policeThreshold = 0,  -- minimum police online OR 0 to ignore
    },
    {
        coords = vector3(-1127.09, 4929.54, 220.00),
        radius = 2.0,
        input = 'cocaine',
        output = 'cocaine',
        time = 8000,
        policeThreshold = 0,
    },
}

-- Selling locations (NPC dealers)
Config.SellZones = {
    {
        coords = vector3(24.62, -1396.32, 29.36),
        radius = 3.0,
        npcModel = 'a_m_m_hillbilly_01',
        npcHeading = 200.0,
        policeThreshold = 2,   -- needs >= this many police to block, 0 = never blocked
        maxItems = 5,          -- max items sold per interaction
    },
    {
        coords = vector3(-1339.80, -1278.65, 4.87),
        radius = 3.0,
        npcModel = 'a_m_m_salton_01',
        npcHeading = 40.0,
        policeThreshold = 2,
        maxItems = 5,
    },
}

-- Visual / game effects per drug type
Config.Effects = {
    high = {
        arm = 'HIGH',          -- walk style for arms
        move = 'move_m@drunk@verydrunk', -- overrides walk style
        speed = 0.9,
        thc = 100,             -- gets you high
    },
    hyper = {
        arm = 'HURT',
        move = 'move_m@quick',
        speed = 1.2,
        thc = 100,
    },
    trippy = {
        arm = 'DEATH',
        move = 'move_m@drunk@verydrunk',
        speed = 0.85,
        thc = 100,
    },
    nod = {
        arm = 'LEDGE',
        move = 'move_m@drunk@verydrunk',
        speed = 0.5,
        thc = 100,
    },
    energy = {
        arm = 'HURT',
        move = 'move_m@fast',
        speed = 1.3,
        thc = 100,
    },
    painkiller = {
        arm = 'LEDGE',
        move = 'move_m@drunk@slightlydrunk',
        speed = 0.9,
        thc = 60,
    },
    focus = {
        arm = 'HURT',
        move = 'move_m@fast',
        speed = 1.1,
        thc = 40,
    },
}

-- How much "thc" to add per effect tick; used to scale overdose chance
Config.Overdose = {
    enabled = true,
    threshold = 1200,   -- cumulative thc before overdose risk
    damage = 5,         -- damage per tick while overdosing
    chance = 60,        -- % chance to overdose when above threshold
}
