local ESX = nil
local QBCore = nil

-- Framework detection and setup
if Config.Framework == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
elseif Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Player states stored here: source -> { thc = number, drugs = { [item] = count } }
local PlayerState = {}

local function GetPlayer(source)
    local xPlayer = nil
    if Config.Framework == 'esx' then
        xPlayer = ESX.GetPlayerFromId(source)
    elseif Config.Framework == 'qb' then
        xPlayer = QBCore.Functions.GetPlayer(source)
    else
        xPlayer = source
    end
    return xPlayer
end

-- Inventory helpers per framework
local function AddItem(source, item, count)
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then xPlayer.addInventoryItem(item, count) end
    elseif Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.AddItem(item, count) end
    else
        -- standalone placeholder: log to console
        print(('[drugs] standalone add item: %s x%d for %s'):format(item, count, GetPlayerName(source)))
    end
end

local function RemoveItem(source, item, count)
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then xPlayer.removeInventoryItem(item, count) end
    elseif Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.RemoveItem(item, count) end
    else
        print(('[drugs] standalone remove item: %s x%d for %s'):format(item, count, GetPlayerName(source)))
    end
end

local function HasItem(source, item, count)
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local itemObj = xPlayer.getInventoryItem(item)
        return itemObj and itemObj.count >= (count or 1) and true or false
    elseif Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local itemObj = Player.Functions.GetItemByName(item)
        return itemObj and itemObj.amount >= (count or 1) and true or false
    else
        return true -- standalone assumes the client handles stock
    end
end

local function AddMoney(source, amount)
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then xPlayer.addMoney(amount) end
    elseif Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.AddMoney('cash', amount) end
    else
        print(('[drugs] standalone money +%d for %s'):format(amount, GetPlayerName(source)))
    end
end

local function RemoveMoney(source, amount)
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then xPlayer.removeMoney(amount) end
    elseif Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.RemoveMoney('cash', amount) end
    else
        print(('[drugs] standalone money -%d for %s'):format(amount, GetPlayerName(source)))
    end
end

-- Police / job helpers
local function CountPolice()
    local count = 0
    if Config.Framework == 'esx' then
        for _, p in ipairs(ESX.GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(p)
            if xPlayer and xPlayer.job and xPlayer.job.name == 'police' then
                count = count + 1
            end
        end
    elseif Config.Framework == 'qb' then
        for _, p in ipairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(p)
            if Player and Player.PlayerData.job and Player.PlayerData.job.name == 'police' then
                count = count + 1
            end
        end
    end
    return count
end

local function GetDrugConfigByIdentifier(item)
    for _, drug in ipairs(Config.Drugs) do
        if drug.item == item then return drug end
    end
    return nil
end

-- Register a "consumption" from the client (validate server side)
RegisterNetEvent('ender_drugs:server:useDrug', function(item)
    local source = source
    local drug = GetDrugConfigByIdentifier(item)
    if not drug then return end

    if not HasItem(source, item, 1) then
        TriggerClientEvent('ender_drugs:client:notify', source, 'You do not have any ' .. drug.label, 'error')
        return
    end

    RemoveItem(source, item, 1)

    -- Build up thc state
    PlayerState[source] = PlayerState[source] or { thc = 0 }
    local state = PlayerState[source]
    local effect = Config.Effects[drug.effect]
    if effect and effect.thc then
        state.thc = state.thc + effect.thc
    end

    -- Overdose check
    if Config.Overdose.enabled and state.thc >= Config.Overdose.threshold then
        if math.random(100) <= Config.Overdose.chance then
            TriggerClientEvent('ender_drugs:client:overdose', source, Config.Overdose.damage)
            state.thc = 0
            TriggerClientEvent('ender_drugs:client:notify', source, 'You overdosed!', 'error')
            return
        end
    end

    TriggerClientEvent('ender_drugs:client:applyEffect', source, drug.effect, drug.effectTime)
    TriggerClientEvent('ender_drugs:client:notify', source, 'You used ' .. drug.label, 'success')
end)

-- Harvest a raw drug from a crop zone
RegisterNetEvent('ender_drugs:server:harvest', function(zoneId)
    local source = source
    local zone = Config.CropZones[zoneId]
    if not zone then return end

    AddItem(source, zone.drug, zone.amount)
    TriggerClientEvent('ender_drugs:client:notify', source, 'You harvested ' .. zone.drug, 'success')
end)

-- Process a raw drug into a sellable drug
RegisterNetEvent('ender_drugs:server:process', function(zoneId)
    local source = source
    local zone = Config.ProcessingZones[zoneId]
    if not zone then return end

    if zone.policeThreshold and zone.policeThreshold > 0 then
        if CountPolice() >= zone.policeThreshold then
            TriggerClientEvent('ender_drugs:client:notify', source, 'Too much police activity around.', 'error')
            return
        end
    end

    if not HasItem(source, zone.input, 1) then
        TriggerClientEvent('ender_drugs:client:notify', source, 'You need a ' .. zone.input .. ' to process.', 'error')
        return
    end

    RemoveItem(source, zone.input, 1)
    AddItem(source, zone.output, 1)
    TriggerClientEvent('ender_drugs:client:notify', source, 'Processing complete. You received a ' .. zone.output .. '.', 'success')
end)

-- Sell drugs at a dealer with sell value from config
RegisterNetEvent('ender_drugs:server:sell', function(zoneId, item)
    local source = source
    local zone = Config.SellZones[zoneId]
    if not zone then return end

    if zone.policeThreshold and zone.policeThreshold > 0 then
        if CountPolice() >= zone.policeThreshold then
            TriggerClientEvent('ender_drugs:client:notify', source, 'The dealer is too nervous with police around.', 'error')
            return
        end
    end

    local drug = GetDrugConfigByIdentifier(item)
    if not drug then return end

    if not HasItem(source, item, 1) then
        TriggerClientEvent('ender_drugs:client:notify', source, 'You have no ' .. drug.label .. ' to sell.', 'error')
        return
    end

    RemoveItem(source, item, 1)
    AddMoney(source, drug.sellValue)
    TriggerClientEvent('ender_drugs:client:notify', source, ('Sold %s for $%d.'):format(drug.label, drug.sellValue), 'success')
end)

-- Cleanup on disconnect
AddEventHandler('playerDropped', function(reason)
    PlayerState[source] = nil
end)

-- Logging helper
AddEventHandler('onResourceStart', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    print('[ender_drugs] Resource started with framework: ' .. Config.Framework)
end)
