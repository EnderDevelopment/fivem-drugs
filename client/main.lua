local PlayerData = {}
local PlayerJob = {}
local inUse = false
local usingEffect = {}
local currentCoords = nil

-- Framework bootstrap for client
if Config.Framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        PlayerData = xPlayer
        PlayerJob = xPlayer.job
    end)
    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(job)
        PlayerJob = job
    end)
    TriggerEvent('esx:getSharedObject', function(obj)
        ESX = obj
    end)
elseif Config.Framework == 'qb' then
    -- qb uses exports, handled via callbacks
end

-- Notify helper (adapt to your notify system)
RegisterNetEvent('ender_drugs:client:notify')
AddEventHandler('ender_drugs:client:notify', function(message, type)
    type = type or 'info'
    if type == 'error' then
        print('[ender_drugs] ERROR: ' .. message)
    elseif type == 'success' then
        print('[ender_drugs] SUCCESS: ' .. message)
    else
        print('[ender_drugs] INFO: ' .. message)
    end
    -- If you use ox_lib or qb notify, uncomment:
    -- exports['ox_lib']:notify({ description = message, type = type })
    -- TriggerEvent('QBCore:Notify', message, type)
end)

-- Draw a marker for a zone
local function DrawMarker(zone)
    local coords = zone.coords
    if zone.radius then
        DrawMarker(27, coords.x, coords.y, coords.z - 0.9, 0, 0, 0, 0, 0, 0, zone.radius * 2, zone.radius * 2, 0.5, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
    end
end

-- Check if player is in a zone
local function IsInZone(zone, playerCoords)
    local coords = zone.coords
    local distance = #(playerCoords - coords)
    return distance <= (zone.radius or 0)
end

-- Main thread: draw markers and detect zones
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        currentCoords = GetEntityCoords(playerPed)

        -- Draw markers for all zone types
        for _, zone in ipairs(Config.CropZones) do
            DrawMarker(zone)
            if IsInZone(zone, currentCoords) then
                sleep = 0
                DrawText3D(zone.coords, 'Press [E] to harvest ' .. zone.drug, 255, 255, 255)
                if IsControlJustReleased(0, 38) then -- E key
                    HarvestZone(zone)
                end
            end
        end

        for _, zone in ipairs(Config.ProcessingZones) do
            DrawMarker(zone)
            if IsInZone(zone, currentCoords) then
                sleep = 0
                DrawText3D(zone.coords, 'Press [E] to process ' .. zone.input, 255, 255, 255)
                if IsControlJustReleased(0, 38) then
                    ProcessZone(zone)
                end
            end
        end

        for _, zone in ipairs(Config.SellZones) do
            if zone.npcModel then
                -- Spawn NPC dealer
                SpawnNpc(zone)
            end
            DrawMarker(zone)
            if IsInZone(zone, currentCoords) then
                sleep = 0
                DrawText3D(zone.coords, 'Press [E] to sell drugs', 255, 255, 255)
                if IsControlJustReleased(0, 38) and not inUse then
                    SellZone(zone)
                end
            elseif CurrentSellZone == zone then
                CurrentSellZone = nil
            end
        end

        Wait(sleep)
    end
end)

function DrawText3D(coords, text, r, g, b)
    local x, y, z = coords.x, coords.y, coords.z
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(r, g, b, 255)
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Draw NPC for sell zones
local spawnedNpcs = {}
local function SpawnNpc(zone)
    local key = ('%s_%s_%s'):format(zone.coords.x, zone.coords.y, zone.coords.z)
    if spawnedNpcs[key] then
        -- Check if NPC still exists
        if DoesEntityExist(spawnedNpcs[key]) then
            return
        end
    end
    local hash = GetHashKey(zone.npcModel)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    local npc = CreatePed(4, hash, zone.coords.x, zone.coords.y, zone.coords.z - 0.97, zone.npcHeading, false, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetPedCanRagdoll(npc, false)
    spawnedNpcs[key] = npc
end

-- Harvest zone logic
local function HarvestZone(zone)
    if inUse then return end
    inUse = true
    ProgressBar('Harvesting...', zone.time)
    TriggerServerEvent('ender_drugs:server:harvest', GetZoneIndex(Config.CropZones, zone))
    inUse = false
end

-- Process zone logic
local function ProcessZone(zone)
    if inUse then return end
    inUse = true
    ProgressBar('Processing...', zone.time)
    TriggerServerEvent('ender_drugs:server:process', GetZoneIndex(Config.ProcessingZones, zone))
    inUse = false
end

-- Sell zone logic - tracks proximity so the player can use /sell
local function SellZone(zone)
    CurrentSellZone = zone
    TriggerEvent('chat:addMessage', {
        args = { 'Drug Dealer', 'Type /sell <id> to sell. Available:' }
    })
    for i, drug in ipairs(Config.Drugs) do
        TriggerEvent('chat:addMessage', {
            args = { 'Drug Dealer', ('[%d] %s ($%d)'):format(i, drug.label, drug.sellValue) }
        })
    end
end

-- Helper to get index of a zone in a list
local function GetZoneIndex(list, zone)
    for i, z in ipairs(list) do
        if z == zone then return i end
    end
    return nil
end

-- Sell a specific drug via command
CurrentSellZone = nil
RegisterCommand('sell', function(source, args, raw)
    if not CurrentSellZone then
        TriggerEvent('chat:addMessage', { args = { 'Drug Dealer', 'You are not near a dealer.' } })
        return
    end
    local idx = tonumber(args[1])
    local drug = Config.Drugs[idx]
    if not drug then
        TriggerEvent('chat:addMessage', { args = { 'Drug Dealer', 'Invalid selection.' } })
        return
    end
    TriggerServerEvent('ender_drugs:server:sell', GetZoneIndex(Config.SellZones, CurrentSellZone), drug.item)
    TriggerEvent('chat:addMessage', { args = { 'Drug Dealer', ('You sold a %s.'):format(drug.label) } })
end, false)

-- Progress bar helper (replace with your progressbar resource)
local function ProgressBar(text, duration)
    -- ox_lib progress
    -- if exports['ox_lib'] then
    --     exports['ox_lib']:progressBar({ duration = duration, label = text, useWhileDead = false, canCancel = true })
    -- end
    -- Fallback: simple wait
    Wait(duration)
end

-- Apply drug effect
RegisterNetEvent('ender_drugs:client:applyEffect')
AddEventHandler('ender_drugs:client:applyEffect', function(effectType, duration)
    local effect = Config.Effects[effectType]
    if not effect then return end

    local playerPed = PlayerPedId()
    -- Set walking style / movement
    if effect.move then
        RequestAnimSet(effect.move)
        while not HasAnimSetLoaded(effect.move) do
            Wait(10)
        end
        SetPedMovementClipset(playerPed, effect.move, 1.0)
    end
    if effect.arm then
        local armHash = GetHashKey(effect.arm)
        SetPedConfigFlag(playerPed, 23, true) -- disable idle camera
        -- Simple effect application
    end
    if effect.speed then
        SetRunSprintMultiplierForPlayer(PlayerId(), effect.speed)
    end

    -- Clear the effect after the duration has passed
    CreateThread(function()
        Wait(duration * 1000)
        local playerPed = PlayerPedId()
        ResetPedMovementClipset(playerPed, 1.0)
        ResetRunSprintMultiplierForPlayer(PlayerId())
    end)
end)

-- Overdose event
RegisterNetEvent('ender_drugs:client:overdose')
AddEventHandler('ender_drugs:client:overdose', function(damage)
    local playerPed = PlayerPedId()
    local i = 0
    while i < 3 do
        SetEntityHealth(playerPed, GetEntityHealth(playerPed) - damage)
        Wait(1000)
        i = i + 1
    end
    TriggerEvent('chat:addMessage', { args = { 'System', 'You overdosed and took damage!' } })
end)

-- Use drug command
RegisterCommand(Config.Command, function()
    if inUse then return end
    -- Show available drugs
    TriggerEvent('chat:addMessage', { args = { 'System', 'Drugs available:' } })
    for i, drug in ipairs(Config.Drugs) do
        TriggerEvent('chat:addMessage', { args = { 'System', ('[%d] %s'):format(i, drug.label) } })
    end
    -- Let user choose from chat
    TriggerEvent('chat:addMessage', { args = { 'System', 'Type /usedrug <id> to use.' } })
end, false)

RegisterCommand('usedrug', function(source, args, raw)
    local idx = tonumber(args[1])
    local drug = Config.Drugs[idx]
    if not drug then
        TriggerEvent('chat:addMessage', { args = { 'System', 'Invalid drug id.' } })
        return
    end
    TriggerServerEvent('ender_drugs:server:useDrug', drug.item)
end, false)
