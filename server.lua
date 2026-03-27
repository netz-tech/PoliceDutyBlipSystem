local json = require("json")
local onDuty = {}
local onDutyStart = {}

-- Full RoleList including Police, Government, and Corporate roles. This is used for permission checks and determining which departments a player can select from.
RoleList = {
    -- Police / Government Departments
    ['ExactRoleName'] = RoleID, -- Exact Discord Role Name / Discord ID

    -- Corporate Roles
    ['ExactRoleName'] = RoleID, -- Exact Discord Role Name / Discord ID

}

local function hydrateRoleListFromConfig()
    if type(Config) ~= 'table' or type(Config.RoleList) ~= 'table' then
        return
    end

    for dept, info in pairs(Config.RoleList) do
        if type(info) == 'table' then
            local roleId = info.role or info.id  -- THIS IS FOR IF YOU HAVE AN "ALL DEPARTMENTS" ROLE SETUP IN YOUR CONFIG.
            if roleId then
                RoleList[dept] = roleId
                if dept == 'ALL' then
                    RoleList['All'] = roleId
                    RoleList['ALL'] = roleId
                end
            end
        end
    end
end

hydrateRoleListFromConfig()

local function isSelectableDepartment(dept)
    if type(dept) ~= 'string' then return false end
    if dept == 'All' or dept == 'ALL' then return false end
    return not string.find(dept, '|', 1, true)
end

local wildcardRoleIds = {}

local function registerWildcardRole(roleId)
    if roleId then
        wildcardRoleIds[#wildcardRoleIds + 1] = tostring(roleId)
    end
end

registerWildcardRole(RoleList['All'])
registerWildcardRole(RoleList['ALL'])
if Config.RoleList and Config.RoleList['ALL'] and Config.RoleList['ALL'].role then
    registerWildcardRole(Config.RoleList['ALL'].role)
end

local function formatDuration(seconds)
    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then
        return nil
    end

    seconds = math.floor(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    local parts = {}

    if hours > 0 then
        parts[#parts + 1] = string.format("%d hr%s", hours, hours ~= 1 and "s" or "")
    end
    if minutes > 0 then
        parts[#parts + 1] = string.format("%d min%s", minutes, minutes ~= 1 and "s" or "")
    end
    if hours == 0 and minutes == 0 then
        parts[#parts + 1] = string.format("%d sec%s", secs, secs ~= 1 and "s" or "")
    end

    return table.concat(parts, ' ')
end

local function getPlayerNameSafe(src)
    local ok, name = pcall(GetPlayerName, src)
    if ok and type(name) == 'string' and name ~= '' then
        return name
    end
    return string.format("ID %s", tostring(src))
end

local function getRoleLookup(src)
    local roles = exports.Badger_Discord_API:GetDiscordRoles(src) or {}
    local lookup = {}
    for _, roleId in ipairs(roles) do
        lookup[tostring(roleId)] = true
    end
    return lookup
end

local function hasWildcardAccess(roleLookup)
    for _, roleId in ipairs(wildcardRoleIds) do
        if roleLookup[roleId] then
            return true
        end
    end
    return false
end

local function canUseDepartment(roleLookup, dept)
    local roleId = RoleList[dept]
    if not roleId then
        return false
    end

    if roleLookup[tostring(roleId)] then
        return true
    end

    return hasWildcardAccess(roleLookup)
end

local function getAllowedDepartments(roleLookup)
    local allowed = {}
    local allowAll = hasWildcardAccess(roleLookup)
    for dept, roleId in pairs(RoleList) do
        if isSelectableDepartment(dept) then
            if allowAll or roleLookup[tostring(roleId)] then
                allowed[#allowed + 1] = dept
            end
        end
    end
    table.sort(allowed)
    return allowed
end

local function setPlayerOffDuty(src, opts)
    opts = opts or {}
    local dept = onDuty[src]
    if not dept then
        if not opts.silent then
            TriggerClientEvent('chat:addMessage', src, {args={'Duty','You are not currently on duty.'}})
        end
        return false
    end

    local startedAt = onDutyStart[src]
    local patrolSeconds = nil
    if startedAt then
        patrolSeconds = os.time() - startedAt
        if patrolSeconds < 0 then
            patrolSeconds = nil
        end
    end

    onDuty[src] = nil
    onDutyStart[src] = nil
    if not opts.silent then
        TriggerClientEvent('policeDuty:setDuty', src, false)
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Duty Status",
            description = "You are now OFF duty ("..dept..")",
            type = "error",
            duration = 5000
        })
    end

    local formatted = formatDuration(patrolSeconds)
    local actionText = "OFF DUTY"
    if formatted then
        actionText = actionText .. " | Patrol Time: " .. formatted
    end
    if type(opts.reason) == 'string' and opts.reason ~= '' then
        actionText = actionText .. " | Reason: " .. opts.reason
    end

    sendWebhook(dept, getPlayerNameSafe(src), actionText, 16711680)
    SaveDutyData()
    return true
end

local function setPlayerOnDuty(src, dept, roleLookup)
    if onDuty[src] then
        TriggerClientEvent('chat:addMessage', src, {args={'Duty','You are already on duty as '..onDuty[src]}})
        return false
    end

    if not RoleList[dept] then
        TriggerClientEvent('chat:addMessage', src, {args={'Duty','That department does not exist.'}})
        return false
    end

    roleLookup = roleLookup or getRoleLookup(src)
    if not canUseDepartment(roleLookup, dept) then
        TriggerClientEvent('chat:addMessage', src, {args={'Duty','You do not have permission for this department.'}})
        return false
    end

    onDuty[src] = dept
    onDutyStart[src] = os.time()
    TriggerClientEvent('policeDuty:setDuty', src, true, dept)
    TriggerClientEvent('ox_lib:notify', src, {
        title = "Duty Status",
        description = "You are now ON duty ("..dept..")",
        type = "success",
        duration = 5000
    })
    sendWebhook(dept, getPlayerNameSafe(src), "ON DUTY", 65280)
    SaveDutyData()
    return true
end

-- Load duty data on server start
if not LoadResourceFile(GetCurrentResourceName(), Config.DataFile) then
    SaveResourceFile(GetCurrentResourceName(), Config.DataFile, "{}", -1)
end

AddEventHandler('playerDropped', function(reason)
    local src = source
    local dropReason = nil
    if type(reason) == 'string' and reason ~= '' then
        dropReason = reason
    end
    local handled = setPlayerOffDuty(src, { silent = true, reason = dropReason or "Disconnected" })
    if not handled then
        onDuty[src] = nil
        onDutyStart[src] = nil
        SaveDutyData()
    end
end)

function SaveDutyData()
    local payload = {
        duty = onDuty,
        start = onDutyStart
    }
    local encoded = json.encode(payload)
    SaveResourceFile(GetCurrentResourceName(), Config.DataFile, encoded, -1)
end

function LoadDutyData()
    local content = LoadResourceFile(GetCurrentResourceName(), Config.DataFile)
    if content and content ~= "" then
        local decoded = json.decode(content)
        if type(decoded) == 'table' and (decoded.duty or decoded.start) then
            if type(decoded.duty) == 'table' then
                onDuty = decoded.duty
            else
                onDuty = {}
            end
            if type(decoded.start) == 'table' then
                onDutyStart = decoded.start
            else
                onDutyStart = {}
            end
        elseif type(decoded) == 'table' then
            -- Legacy format where file stored only onDuty table.
            onDuty = decoded
            onDutyStart = {}
        else
            onDuty = {}
            onDutyStart = {}
        end
    else
        onDuty = {}
        onDutyStart = {}
    end
end

LoadDutyData()

-- /duty command
RegisterCommand('duty', function(src, args)
    local deptArg = args[1]

    if type(deptArg) == 'string' then
        if deptArg:lower() == 'off' then
            setPlayerOffDuty(src)
            return
        end

        setPlayerOnDuty(src, deptArg)
        return
    end

    local roleLookup = getRoleLookup(src)
    local allowedDepartments = getAllowedDepartments(roleLookup)

    if not onDuty[src] and #allowedDepartments == 0 then
        TriggerClientEvent('chat:addMessage', src, {args={'Duty','You do not have permission for any department.'}})
        return
    end

    TriggerClientEvent('policeDuty:openDutyMenu', src, allowedDepartments, onDuty[src])
end, false)

RegisterNetEvent('policeDuty:requestDutyChange')
AddEventHandler('policeDuty:requestDutyChange', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end

    if payload.action == 'off' then
        setPlayerOffDuty(src)
        return
    end

    if payload.action == 'on' and type(payload.department) == 'string' then
        setPlayerOnDuty(src, payload.department)
    end
end)

-- Command description
Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/duty', 'Open the duty selection menu or provide a department to go on duty directly.', {
        { name="department", help="Optional department short code (FHP, USMS, etc.). Use Off to leave duty instantly." }
    })
end)

function sendWebhook(dept, name, action, color)
    dept = type(dept) == 'string' and dept ~= '' and dept or "UNKNOWN"
    name = type(name) == 'string' and name ~= '' and name or "Unknown"
    action = type(action) == 'string' and action ~= '' and action or "UPDATED DUTY"
    color = tonumber(color) or 16777215

    local embed = {{
        ["title"] = "Duty Log",
        ["description"] = string.format("**%s (%s)** %s.", name, dept, action),
        ["color"] = color,
        ["footer"] = { ["text"] = os.date("%Y-%m-%d %I:%M:%S %p EST") }
    }}
    local dataWebhook = nil
    if dept:match("") then -- Can be whatever the corporate roles are, if you choose to use them.
        dataWebhook = nil
    else
        if Config.RoleList and Config.RoleList[dept] and Config.RoleList[dept].webhook then
            dataWebhook = Config.RoleList[dept].webhook
        end
    end
    if dataWebhook then
        PerformHttpRequest(dataWebhook, function() end, 'POST', json.encode({embeds = embed}), {['Content-Type']='application/json'})
    end
end


