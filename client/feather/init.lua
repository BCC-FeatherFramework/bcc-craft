-- bcc-craft's boundary to the Feather Framework (client side).
-- Keeps the call shapes the crafting menus use (FeatherRPC:Call/CallAsync/Register,
-- Notify(message, type, duration), progressbar.start/onCancel, devPrint) on top of
-- feather-core, feather-notify, feather-toolkit and feather-menu-v2.

if Config.devMode then
    function devPrint(...)
        local args = { ... }
        for i = 1, select('#', ...) do args[i] = tostring(args[i]) end
        print("^1[DEV MODE]^3 " .. table.concat(args, " ") .. "^0")
    end
else
    function devPrint(...) end
end

Toolkit = exports['feather-toolkit']
FeatherMenu = FeatherMenuV2Compat

-- RPC ------------------------------------------------------------------------

FeatherRPC = {}

-- Returns the server handler's reply, or nil on transport failure.
function FeatherRPC:CallAsync(name, params)
    local result, transportError = exports['feather-core']:CallRPCAsync(name, params or {})
    if result == nil and type(transportError) == 'table' then
        devPrint(('rpc %s failed: %s'):format(name, tostring(transportError.code or transportError.message)))
    end
    return result, transportError
end

function FeatherRPC:Call(name, params, callback)
    CreateThread(function()
        local result, extra = self:CallAsync(name, params)
        if callback then callback(result, extra) end
    end)
end

-- Server-to-client procedures (craft book use, crafting started).
function FeatherRPC:Register(name, handler)
    exports['feather-core']:RegisterRPC(name, function(params, respond)
        handler(params or {}, function() end)
        if respond then respond(true) end
    end)
end

-- Notifications ----------------------------------------------------------------

function Notify(message, typeOrDuration, maybeDuration)
    local duration = tonumber(maybeDuration) or (type(typeOrDuration) == 'number' and typeOrDuration)
        or (Config.NotifyOptions and Config.NotifyOptions.autoClose) or 4000
    local result = exports['feather-notify']:ShowNotification({
        style = 'right',
        message = tostring(message),
        duration = duration
    })
    if type(result) ~= 'table' or result.ok ~= true then
        devPrint('notification failed: ' .. (type(result) == 'table' and tostring(result.code) or 'invalid_result'))
    end
end

-- Progress bar (replaces feather-progressbar) ------------------------------------
-- progressbar.start(text, durationMs, onComplete, theme, color, width, cancelable)
-- runs on feather-toolkit; ESC (or backspace) cancels a cancelable bar and calls the
-- handler set with progressbar.onCancel. Toolkit allows up to 10 minutes.

progressbar = {}
local cancelHandler

function progressbar.onCancel(handler)
    cancelHandler = handler
end

local CANCEL_CONTROLS = { 0x156F7119, 0x308588E6 } -- INPUT_FRONTEND_CANCEL, INPUT_GAME_MENU_CANCEL

function progressbar.start(text, durationMs, onComplete, theme, color, width, cancelable)
    local finished = false
    local started = Toolkit:StartProgress({
        message = tostring(text or ''):gsub('%c', ' '):sub(1, 160),
        durationMs = math.max(100, math.min(600000, math.floor(tonumber(durationMs) or 1000))),
        theme = (theme == 'linear' or theme == 'circle' or theme == 'innercircle') and theme or 'innercircle',
        color = type(color) == 'string' and color:match('^#%x%x%x%x%x%x$') and color or '#bb8844',
        widthPercent = math.max(5, math.min(100, tonumber(tostring(width or ''):match('(%d+)')) or 20))
    }, function(result)
        finished = true
        local outcome = type(result) == 'table' and result.ok and result.value.outcome
        if outcome == 'completed' then
            cancelHandler = nil
            if onComplete then onComplete() end
        elseif cancelHandler then
            local handler = cancelHandler
            cancelHandler = nil
            handler()
        end
    end)
    if type(started) ~= 'table' or not started.ok then
        devPrint('progress failed: ' .. tostring(type(started) == 'table' and started.code))
        if onComplete then onComplete() end
        return
    end
    if cancelable then
        local id = started.value.id
        CreateThread(function()
            while not finished do
                for _, control in ipairs(CANCEL_CONTROLS) do
                    if IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control) then
                        Toolkit:CancelProgress(id)
                    end
                end
                Wait(0)
            end
        end)
    end
end

-- Menu -------------------------------------------------------------------------

BCCCraftingMenu = FeatherMenu:RegisterMenu("bcc:crafting:mainmenu",
    {
        top = '3%',
        left = '3%',
        ['720width'] = '400px',
        ['1080width'] = '500px',
        ['2kwidth'] = '600px',
        ['4kwidth'] = '800px',
        style = {},
        contentslot = {
            style = {
                ['height'] = '450px',
                ['min-height'] = '300px'
            }
        },
    },
    {
        opened = function()
            DisplayRadar(false)
        end,
        closed = function()
            DisplayRadar(true)
            cleanupCampfireIfExists()
        end
    }
)
