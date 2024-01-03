if not ServerApi then Debug("ERROR CONFIG NOT FOUND") return end
if (not ServerApi.Data.Token or type(ServerApi.Data.Token) ~= 'string') then Debug("ERROR TOKEN NOT FOUND") return end
CreateThread(function() if (GetCurrentResourceName() ~= "Phans-Permissions") then Debug("Error Some Scripts Prosper Releases Might Not Work If This Is Renammed",true) end  end)

local UserData = {}
local Cooldowns = {}
local UserMetaTable = {}
local ServerData = {}

local function CheckGifOrPng(hash)
    if not hash then return '.png' end
    if (hash:sub(1, 1) and hash:sub(2, 2) == "_") then
        return '.gif'
    else
        return '.png'
    end
end

local Errors = {
    [429] = 'You\'ve Been Rate Limitted.',
    [403] = 'Token Inputed Is Incorrect.',
    [401] = 'Token Inputed Is Incorrect.',
    [400] = 'The Config Was Not Properly Configured Maybe Check The Server Id.',
    [501] = 'Discord Is Down.',
}

---@param type string - Message To Print
---@param Error string - Error print
function Debug(Type, Error)
    return ServerApi.Data.Debugs and Error and print("^1 Phans: ".. Type.. " (Error: ".. Error .. ")") or  print("^1 Phans: ".. Type)
end

function UserMetaTable:RequestUserData()
    ServerData = {}
    if not self.discord then
        return "User Discord Not Found"
    end
    local currentTime = GetGameTimer()
    if Cooldowns[self.source] and Cooldowns[self.source] > currentTime then
        local remainingTime = (Cooldowns[self.source] - currentTime) / 1000
        ServerApi.Data.chatMessage(self.source, '[Phans Api]', string.format("Must Wait %s Seconds Before Requesting Api Again", math.floor(remainingTime)))
        return
    end
    local errorCode, responseData = exports[GetCurrentResourceName()]:RequestApi('GET', string.format("guilds/%s/members/%s", ServerApi.Data.ServerId, self.discord), {})
    local errorCode2, responseData2 = exports[GetCurrentResourceName()]:RequestApi("GET", string.format("guilds/%s",ServerApi.Data.ServerId),{})
    if errorCode ~= 200 and errorCode ~= 204 then
        print(Errors[errorCode])
        return
    end
    ServerData[#ServerData+1] = {
        RoleCount = #json.decode(responseData2).roles or 0,
        ServerName = json.decode(responseData2).name or 'Not Found',
        ServerIcon = string.format('https://cdn.discordapp.com/icons/%s/%s%s',ServerApi.Data.ServerId,json.decode(responseData2).icon,CheckGifOrPng(json.decode(responseData2).icon)) or 'Not Found'
    }
    if responseData then
        local responseDataTable = json.decode(responseData)
        if responseDataTable and next(responseDataTable.roles) ~= 0 then
            if not responseDataTable.user.banner then
                responseDataTable.user.banner = nil
            else
                self.Banner = string.format('https://cdn.discordapp.com/banners/%s/%s%s',self.DiscordID,responseDataTable.user.banner,CheckGifOrPng(responseDataTable.user.banner))
            end
            if not responseDataTable.user.AvatarURL then
                responseDataTable.user.AvatarURL = ''
            end
            self.RoleIds = responseDataTable.roles
            self.Username = responseDataTable.user.username
            self.DiscordID = responseDataTable.user.id
            self.AvatarURL = string.format('https://cdn.discordapp.com/avatars/%s/%s%s',self.DiscordID,responseDataTable.user.avatar,CheckGifOrPng(responseDataTable.user.avatar))
            print(string.format("Found Roles List for %s (%s): %s", GetPlayerName(self.source), self.source, json.encode(self.RoleIds)))
            TriggerClientEvent('Phans:ReturnData', self.source, self, ServerApi.Data.Debugs)
        else
            print("No roles found for user", self.source)
            TriggerClientEvent('Phans:ReturnData', self.source, self, ServerApi.Data.Debugs)
        end
    else
        print("Error in API request for user", self.source)
        TriggerClientEvent('Phans:ReturnData', self.source, self, ServerApi.Data.Debugs)
    end
    Cooldowns[self.source] = currentTime + ServerApi.Data.RefreshTime
end

---@param self | Source of User
UserMetaTable.InitUserData = function(self)
    self.discord = GetPlayerIdentifierByType(source, 'discord'):gsub('discord:', '')
    self:RequestUserData()
end

---@param self | Source of User
UserMetaTable.ReturnDiscordId = function(self)
    return self.DiscordID or 0
end

---@param self | Source of User
UserMetaTable.ReturnDiscordName = function(self)
    return self.Username or 'Not Found'
end

---@param self | Source of User
---@param roleid | Role That Checks
---@param return boolean
UserMetaTable.CheckIfHasRole = function(self, roleid)
    if self.RoleIds then
        for k,v in ipairs(self.RoleIds) do
            if tonumber(v) == tonumber(roleid) then
                return true
            end
        end
    end
    return false
end

---@param hash string&Number - Data To Return
---@param return string


---@param self | Source of User
UserMetaTable.GetAvatar = function(self)
    if self.AvatarURL then return self.AvatarURL else return 'https://media3.giphy.com/media/k2Da0Uzaxo9xe/giphy.gif' end
end

---@param self | Source of User
UserMetaTable.GetRoleList = function(self)
    if self.RoleIds then return json.encode(self.RoleIds) end  return false
end

---@param self | Source of User
UserMetaTable.GetBanner = function(self)
    if self.Banner then return self.Banner else return 'https://cdn.discordapp.com/attachments/1183826678544334898/1183953955340955658/banner5m.png?ex=658a360b&is=6577c10b&hm=44277cf440d894e4172482441ca6f7218de80d396cab25d6e523032ac0ca703e&' end
end

---@param source | Source of User
local function CreateUser(source)
    local user = {
        source = source,
        discord = nil,
        RoleIds = nil,
    }
    setmetatable(user, { __index = UserMetaTable })
    return user
end

---@param Type | Message That is printed along with The Debug.
RegisterNetEvent('Phans:SendPerms', function()
    local source = source
    local user = CreateUser(source)
    UserData[source] = user
    user:InitUserData()
end)

---@param self | Source of User
RegisterCommand('refreshdapi', function(source)
    local self = UserData[source]
    if self then
        self:RequestUserData()
    end
end)

---@param player | Source of User
---@param roleid | Role That Goes for (HasRole)
---@return Table - Returns Table With Data
exports('GetPlayerData', function(player, roleid)
    local playerdata = UserData[player]
    local Data = {
        Roles = playerdata:GetRoleList(),
        DiscordID = playerdata:ReturnDiscordId(),
        DiscordName = playerdata:ReturnDiscordName(),
        Avatar = playerdata:GetAvatar(player),
        Banner = playerdata:GetBanner(player),
        Server = {
            RoleCount = ServerData.RoleCount,
            ServerName = ServerData.ServerName,
            ServerIcon = ServerData.ServerIcon,
        }
    }
    Data.HasRole = roleid and playerdata:CheckIfHasRole(roleid) or nil

    return Data
end)
