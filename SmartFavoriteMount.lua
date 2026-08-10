BINDING_NAME_SFM_SUMMON_SMART_FAVORITE = "Summon Smart Favorite Mount"

local DATABASE_VERSION = 2

local groundFavoriteButton
local flyingFavoriteButton
local mountJournalHooked = false


-- =========================================================
-- Mount helpers
-- =========================================================

local function FindMountByName(searchName)
    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local name = C_MountJournal.GetMountInfoByID(mountID)

        if name and string.lower(name) == string.lower(searchName) then
            return mountID
        end
    end

    return nil
end


local function GetMountName(mountID)
    return C_MountJournal.GetMountInfoByID(mountID)
end


local function GetUsableFavorite(favorites)
    local candidates = {}

    for mountID, isFavorite in pairs(favorites) do
        if isFavorite then
            local _, _, _, _, isUsable, _, _, _, _, _, isCollected =
                C_MountJournal.GetMountInfoByID(mountID)

            if isCollected and isUsable then
                table.insert(candidates, mountID)
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[math.random(#candidates)]
end


-- =========================================================
-- Database
-- =========================================================

local function MigrateFavorites(oldFavorites)
    local migratedFavorites = {}

    if not oldFavorites then
        return migratedFavorites
    end

    for key, value in pairs(oldFavorites) do
        -- Old format: { "Raven Lord", "Invincible" }
        if type(key) == "number" and type(value) == "string" then
            local mountID = FindMountByName(value)

            if mountID then
                migratedFavorites[mountID] = true
            end

        -- Current format: { [185] = true }
        elseif type(key) == "number" and value == true then
            migratedFavorites[key] = true
        end
    end

    return migratedFavorites
end


local function InitializeDatabase()
    if not SmartFavoriteMountDB then
        SmartFavoriteMountDB = {}
    end

    if not SmartFavoriteMountDB.ground then
        SmartFavoriteMountDB.ground = {}
    end

    if not SmartFavoriteMountDB.flying then
        SmartFavoriteMountDB.flying = {}
    end

    local currentVersion = SmartFavoriteMountDB.version or 1

    if currentVersion < DATABASE_VERSION then
        SmartFavoriteMountDB.ground =
            MigrateFavorites(SmartFavoriteMountDB.ground)

        SmartFavoriteMountDB.flying =
            MigrateFavorites(SmartFavoriteMountDB.flying)

        SmartFavoriteMountDB.version = DATABASE_VERSION
    end
end


local function IsFavorite(mountType, mountID)
    local favorites = SmartFavoriteMountDB[mountType]

    return favorites and favorites[mountID] == true
end


local function ToggleFavorite(mountType, mountID)
    local favorites = SmartFavoriteMountDB[mountType]

    if not favorites then
        return
    end

    if favorites[mountID] then
        favorites[mountID] = nil
    else
        favorites[mountID] = true
    end
end


local function ListFavoriteGroup(title, favorites)
    print(title)

    local foundFavorite = false

    for mountID, isFavorite in pairs(favorites) do
        if isFavorite then
            local mountName = GetMountName(mountID)

            if mountName then
                print("  - " .. mountName)
                foundFavorite = true
            end
        end
    end

    if not foundFavorite then
        print("  None")
    end
end


local function ListFavorites()
    print("|cff00ccffSmart Favorite Mount Favorites|r")

    ListFavoriteGroup(
        "|cffffcc00Ground:|r",
        SmartFavoriteMountDB.ground
    )

    ListFavoriteGroup(
        "|cff66ccffFlying:|r",
        SmartFavoriteMountDB.flying
    )
end


-- =========================================================
-- Smart summon
-- =========================================================

function SummonSmartFavorite()
    local mountID

    if IsFlyableArea() then
        mountID = GetUsableFavorite(SmartFavoriteMountDB.flying)

        if not mountID then
            mountID = GetUsableFavorite(SmartFavoriteMountDB.ground)
        end
    else
        mountID = GetUsableFavorite(SmartFavoriteMountDB.ground)
    end

    if not mountID then
        print(
            "|cffff4444Smart Favorite Mount:|r "
            .. "No usable favorites found."
        )
        return
    end

    C_MountJournal.SummonByID(mountID)
end


-- =========================================================
-- Mount Journal UI
-- =========================================================

local function UpdateMountJournalButtons()
    if not groundFavoriteButton or not flyingFavoriteButton then
        return
    end

    if not MountJournal or not MountJournal.selectedMountID then
        return
    end

    local mountID = MountJournal.selectedMountID

    if IsFavorite("ground", mountID) then
        groundFavoriteButton:SetText("Ground +")
    else
        groundFavoriteButton:SetText("Ground")
    end

    if IsFavorite("flying", mountID) then
        flyingFavoriteButton:SetText("Flying +")
    else
        flyingFavoriteButton:SetText("Flying")
    end
end


local function ShowFavoriteTooltip(button, mountType, title)
    local mountID = MountJournal.selectedMountID

    if not mountID then
        return
    end

    local mountName = GetMountName(mountID) or "Selected mount"
    local isFavorite = IsFavorite(mountType, mountID)

    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(title)

    if isFavorite then
        GameTooltip:AddLine(
            "Click to remove "
                .. mountName
                .. " from your "
                .. mountType
                .. " favorites.",
            1,
            1,
            1,
            true
        )
    else
        GameTooltip:AddLine(
            "Click to add "
                .. mountName
                .. " to your "
                .. mountType
                .. " favorites.",
            1,
            1,
            1,
            true
        )
    end

    GameTooltip:Show()
end


local function CreateMountJournalButtons()
    if groundFavoriteButton or not MountJournal then
        return
    end

    -- Ground button
    groundFavoriteButton = CreateFrame(
        "Button",
        nil,
        MountJournal,
        "UIPanelButtonTemplate"
    )

    groundFavoriteButton:SetSize(110, 24)
    groundFavoriteButton:SetText("Ground")
    groundFavoriteButton:SetFrameStrata("DIALOG")
    groundFavoriteButton:SetFrameLevel(MountJournal:GetFrameLevel() + 20)

    groundFavoriteButton:SetPoint(
        "BOTTOM",
        MountJournal,
        "BOTTOM",
        -60,
        0
    )

    groundFavoriteButton:SetScript("OnClick", function()
        local mountID = MountJournal.selectedMountID

        if not mountID then
            return
        end

        ToggleFavorite("ground", mountID)
        UpdateMountJournalButtons()
    end)

    groundFavoriteButton:SetScript("OnEnter", function(self)
        ShowFavoriteTooltip(
            self,
            "ground",
            "Ground Favorite"
        )
    end)

    groundFavoriteButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


    -- Flying button
    flyingFavoriteButton = CreateFrame(
        "Button",
        nil,
        MountJournal,
        "UIPanelButtonTemplate"
    )

    flyingFavoriteButton:SetSize(110, 24)
    flyingFavoriteButton:SetText("Flying")
    flyingFavoriteButton:SetFrameStrata("DIALOG")
    flyingFavoriteButton:SetFrameLevel(MountJournal:GetFrameLevel() + 20)

    flyingFavoriteButton:SetPoint(
        "LEFT",
        groundFavoriteButton,
        "RIGHT",
        10,
        0
    )

    flyingFavoriteButton:SetScript("OnClick", function()
        local mountID = MountJournal.selectedMountID

        if not mountID then
            return
        end

        ToggleFavorite("flying", mountID)
        UpdateMountJournalButtons()
    end)

    flyingFavoriteButton:SetScript("OnEnter", function(self)
        ShowFavoriteTooltip(
            self,
            "flying",
            "Flying Favorite"
        )
    end)

    flyingFavoriteButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdateMountJournalButtons()
end


local function SetupMountJournal()
    if not MountJournal then
        return
    end

    CreateMountJournalButtons()

    if not mountJournalHooked and MountJournal_SetSelected then
        hooksecurefunc(
            "MountJournal_SetSelected",
            UpdateMountJournalButtons
        )

        mountJournalHooked = true
    end
end


-- =========================================================
-- Events
-- =========================================================

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "SmartFavoriteMount" then
        InitializeDatabase()

        -- Covers the case where Blizzard_Collections
        -- was already loaded before this addon.
        if MountJournal then
            SetupMountJournal()
        end
    elseif addonName == "Blizzard_Collections" then
        SetupMountJournal()
    end
end)


-- =========================================================
-- Slash command
-- =========================================================

SLASH_SMARTFAVORITEMOUNT1 = "/sfm"

SlashCmdList["SMARTFAVORITEMOUNT"] = function(msg)
    local command = string.lower(msg or "")

    if command == "" then
        SummonSmartFavorite()
        return
    end

    if command == "list" then
        ListFavorites()
        return
    end

    print("|cffffcc00Smart Favorite Mount commands:|r")
    print("/sfm")
    print("/sfm list")
end