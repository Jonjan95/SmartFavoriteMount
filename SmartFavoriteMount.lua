BINDING_NAME_SFM_SUMMON_SMART_FAVORITE = "Summon Smart Favorite Mount"

local DATABASE_VERSION = 2

local groundFavoriteButton
local flyingFavoriteButton


-- =========================================================
-- Mount helpers
-- =========================================================

local function FindMountByName(searchName)
    local mountIDs = C_MountJournal.GetMountIDs()

    for _, mountID in ipairs(mountIDs) do
        local name = C_MountJournal.GetMountInfoByID(mountID)

        if name and string.lower(name) == string.lower(searchName) then
            return mountID
        end
    end

    return nil
end


local function GetMountName(mountID)
    local name = C_MountJournal.GetMountInfoByID(mountID)

    return name
end


local function GetRandomFavorite(favorites)
    local mountIDs = {}

    for mountID, isFavorite in pairs(favorites) do
        if isFavorite and type(mountID) == "number" then
            table.insert(mountIDs, mountID)
        end
    end

    if #mountIDs == 0 then
        return nil
    end

    return mountIDs[math.random(#mountIDs)]
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

        -- Old format:
        -- { "Raven Lord", "Invincible" }
        if type(key) == "number" and type(value) == "string" then
            local mountID = FindMountByName(value)

            if mountID then
                migratedFavorites[mountID] = true
            end

        -- New format already:
        -- { [185] = true }
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

        print(
            "|cff00ccffSmart Favorite Mount:|r "
            .. "Favorite database upgraded."
        )
    end
end


local function IsFavorite(mountType, mountID)
    local favorites = SmartFavoriteMountDB[mountType]

    if not favorites then
        return false
    end

    return favorites[mountID] == true
end


local function AddFavorite(mountType, mountID)
    local favorites = SmartFavoriteMountDB[mountType]

    if not favorites then
        print("|cffff4444Smart Favorite Mount:|r Invalid mount type.")
        return
    end

    local mountName = GetMountName(mountID)

    if not mountName then
        print("|cffff4444Smart Favorite Mount:|r Mount not found.")
        return
    end

    if favorites[mountID] then
        print(
            "|cffffcc00Smart Favorite Mount:|r "
            .. mountName
            .. " is already a "
            .. mountType
            .. " favorite."
        )
        return
    end

    favorites[mountID] = true

    print(
        "|cff00ff00Smart Favorite Mount:|r Added "
        .. mountName
        .. " as "
        .. mountType
        .. "."
    )
end


local function RemoveFavorite(mountType, mountID)
    local favorites = SmartFavoriteMountDB[mountType]

    if not favorites then
        print("|cffff4444Smart Favorite Mount:|r Invalid mount type.")
        return
    end

    local mountName = GetMountName(mountID) or "Unknown Mount"

    if not favorites[mountID] then
        print(
            "|cffff4444Smart Favorite Mount:|r "
            .. mountName
            .. " is not a "
            .. mountType
            .. " favorite."
        )
        return
    end

    favorites[mountID] = nil

    print(
        "|cff00ff00Smart Favorite Mount:|r Removed "
        .. mountName
        .. " from "
        .. mountType
        .. " favorites."
    )
end


local function ToggleFavorite(mountType, mountID)
    if IsFavorite(mountType, mountID) then
        RemoveFavorite(mountType, mountID)
    else
        AddFavorite(mountType, mountID)
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
    local favorites
    local mountType

    if IsFlyableArea() then
        favorites = SmartFavoriteMountDB.flying
        mountType = "Flying"
    else
        favorites = SmartFavoriteMountDB.ground
        mountType = "Ground"
    end

    local mountID = GetRandomFavorite(favorites)

    if not mountID then
        print(
            "|cffff4444Smart Favorite Mount:|r No "
            .. mountType
            .. " favorites found."
        )
        return
    end

    local mountName = GetMountName(mountID) or "Unknown Mount"

    print(
        "|cff00ccffSmart Favorite Mount:|r "
        .. mountType
        .. " → "
        .. mountName
    )

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
        groundFavoriteButton:SetText("★ Ground")
    else
        groundFavoriteButton:SetText("☆ Ground")
    end

    if IsFavorite("flying", mountID) then
        flyingFavoriteButton:SetText("★ Flying")
    else
        flyingFavoriteButton:SetText("☆ Flying")
    end
end


local function CreateMountJournalButtons()
    if groundFavoriteButton then
        return
    end

    if not MountJournal then
        return
    end

    groundFavoriteButton = CreateFrame(
        "Button",
        nil,
        MountJournal,
        "UIPanelButtonTemplate"
    )

    groundFavoriteButton:SetSize(110, 24)
    groundFavoriteButton:SetText("☆ Ground")
    groundFavoriteButton:SetFrameStrata("DIALOG")
    groundFavoriteButton:SetFrameLevel(MountJournal:GetFrameLevel() + 20)

    groundFavoriteButton:SetPoint(
        "BOTTOM",
        MountJournal,
        "BOTTOM",
        -60,
        40
    )

    groundFavoriteButton:SetScript("OnClick", function()
        local mountID = MountJournal.selectedMountID

        if not mountID then
            return
        end

        ToggleFavorite("ground", mountID)
        UpdateMountJournalButtons()
    end)


    flyingFavoriteButton = CreateFrame(
        "Button",
        nil,
        MountJournal,
        "UIPanelButtonTemplate"
    )

    flyingFavoriteButton:SetSize(110, 24)
    flyingFavoriteButton:SetText("☆ Flying")
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

    UpdateMountJournalButtons()
end


local function SetupMountJournalHooks()
    if not MountJournal then
        return
    end

    CreateMountJournalButtons()

    if MountJournal_SetSelected then
        hooksecurefunc(
            "MountJournal_SetSelected",
            function()
                UpdateMountJournalButtons()
            end
        )
    end
end


-- =========================================================
-- Events
-- =========================================================

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "SmartFavoriteMount" then
        InitializeDatabase()

        print("|cff00ccffSmart Favorite Mount|r loaded!")
    end

    if addonName == "Blizzard_Collections" then
        SetupMountJournalHooks()
    end
end)


-- =========================================================
-- Main slash command
-- =========================================================

SLASH_SMARTFAVORITEMOUNT1 = "/sfm"

SlashCmdList["SMARTFAVORITEMOUNT"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")

    command = string.lower(command or "")

    if command == "" then
        SummonSmartFavorite()
        return
    end

    if command == "add" then
        local mountType, mountName = rest:match("^(%S+)%s+(.+)$")

        if not mountType or not mountName then
            print("|cffffcc00Usage:|r /sfm add ground <mount name>")
            print("|cffffcc00Usage:|r /sfm add flying <mount name>")
            return
        end

        mountType = string.lower(mountType)

        if mountType ~= "ground" and mountType ~= "flying" then
            print(
                "|cffff4444Smart Favorite Mount:|r "
                .. "Type must be ground or flying."
            )
            return
        end

        local mountID = FindMountByName(mountName)

        if not mountID then
            print(
                "|cffff4444Smart Favorite Mount:|r Mount not found: "
                .. mountName
            )
            return
        end

        AddFavorite(mountType, mountID)
        return
    end

    if command == "remove" then
        local mountType, mountName = rest:match("^(%S+)%s+(.+)$")

        if not mountType or not mountName then
            print("|cffffcc00Usage:|r /sfm remove ground <mount name>")
            print("|cffffcc00Usage:|r /sfm remove flying <mount name>")
            return
        end

        mountType = string.lower(mountType)

        if mountType ~= "ground" and mountType ~= "flying" then
            print(
                "|cffff4444Smart Favorite Mount:|r "
                .. "Type must be ground or flying."
            )
            return
        end

        local mountID = FindMountByName(mountName)

        if not mountID then
            print(
                "|cffff4444Smart Favorite Mount:|r Mount not found: "
                .. mountName
            )
            return
        end

        RemoveFavorite(mountType, mountID)
        return
    end

    if command == "list" then
        ListFavorites()
        return
    end

    print("|cffffcc00Smart Favorite Mount commands:|r")
    print("/sfm")
    print("/sfm add ground <mount>")
    print("/sfm add flying <mount>")
    print("/sfm remove ground <mount>")
    print("/sfm remove flying <mount>")
    print("/sfm list")
end


-- =========================================================
-- Debug commands
-- =========================================================

SLASH_SFMFLY1 = "/sfmfly"

SlashCmdList["SFMFLY"] = function()
    if IsFlyableArea() then
        print(
            "|cff00ff00Smart Favorite Mount:|r "
            .. "This area IS flyable."
        )
    else
        print(
            "|cffff4444Smart Favorite Mount:|r "
            .. "This area is NOT flyable."
        )
    end
end


SLASH_SFMINFO1 = "/sfminfo"

SlashCmdList["SFMINFO"] = function(msg)
    local mountID = FindMountByName(msg)

    if not mountID then
        print(
            "|cffff4444Smart Favorite Mount:|r Mount not found: "
            .. msg
        )
        return
    end

    local name = C_MountJournal.GetMountInfoByID(mountID)

    local creatureDisplayID,
          description,
          source,
          isSelfMount,
          mountTypeID =
        C_MountJournal.GetMountInfoExtraByID(mountID)

    print("|cff00ccffSmart Favorite Mount Debug|r")
    print("Name: " .. tostring(name))
    print("Mount ID: " .. tostring(mountID))
    print("Mount Type ID: " .. tostring(mountTypeID))
end