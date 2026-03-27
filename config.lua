Config = {}

Config.RoleList = {
    [''] = { -- What you want the "tag" to be when going on duty /example "tag" 
        role = DiscordRoleID, -- Role ID
        color = 3, -- Blip color (https://docs.fivem.net/docs/game-references/blips/#blip-colors)
        webhook = '' -- Webhook URL for duty logs, set to nil or empty string to disable logging for this department
    },
}

Config.DataFile = 'data/duty.json'