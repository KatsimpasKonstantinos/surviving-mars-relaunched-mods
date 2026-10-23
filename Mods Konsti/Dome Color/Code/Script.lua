local default_red = 255
local default_green = 255
local default_blue = 255

local glass_red = default_red
local glass_green = default_green
local glass_blue = default_blue

local mod_name = "[Dome Color] "
local mod_id = CurrentModId
local mod_options = CurrentModOptions



-- Safely fetch attaches without tripping CommonLua's undefined-global assert
-- on C-level auto-attach entities (like LampInt_04) that lack a Lua class.
local function SafeGetAttaches(obj)
    local mt = getmetatable(_G)
    local orig_index = mt and mt.__index
    if mt then
        mt.__index = nil
    end

    local ok, attaches = pcall(obj.GetAttaches, obj)

    if mt then
        mt.__index = orig_index
    end

    return ok and attaches or nil
end

local function ApplyTintToDome(dome)
    if not IsValid(dome) then
        return
    end

    local attaches = SafeGetAttaches(dome)
    if not attaches then
        return
    end

    local color = RGB(glass_red, glass_green, glass_blue)

    for _, attach in ipairs(attaches) do
        if IsValid(attach) then
            local att_entity = attach:GetEntity() or ""
            local att_class = attach.class or ""

            if string.find(att_entity, "Glass") or string.find(att_class, "Glass") then
                attach:SetColorModifier(color)
            end
        end
    end
end

-- Force the dome to rebuild/rerender its current skin so the glass mesh does not vanish
local function RefreshDomeGlass(dome)
    if not IsValid(dome) then
        return
    end

    if dome.GetCurrentSkin and dome.ChangeSkin then
        local skin, palette = dome:GetCurrentSkin()
        if skin then
            dome:ChangeSkin(skin, palette)
            return
        end
    end

    ApplyTintToDome(dome)
end

local function ApplyTintToAllDomes()
    local domes
    if UIColony and UIColony.GetCityLabels then
        domes = UIColony:GetCityLabels("Dome")
    elseif UICity and UICity.labels then
        domes = UICity.labels.Dome
    end

    if not domes then
        return
    end

    for _, dome in ipairs(domes) do
        RefreshDomeGlass(dome)
    end
end

local function UpdateGlassSettings()
    local options = mod_options or CurrentModOptions or (mod_id and Mods and Mods[mod_id] and Mods[mod_id].options)
    if not options then
        print(mod_name .. "CurrentModOptions is nil - keeping default glass settings")
        glass_red = default_red
        glass_green = default_green
        glass_blue = default_blue
        return
    end

    glass_red = tonumber(options:GetProperty("GlassRed")) or default_red
    glass_green = tonumber(options:GetProperty("GlassGreen")) or default_green
    glass_blue = tonumber(options:GetProperty("GlassBlue")) or default_blue

    ApplyTintToAllDomes()
end

-- Called automatically inside Dome:ChangeSkin (both via paintbrush and RefreshDomeGlass)
local orig_Dome_OnSkinChanged = Dome.OnSkinChanged
function Dome:OnSkinChanged(skin, palette)
    if orig_Dome_OnSkinChanged then
        orig_Dome_OnSkinChanged(self, skin, palette)
    end
    ApplyTintToDome(self)
end

-- Apply automatically when a new dome finishes construction
local orig_Dome_GameInit = Dome.GameInit
function Dome:GameInit()
    if orig_Dome_GameInit then
        orig_Dome_GameInit(self)
    end
    CreateRealTimeThread(function()
        RefreshDomeGlass(self)
    end)
end

function OnMsg.ApplyModOptions(id)
    if id and mod_id and id ~= mod_id then
        return
    end
    UpdateGlassSettings()
end

function OnMsg.CityStart()
    UpdateGlassSettings()
end

function OnMsg.LoadGame()
    UpdateGlassSettings()
end