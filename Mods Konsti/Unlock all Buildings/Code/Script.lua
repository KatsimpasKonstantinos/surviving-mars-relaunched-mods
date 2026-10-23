
local mod_name = "[Unlock all Buildings] "
local mod_id = CurrentModId
local options = CurrentModOptions

local opt_unlock_all = true

local category_remaps = {
    BlackCubeDump = "Storages",
    BlackCubeSmallMonument = "Decorations",
    BlackCubeLargeMonument = "Decorations",
    BlackCubeMonolith = "Wonders",
}

local mystery_override_buildings = {
    StorageMysteryResource = true,
    MechanizedDepotMysteryResource = true,
}

local sponsor_props = {
    "sponsor_name1",
    "sponsor_status1",
    "sponsor_name2",
    "sponsor_status2",
    "sponsor_name3",
    "sponsor_status3",
}

local function SafeSet(obj, prop, val)
    if obj and obj[prop] ~= nil then
        rawset(obj, prop, val)
    end
end

-- Snapshot raw properties, preserving nil and false separately.
local function SnapshotRawProps(obj, props)
    if not obj then
        return nil
    end

    local snapshot = {}

    for _, prop in ipairs(props) do
        local value = rawget(obj, prop)

        snapshot[prop] = {
            existed = value ~= nil,
            value = value,
        }
    end

    return snapshot
end

local function RestoreRawProps(obj, snapshot)
    if not obj or not snapshot then
        return
    end

    for prop, saved in pairs(snapshot) do
        if saved.existed then
            rawset(obj, prop, saved.value)
        else
            rawset(obj, prop, nil)
        end
    end
end

local function UpdateOptions()
    options = CurrentModOptions or options

    if not options then
        print(mod_name .. "CurrentModOptions is nil - keeping defaults")
        return
    end

    local val = options:GetProperty("UnlockAllBuildings")

    if val ~= nil then
        opt_unlock_all = val and true or false
    end
end

local function GetBuildingClass(id)
    local classes = rawget(_G, "g_Classes")
    return (classes and classes[id]) or rawget(_G, id)
end

local function GetOrCreateBackup()
    local backup = rawget(_G, "__UnlockAllBuildings_Backup")

    if not backup then
        backup = {
            templates = {},
            tech_reqs = {},
            overrides = {},
            mod_set_overrides = {},
        }

        rawset(_G, "__UnlockAllBuildings_Backup", backup)
    end

    backup.templates = backup.templates or {}
    backup.tech_reqs = backup.tech_reqs or {}
    backup.overrides = backup.overrides or {}
    backup.mod_set_overrides = backup.mod_set_overrides or {}

    -- New backups specifically for sponsor restrictions.
    -- Keep the original backup key so existing backups for other properties
    -- remain usable.
    backup.sponsor_template_raw = backup.sponsor_template_raw or {}
    backup.sponsor_class_raw = backup.sponsor_class_raw or {}

    return backup
end

local function MakeLegacySponsorBackup(template)
    local sponsors = {}

    for i = 1, 3 do
        sponsors[i] = {
            name = template["sponsor_name" .. i] or "",
            status = template["sponsor_status" .. i] or false,
        }
    end

    return sponsors
end

local function MakeEnvironmentBackup(template)
    local environments = {}

    for i = 1, 4 do
        environments[i] =
            template["disabled_in_environment" .. i] or ""
    end

    return environments
end

local function RestoreLegacySponsors(obj, sponsors)
    if not obj or not sponsors then
        return
    end

    for i = 1, 3 do
        local saved = sponsors[i]

        if saved then
            SafeSet(obj, "sponsor_name" .. i, saved.name)
            SafeSet(obj, "sponsor_status" .. i, saved.status)
        end
    end
end

local function BackupOriginalData()
    local templates = rawget(_G, "BuildingTemplates")
    if not templates then
        return nil
    end

    local tech_reqs = rawget(_G, "BuildingTechRequirements")
    local backup = GetOrCreateBackup()

    for id, template in pairs(templates) do
        if not template.hide_from_build_menu
            and template.build_category ~= "Hidden" then

            local cls = GetBuildingClass(id)

            -- IMPORTANT:
            -- Capture sponsor values independently for the template and class.
            -- This must happen before ApplyTemplateUnlocks modifies either.
            if not backup.sponsor_template_raw[id] then
                backup.sponsor_template_raw[id] =
                    SnapshotRawProps(template, sponsor_props)
            end

            if cls and not backup.sponsor_class_raw[id] then
                backup.sponsor_class_raw[id] =
                    SnapshotRawProps(cls, sponsor_props)
            end

            local orig = backup.templates[id]

            if not orig then
                orig = {
                    build_category = template.build_category or "",
                    sponsors = MakeLegacySponsorBackup(template),
                    environments = MakeEnvironmentBackup(template),
                }

                backup.templates[id] = orig
            end

            if tech_reqs and backup.tech_reqs[id] == nil then
                if tech_reqs[id] then
                    local copy = {}

                    for i, req in ipairs(tech_reqs[id]) do
                        copy[i] = {
                            tech = req.tech,
                            hide = req.hide,
                            check_supply = req.check_supply,
                        }
                    end

                    backup.tech_reqs[id] = copy
                else
                    backup.tech_reqs[id] = false
                end
            end
        end
    end

    return backup
end

local function ApplyTemplateUnlocks()
    local templates = rawget(_G, "BuildingTemplates")
    if not templates then
        return
    end

    local backup = BackupOriginalData()
    if not backup then
        return
    end

    local tech_reqs = rawget(_G, "BuildingTechRequirements")

    for id, orig in pairs(backup.templates) do
        local template = templates[id]

        if template then
            local cls = GetBuildingClass(id)

            if opt_unlock_all then
                -- 1. Sponsor and rival restrictions
                for i = 1, 3 do
                    SafeSet(template, "sponsor_name" .. i, "")
                    SafeSet(template, "sponsor_status" .. i, false)

                    SafeSet(cls, "sponsor_name" .. i, "")
                    SafeSet(cls, "sponsor_status" .. i, false)
                end

                -- 2. Environment restrictions
                for i = 1, 4 do
                    local prop = "disabled_in_environment" .. i

                    SafeSet(template, prop, "")
                    SafeSet(cls, prop, "")
                end

                -- 3. Remap hidden building categories
                local remapped_cat = category_remaps[id]

                if remapped_cat then
                    SafeSet(template, "build_category", remapped_cat)
                    SafeSet(cls, "build_category", remapped_cat)
                end

            else
                -- 1. Restore sponsor/rival restrictions independently.
                -- These snapshots are authoritative when available.
                local template_sponsors = backup.sponsor_template_raw[id]
                local class_sponsors = backup.sponsor_class_raw[id]

                if template_sponsors then
                    RestoreRawProps(template, template_sponsors)
                else
                    RestoreLegacySponsors(template, orig.sponsors)
                end

                if class_sponsors then
                    RestoreRawProps(cls, class_sponsors)
                else
                    -- Compatibility with backups created by the old mod.
                    RestoreLegacySponsors(cls, orig.sponsors)
                end

                -- 2. Restore environment restrictions
                for i = 1, 4 do
                    local prop = "disabled_in_environment" .. i
                    local env = orig.environments
                        and orig.environments[i]
                        or ""

                    SafeSet(template, prop, env)
                    SafeSet(cls, prop, env)
                end

                -- 3. Restore original building categories
                local remapped_cat = category_remaps[id]

                if remapped_cat then
                    SafeSet(
                        template,
                        "build_category",
                        orig.build_category
                    )

                    SafeSet(
                        cls,
                        "build_category",
                        orig.build_category
                    )
                end
            end

            -- 4. Technology and other build requirements
            local orig_reqs = backup.tech_reqs[id]

            if tech_reqs and orig_reqs then
                if opt_unlock_all then
                    tech_reqs[id] = nil
                else
                    local restored = {}

                    for i, req in ipairs(orig_reqs) do
                        restored[i] = {
                            tech = req.tech,
                            hide = req.hide,
                            check_supply = req.check_supply,
                        }
                    end

                    tech_reqs[id] = restored
                end
            end
        end
    end
end

local function ApplyRuntimeUnlocks()
    UpdateOptions()
    ApplyTemplateUnlocks()

    local overrides = rawget(_G, "BuildMenuPrerequisiteOverrides")
    local templates = rawget(_G, "BuildingTemplates")

    if not overrides or not templates then
        return
    end

    local backup = GetOrCreateBackup()

    -- Revert runtime overrides changed by this mod.
    for id in pairs(backup.mod_set_overrides) do
        overrides[id] = backup.overrides[id]
        backup.mod_set_overrides[id] = nil
    end

    if not opt_unlock_all then
        return
    end

    for id in pairs(backup.templates) do
        if overrides[id] ~= nil
            and overrides[id] ~= true
            and backup.overrides[id] == nil then

            backup.overrides[id] = overrides[id]
        end

        if mystery_override_buildings[id] then
            overrides[id] = true
            backup.mod_set_overrides[id] = true

        elseif overrides[id] ~= nil and overrides[id] ~= true then
            overrides[id] = nil
            backup.mod_set_overrides[id] = true
        end
    end
end

function OnMsg.ClassesPostprocess()
    UpdateOptions()
    ApplyTemplateUnlocks()
end

function OnMsg.ApplyModOptions(id)
    if id and mod_id and id ~= mod_id then
        return
    end

    ApplyRuntimeUnlocks()
end

function OnMsg.CityStart()
    ApplyRuntimeUnlocks()
end

function OnMsg.LoadGame()
    ApplyRuntimeUnlocks()
end

UpdateOptions()
