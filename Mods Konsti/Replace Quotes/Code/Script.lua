local TGetID = rawget(_G, "TGetID")
local IsT = rawget(_G, "IsT")
local _InternalTranslate = rawget(_G, "TTranslate") or rawget(_G, "_InternalTranslate")
local ModLog = rawget(_G, "ModLog")

local DEBUG_LOGGING = false
local FORCE_DEFAULT_OPTIONS = false

local remove_quotes = false
local replace_elon_musk = true
local replace_vladimir_putin = true
local replace_ronald_reagan = true
local replace_vegans = true

local mod_name = "[Replace Quotes]"
local mod_id = rawget(_G, "CurrentModId")
local options = rawget(_G, "CurrentModOptions")

local original_strings = {}
local original_t_tables = {} -- Maps T_table -> original t[2] inline string
local active_overrides = {}

local function DebugLog(fmt, ...)
    if not DEBUG_LOGGING then return end
    local ok, msg = pcall(string.format, fmt, ...)
    if not ok then
        msg = tostring(fmt)
    end
    local full_msg = mod_name .. " " .. msg
    print(full_msg)
    if type(ModLog) == "function" then
        ModLog(full_msg)
    end
end

local quotes_list = {
    -- Legacy IDs (Original Surviving Mars)
    [7933] = [[<grey>"I plan to live forever, of course, but barring that I'd settle for a couple thousand years. Even five hundred would be pretty nice."
<right>Nwabudike Morgan</grey><left>]],
    [6356] = [[<grey>"Some civilian workers got in among the research patients today and became so hysterical I felt compelled to have them nerve stapled. The consequence, of course, will be another public relations nightmare, but I was severely shaken by the extent of their revulsion towards a project so vital to our survival."
<right>Nwabudike Morgan</grey><left>]],
    [6497] = [[<grey>"Planet's Primary, Alpha Centauri A, blasts unimaginable quantities of energy into space each instant, and virtually every joule of it is wasted entirely. Incomprehensible riches can be ours if we can but stretch our arms wide enough to dip from this eternal river of wealth."
<right>Nwabudike Morgan</grey><left>]],
    [825589330974] = [[<grey>"Resources exist to be consumed. And consumed they will be, if not by this generation then by some future. By what right does this forgotten future seek to deny us our birthright? None I say! Let us take what is ours, chew and eat our fill."
<right>Nwabudike Morgan</grey><left>]],
    [10515] = [[<grey>"Today the dreams of the best sons of mankind have come true. The assault on space has begun."
<right>Sergei Korolev</grey><left>]],
    [6512] = [[<grey>"This is a present from a small, distant world, a token of our sounds, our science, our images, our music, our thoughts and our feelings. We are attempting to survive our time so we may live into yours."
<right>Jimmy Carter</grey><left>]],

    -- Surviving Mars: Relaunched IDs (Presets.Tech flavor)
    [542089089588] = [[<grey>"I plan to live forever, of course, but barring that I'd settle for a couple thousand years. Even five hundred would be pretty nice."
<right>Nwabudike Morgan</grey><left>]],
    [180180820096] = [[<grey>"Human behavior is economic behavior. The particulars may vary, but competition for limited resources remains a constant."
<right>Nwabudike Morgan</grey><left>]],
    [843410249964] = [[<grey>"Planet's Primary, Alpha Centauri A, blasts unimaginable quantities of energy into space each instant, and virtually every joule of it is wasted entirely. Incomprehensible riches can be ours if we can but stretch our arms wide enough to dip from this eternal river of wealth."
<right>Nwabudike Morgan</grey><left>]],
    [187973786134] = [[<grey>"Resources exist to be consumed. And consumed they will be, if not by this generation then by some future. By what right does this forgotten future seek to deny us our birthright? None I say! Let us take what is ours, chew and eat our fill."
<right>Nwabudike Morgan</grey><left>]],
    [440839757406] = [[<grey>"Today the dreams of the best sons of mankind have come true. The assault on space has begun."
<right>Sergei Korolev</grey><left>]],
    [270865958824] = [[<grey>"This is a present from a small, distant world, a token of our sounds, our science, our images, our music, our thoughts and our feelings. We are attempting to survive our time so we may live into yours."
<right>Jimmy Carter</grey><left>]],

    -- Non-tech strings
    [1249] = [[Carter]],
    [11782] = [[Nwabudike]],
    [12573] = [[Veganism is the practice of abstaining from the use of animal products and the consumption of animal source foods.<if(has_dlc('shepard'))>

Has decreased Comfort when living near a Ranch and won't work in such buildings. Has increased Comfort when away from Ranches.</if>]],
}

local legacy_musk_ids = { 7933, 6356, 6497, 825589330974 }
local relaunched_musk_ids = { 542089089588, 180180820096, 843410249964, 187973786134 }

local legacy_putin_ids = { 10515 }
local relaunched_putin_ids = { 440839757406 }

local legacy_reagan_ids = { 6512 }
local relaunched_reagan_ids = { 270865958824 }

local function GetBoolOption(prop_name, default_val)
    if FORCE_DEFAULT_OPTIONS then
        return default_val
    end
    if not options or type(options.GetProperty) ~= "function" then
        return default_val
    end
    local val = options:GetProperty(prop_name)
    if type(val) ~= "boolean" then
        return default_val
    end
    return val
end

local function BackupAndGetString(tt, string_idx)
    if not string_idx then return nil end
    if original_strings[string_idx] == nil then
        local current = tt[string_idx]
        if type(current) == "string" and current ~= "" and current ~= " " and current ~= quotes_list[string_idx] then
            original_strings[string_idx] = current
        end
    end
    return original_strings[string_idx]
end

local function RestoreOriginalStrings(tt)
    for idx, orig_str in pairs(original_strings) do
        tt[idx] = orig_str
    end
    for t_tbl, orig_inline in pairs(original_t_tables) do
        rawset(t_tbl, 2, orig_inline)
    end
end

local function ReplaceEmbeddedQuote(tt, string_idx, replace_text, search_text)
    local str = BackupAndGetString(tt, string_idx)
    if not str then return end

    search_text = search_text or "<grey>"
    local idx = str:find(search_text, 1, true)
    if not idx then return end

    local new_str
    if replace_text and replace_text ~= "" then
        new_str = str:sub(1, idx - 1) .. replace_text
    else
        local prefix = str:sub(1, idx - 1)
        new_str = (prefix ~= "") and prefix or " "
    end

    tt[string_idx] = new_str
    active_overrides[string_idx] = new_str
end

local function SetDirectString(tt, string_idx, new_text)
    BackupAndGetString(tt, string_idx)
    if not new_text or new_text == "" then
        new_text = " "
    end
    tt[string_idx] = new_text
    active_overrides[string_idx] = new_text
end

local function ReplaceLegacyList(tt, id_list, clear_only)
    for _, id in ipairs(id_list) do
        ReplaceEmbeddedQuote(tt, id, clear_only and "" or quotes_list[id])
    end
end

local function ReplaceRelaunchedList(tt, id_list, clear_only)
    for _, id in ipairs(id_list) do
        SetDirectString(tt, id, clear_only and "" or quotes_list[id])
    end
end

-- Patches a T() table { [1] = id, [2] = inline_str } in-place
local function PatchTTable(t, prop_name)
    if type(t) ~= "table" then return 0 end
    local id = rawget(t, 1)
    local inline_str = rawget(t, 2)
    if type(id) ~= "number" or type(inline_str) ~= "string" then
        return 0
    end

    local orig_str = original_t_tables[t] or inline_str
    local new_str = active_overrides[id]

    -- If remove_quotes is on, strip any quote from flavor or embedded <grey> tags
    if remove_quotes and new_str == nil then
        if prop_name == "flavor" then
            new_str = " "
        elseif orig_str:find("<grey>", 1, true) then
            local idx = orig_str:find("<grey>", 1, true)
            new_str = (idx > 1) and orig_str:sub(1, idx - 1) or " "
        end
    end

    if new_str ~= nil then
        if original_t_tables[t] == nil then
            original_t_tables[t] = inline_str
        end
        if orig_str:find("<grey>", 1, true) and not orig_str:find("^<grey>") and new_str:find("^<grey>") then
            local idx = orig_str:find("<grey>", 1, true)
            new_str = orig_str:sub(1, idx - 1) .. new_str
        end
        rawset(t, 2, new_str)
        return 1
    end
    return 0
end

-- Scans a Preset category (like Presets.Tech or Presets.TraitPreset) and patches its T() properties
local function PatchPresetCategory(preset_cat)
    if type(preset_cat) ~= "table" then return 0 end
    local patched = 0
    for _, group in ipairs(preset_cat) do
        if type(group) == "table" then
            for _, item in ipairs(group) do
                if type(item) == "table" then
                    patched = patched + PatchTTable(rawget(item, "flavor"), "flavor")
                    patched = patched + PatchTTable(rawget(item, "description"), "description")
                    patched = patched + PatchTTable(rawget(item, "display_name"), "display_name")
                end
            end
        end
    end
    return patched
end

local function ApplyQuotes(trigger_reason)
    local tt = rawget(_G, "TranslationTable")
    if type(tt) ~= "table" then
        return
    end

    RestoreOriginalStrings(tt)
    active_overrides = {}

    if remove_quotes then
        for id, str in pairs(tt) do
            if type(str) == "string" and (str:find("^<grey>\"") or str:find("^<grey>'")) then
                SetDirectString(tt, id, " ")
            end
        end
        ReplaceLegacyList(tt, legacy_musk_ids, true)
        ReplaceLegacyList(tt, legacy_putin_ids, true)
        ReplaceLegacyList(tt, legacy_reagan_ids, true)

        ReplaceRelaunchedList(tt, relaunched_musk_ids, true)
        ReplaceRelaunchedList(tt, relaunched_putin_ids, true)
        ReplaceRelaunchedList(tt, relaunched_reagan_ids, true)
    else
        if replace_elon_musk then
            ReplaceLegacyList(tt, legacy_musk_ids, false)
            ReplaceRelaunchedList(tt, relaunched_musk_ids, false)
        end
        if replace_vladimir_putin then
            ReplaceLegacyList(tt, legacy_putin_ids, false)
            ReplaceRelaunchedList(tt, relaunched_putin_ids, false)
        end
        if replace_ronald_reagan then
            ReplaceLegacyList(tt, legacy_reagan_ids, false)
            ReplaceRelaunchedList(tt, relaunched_reagan_ids, false)
        end
    end

    -- Non-tech strings
    if replace_elon_musk then
        SetDirectString(tt, 11782, quotes_list[11782])
    end
    if replace_ronald_reagan then
        SetDirectString(tt, 1249, quotes_list[1249])
    end
    if replace_vegans then
        SetDirectString(tt, 12573, quotes_list[12573])
    end

    -- Patch T-tables in-place inside Presets.Tech, Presets.TechPreset, and Presets.TraitPreset
    local total_patched = 0
    local presets = rawget(_G, "Presets")
    if type(presets) == "table" then
        total_patched = total_patched + PatchPresetCategory(presets.Tech)
        total_patched = total_patched + PatchPresetCategory(presets.TechPreset)
        total_patched = total_patched + PatchPresetCategory(presets.TraitPreset)
    end

    DebugLog("ApplyQuotes (%s): patched %d preset T-tables (remove=%s, musk=%s, putin=%s, reagan=%s, vegans=%s)",
        tostring(trigger_reason), total_patched,
        tostring(remove_quotes), tostring(replace_elon_musk),
        tostring(replace_vladimir_putin), tostring(replace_ronald_reagan), tostring(replace_vegans))

    Msg("TranslationChanged", "CustomQuotes_skip_msg")
end

local function UpdateQuoteOptions(trigger_reason)
    options = rawget(_G, "CurrentModOptions") or options
    mod_id = rawget(_G, "CurrentModId") or mod_id

    remove_quotes = GetBoolOption("RemoveQuotes", false)
    replace_elon_musk = GetBoolOption("ElonMusk", true)
    replace_vladimir_putin = GetBoolOption("VladimirPutin", true)
    replace_ronald_reagan = GetBoolOption("RonaldReagan", true)
    replace_vegans = GetBoolOption("Vegans", true)

    ApplyQuotes(trigger_reason or "UpdateQuoteOptions")
end

function OnMsg.TranslationChanged(skip)
    if skip == "CustomQuotes_skip_msg" then
        return
    end
    ApplyQuotes("OnMsg.TranslationChanged")
end

function OnMsg.ApplyModOptions(id)
    mod_id = rawget(_G, "CurrentModId") or mod_id
    if id and mod_id and id ~= mod_id then
        return
    end
    UpdateQuoteOptions("OnMsg.ApplyModOptions")
end

function OnMsg.ClassesBuilt() UpdateQuoteOptions("OnMsg.ClassesBuilt") end
function OnMsg.DataLoaded() UpdateQuoteOptions("OnMsg.DataLoaded") end
function OnMsg.ModsReloaded() UpdateQuoteOptions("OnMsg.ModsReloaded") end
function OnMsg.CityStart() UpdateQuoteOptions("OnMsg.CityStart") end
function OnMsg.NewMapLoaded() UpdateQuoteOptions("OnMsg.NewMapLoaded") end
function OnMsg.LoadGame() UpdateQuoteOptions("OnMsg.LoadGame") end

UpdateQuoteOptions("Initial Script Load")