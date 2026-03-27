local onDuty = false
local myBlip = nil
local department = nil
local dutyMenuOpen = false

local function closeDutyMenu(sendHideMessage)
    if not dutyMenuOpen then return end
    dutyMenuOpen = false
    SetNuiFocus(false, false)
    if sendHideMessage then
        SendNUIMessage({ action = 'closeDutyMenu' })
    end
end

local function buildMenuOptions(allowedDepartments, currentDept)
    local options = {}

    if currentDept then
        options[#options + 1] = {
            label = 'Go Off Duty',
            description = ('Currently on duty as %s'):format(currentDept),
            action = 'off'
        }
    end

    if allowedDepartments then
        for _, dept in ipairs(allowedDepartments) do
            options[#options + 1] = {
                label = dept,
                description = ('Go on duty as '..dept),
                action = 'on',
                department = dept
            }
        end
    end

    return options
end

RegisterNetEvent('policeDuty:openDutyMenu')
AddEventHandler('policeDuty:openDutyMenu', function(allowedDepartments, currentDept)
    local options = buildMenuOptions(allowedDepartments, currentDept)

    if #options == 0 then
        TriggerEvent('chat:addMessage', { args = {'Duty','No departments available for you.'} })
        return
    end

    dutyMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openDutyMenu',
        payload = { options = options }
    })
end)

RegisterNUICallback('dutyMenuSelect', function(data, cb)
    cb({})
    if type(data) ~= 'table' then return end
    TriggerServerEvent('policeDuty:requestDutyChange', {
        action = data.action,
        department = data.department
    })
end)

RegisterNUICallback('dutyMenuClose', function(_, cb)
    cb({})
    closeDutyMenu(false)
end)

-- Set duty state from server
RegisterNetEvent('policeDuty:setDuty')
AddEventHandler('policeDuty:setDuty', function(state, dept)
    closeDutyMenu(true)
    onDuty = state
    department = dept

    if state then
        -- Give loadout
        GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_STUNGUN"), 1000, false, true)
        GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_NIGHTSTICK"), 1, false, true)
        GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_COMBATPISTOL"), 250, false, true)
        GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_CARBINERIFLE"), 500, false, true)
        GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_FLASHLIGHT"), 1, false, true)
        GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PUMPSHOTGUN"), 70, false, true)

        -- Add attachments
        GiveWeaponComponentToPed(PlayerPedId(), GetHashKey("WEAPON_COMBATPISTOL"), GetHashKey("COMPONENT_AT_PI_FLSH"))
        GiveWeaponComponentToPed(PlayerPedId(), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_AT_AR_FLSH"))
        GiveWeaponComponentToPed(PlayerPedId(), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_AT_SCOPE_MEDIUM")) -- red dot sight

        -- Create blip
        if myBlip then RemoveBlip(myBlip) end
        myBlip = AddBlipForEntity(PlayerPedId())
        SetBlipSprite(myBlip, 60)
        if Config.RoleList[dept] and Config.RoleList[dept].color then
            SetBlipColour(myBlip, Config.RoleList[dept].color)
        else
            SetBlipColour(myBlip, 2)
        end
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(department)
        EndTextCommandSetBlipName(myBlip)
    else
        if myBlip then RemoveBlip(myBlip) end
        myBlip = nil
        RemoveAllPedWeapons(PlayerPedId(), true)
    end
end)
