local default_normal_speed = 1
local default_medium_speed = 5
local default_fast_speed = 15

local normal_speed = default_normal_speed
local medium_speed = default_medium_speed
local fast_speed = default_fast_speed

local mod_name = "[Custom Speed]"
local mod_id = CurrentModId
local options = CurrentModOptions

local function GetNumberOption(prop_name, default_val)
    if not options then
        return default_val
    end
    local val = tonumber(options:GetProperty(prop_name))
    if not val then
        print(mod_name .. " ERROR: " .. prop_name .. " could not be converted to a number")
        return default_val
    end
    return val
end

local function SpeedLabels()
    return {
        normal_text = "Play at normal speed (" .. normal_speed .. "x)",
        medium_title = "Fast (" .. medium_speed .. "x)",
        medium_text = "Play at " .. medium_speed .. " times normal speed",
        fast_title = "Fastest (" .. fast_speed .. "x)",
        fast_text = "Play at " .. fast_speed .. " times normal speed",
    }
end

local function ApplyButtonRollover(btn, title, text)
    if not btn then return end
    if title then
        btn.RolloverTitle = title
        if btn.SetRolloverTitle then btn:SetRolloverTitle(title) end
    end
    btn.RolloverText = text
    if btn.SetRolloverText then btn:SetRolloverText(text) end
end

local function SyncHUDButtons(hud)
    if not hud or type(GetTimeFactor) ~= "function" then return end

    local factor = GetTimeFactor()
    local is_paused = (type(IsPaused) == "function" and IsPaused()) or factor == 0

    local norm_factor = normal_speed * 1000
    local med_factor = medium_speed * 1000
    local fast_factor = fast_speed * 1000

    if hud.idPause and hud.idPause.SetToggled then
        hud.idPause:SetToggled(is_paused)
    end
    if hud.idPlay and hud.idPlay.SetToggled then
        hud.idPlay:SetToggled(not is_paused and factor == norm_factor)
    end
    if hud.idNormal and hud.idNormal.SetToggled then
        hud.idNormal:SetToggled(not is_paused and factor == norm_factor)
    end
    if hud.idMedium and hud.idMedium.SetToggled then
        hud.idMedium:SetToggled(not is_paused and factor == med_factor)
    end
    if hud.idFast and hud.idFast.SetToggled then
        hud.idFast:SetToggled(not is_paused and factor == fast_factor and factor ~= med_factor)
    end
end

local function OverrideTranslations(l)
    if type(TranslationTable) ~= "table" then return end
    TranslationTable[589021399991] = l.normal_text
    TranslationTable[476435596270] = l.medium_text
    TranslationTable[110259542223] = l.medium_title
    TranslationTable[941799678429] = l.fast_text
    TranslationTable[187924928034] = l.fast_title
end

local function RewriteHUD(hud, l)
    if not hud then return end
    l = l or SpeedLabels()

    ApplyButtonRollover(hud.idNormal, nil, l.normal_text)
    ApplyButtonRollover(hud.idMedium, l.medium_title, l.medium_text)
    ApplyButtonRollover(hud.idFast, l.fast_title, l.fast_text)

    SyncHUDButtons(hud)
end

local function SafeRewriteHUD(hud, l)
    local ok, err = pcall(RewriteHUD, hud, l)
    if not ok then
        print(mod_name .. " HUD label rewrite failed:", err)
    end
end

local function ApplySpeeds()
    if const then
        if const.normalGameSpeed then const.normalGameSpeed = normal_speed end
        const.mediumGameSpeed = medium_speed
        const.fastGameSpeed = fast_speed

        if const.GameSpeeds then
            const.GameSpeeds.normal = normal_speed
            const.GameSpeeds.medium = medium_speed
            const.GameSpeeds.fast = fast_speed
        end
    end

    if type(UpdateGameSpeedLimit) == "function" then
        UpdateGameSpeedLimit()
    end

    local labels = SpeedLabels()
    OverrideTranslations(labels)

    local hud = GetHUD and GetHUD() or (Dialogs and Dialogs.HUD)
    SafeRewriteHUD(hud, labels)
end

local function UpdateSpeeds()
    options = CurrentModOptions or options
    if not options then
        print(mod_name .. " CurrentModOptions is nil - keeping default speeds")
    end

    normal_speed = GetNumberOption("Normalspeed", default_normal_speed)
    medium_speed = GetNumberOption("Mediumspeed", default_medium_speed)
    fast_speed = GetNumberOption("Fastspeed", default_fast_speed)

    ApplySpeeds()
end

function OnMsg.ClassesBuilt()
    UpdateSpeeds()

    if type(GetGameSpeed) == "function" and type(GetTimeFactor) == "function" then
        local old_get_speed = GetGameSpeed
        function GetGameSpeed()
            if (type(IsPaused) == "function" and IsPaused()) or GetTimeFactor() == 0 then
                return "pause"
            end
            local factor = GetTimeFactor()
            if factor == medium_speed * 1000 then return "medium" end
            if factor == fast_speed * 1000 then return "fast" end
            if factor == normal_speed * 1000 then return "normal" end
            return old_get_speed()
        end
    end

    if not HUDClass then
        print(mod_name .. " HUDClass not found at ClassesBuilt")
        return
    end

    local function HookHUDMethod(method_name)
        local old_method = HUDClass[method_name]
        if old_method then
            HUDClass[method_name] = function(self, ...)
                local result = old_method(self, ...)
                SafeRewriteHUD(self)
                return result
            end
        end
    end

    HookHUDMethod("UpdateTimeButtons")
    HookHUDMethod("Open")
end

function OnMsg.ApplyModOptions(id)
    if id and mod_id and id ~= mod_id then
        return
    end
    UpdateSpeeds()
end

OnMsg.CityStart = UpdateSpeeds
OnMsg.NewMapLoaded = UpdateSpeeds
OnMsg.LoadGame = UpdateSpeeds
UpdateSpeeds()