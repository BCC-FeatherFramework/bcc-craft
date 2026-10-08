-- bcc-craft's boundary to the Feather Framework (server side).
--
-- Keeps the call shapes the crafting code was written against (devPrint,
-- NotifyClient, an RPC object, Discord:sendMessage, character objects with
-- charIdentifier/firstname/lastname) while every value now comes from the
-- feather-core session and the Character provider. Character IDs are UUIDs.

Craft = Craft or {}

function Craft.Ok(value) return { ok = true, value = value } end
function Craft.Err(code, message, details)
    return { ok = false, code = code, message = message, details = details }
end

if Config.devMode then
    function devPrint(...)
        local args = { ... }
        for i = 1, select('#', ...) do args[i] = tostring(args[i]) end
        -- One print per line, each ending with ^0 so the color never carries over.
        for line in (table.concat(args, " ") .. "\n"):gmatch("(.-)\n") do
            print("^1[DEV MODE] ^4" .. line .. "^0")
        end
    end
else
    function devPrint(...) end
end

-- RPC ------------------------------------------------------------------------
-- Same handler shape as bcc-utils: function(params, cb, source).

FeatherRPC = {}

function FeatherRPC:Register(name, handler, options)
    local registered = exports['feather-core']:RegisterRPC(name, function(params, respond, src)
        local answered = false
        local function reply(...)
            if answered then return end -- one reply per call
            answered = true
            respond(...)
        end
        local called, problem = xpcall(handler, debug.traceback, params or {}, reply, src)
        if not called then
            print(('[bcc-craft] rpc %s failed: %s'):format(name, tostring(problem)))
            reply(false)
        end
    end, options or { windowMs = 1000, maxCalls = 10, maxPayloadBytes = 16384, requireCharacter = true })
    if registered ~= true then
        print(('[bcc-craft] rpc registration failed: %s'):format(name))
    end
end

-- Server-to-client call (replaces BccUtils.RPC:Call(name, params, nil, source)).
function FeatherRPC:Notify(name, params, target)
    return exports['feather-core']:NotifyRPC(name, params or {}, target)
end

-- Notifications ----------------------------------------------------------------

function NotifyClient(src, message, duration, notifyType)
    if not src or tonumber(src) == 0 then return end
    duration = duration or ((Config.NotifyOptions and Config.NotifyOptions.autoClose) or 4000)
    local result = exports['feather-core']:SendNotification({
        source = tonumber(src),
        style = 'right',
        message = tostring(message),
        duration = tonumber(duration) or 4000
    })
    if type(result) ~= 'table' or result.ok ~= true then
        devPrint('[NotifyClient] failed', type(result) == 'table' and result.code or 'invalid_result')
    end
end

-- Characters -----------------------------------------------------------------

CraftCharacters = {}
local names = {} -- characterId -> { firstname, lastname }

local function IsCallable(value)
    return type(value) == 'function' or (type(value) == 'table'
        and type(rawget(value, '__cfx_functionReference')) == 'string')
end

local function ProfileProvider()
    local provider = exports['feather-core']:GetProvider('character-profile', nil, 1)
    local implementation = type(provider) == 'table' and provider.ok and provider.value.implementation or nil
    if type(implementation) ~= 'table' then return nil end
    return implementation
end

local function GetName(characterId)
    local cached = names[characterId]
    if cached then return cached.firstname, cached.lastname end
    local provider = ProfileProvider()
    if provider and IsCallable(provider.GetProfile) then
        local profile = provider.GetProfile(characterId)
        if type(profile) == 'table' and profile.ok and type(profile.value) == 'table' then
            names[characterId] = {
                firstname = profile.value.firstName or 'Unknown',
                lastname = profile.value.lastName or 'Unknown'
            }
            return names[characterId].firstname, names[characterId].lastname
        end
    end
    return 'Unknown', 'Unknown'
end

-- The active character of a connected player, or nil. The identity comes from
-- the Core session; nothing the client sends is trusted.
function CraftCharacters.Get(src)
    src = tonumber(src)
    if not src or src <= 0 then return nil end
    local session = exports['feather-core']:GetSessionContext(src)
    if type(session) ~= 'table' or not session.ok or type(session.value) ~= 'table'
        or type(session.value.characterId) ~= 'string' then
        return nil
    end
    local characterId = session.value.characterId:lower()
    local firstname, lastname = GetName(characterId)
    return {
        source = src,
        charIdentifier = characterId,
        accountId = session.value.accountId,
        firstname = firstname,
        lastname = lastname
    }
end

AddEventHandler('onResourceStart', function(resource)
    if resource == 'feather-character' then names = {} end
end)

-- Domain calls ---------------------------------------------------------------
-- Calls a Feather domain export so the invoking resource is bcc-craft, and
-- turns exceptions or malformed replies into error envelopes.

function Craft.Call(resource, operation, request, context)
    if GetResourceState(resource) ~= 'started' then
        return Craft.Err('dependency_unavailable', resource .. ' is not started.')
    end
    local called, result = pcall(function()
        local provider = exports[resource]
        return provider[operation](provider, request, context)
    end)
    if not called or type(result) ~= 'table' or type(result.ok) ~= 'boolean' then
        return Craft.Err('dependency_unavailable', ('%s %s failed.'):format(resource, operation))
    end
    return result
end

-- Discord webhook (replaces BccUtils.Discord). Sends nothing when no link is set.
Discord = {}

function Discord:sendMessage(message)
    local link = Config.WebhookLink
    if type(link) ~= 'string' or not link:match('^https://discord%.com/api/webhooks/') then return end
    PerformHttpRequest(link, function() end, 'POST', json.encode({
        username = Config.WebhookTitle or 'BCC-Crafting',
        avatar_url = (Config.WebhookAvatar ~= '' and Config.WebhookAvatar) or nil,
        content = tostring(message):sub(1, 2000)
    }), { ['Content-Type'] = 'application/json' })
end

-- Optional playtime requirement through bcc-userlog (keyed by Steam identifier).
if Config.useBccUserlog and GetResourceState('bcc-userlog') ~= 'missing' then
    CreateThread(function()
        local ok, api = pcall(function() return exports['bcc-userlog']:getUserLogAPI() end)
        UserLogAPI = ok and api or nil
    end)
end
