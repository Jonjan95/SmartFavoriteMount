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

local function GetRandomFavorite(favorites)
    if #favorites == 0 then
        return nil
    end

    local randomIndex = math.random(#favorites)

    return favorites[randomIndex]
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
end

local function AddFavorite(mountType, mountName)
    local favorites = SmartFavoriteMountDB[mountType]

    if not favorites then
        print("|cffff4444Smart Favorite Mount:|r Invalid mount type.")
        return
    end

    local mountID = FindMountByName(mountName)

    if not mountID then
        print("|cffff4444Smart Favorite Mount:|r Mount not found: " .. mountName)
        return
    end

    for _, existingMount in ipairs(favorites) do
        if string.lower(existingMount) == string.lower(mountName) then
            print(
                "|cffffcc00Smart Favorite Mount:|r "
                .. mountName
                .. " is already a favorite."
            )
            return
        end
    end

    table.insert(favorites, mountName)

    print(
        "|cff00ff00Smart Favorite Mount:|r Added "
        .. mountName
        .. " as "
        .. mountType
        .. "."
    )
end

local function RemoveFavorite(mountType, mountName)
    local favorites = SmartFavoriteMountDB[mountType]

    if not favorites then
        print("|cffff4444Smart Favorite Mount:|r Invalid mount type.")
        return
    end

    for index, existingMount in ipairs(favorites) do
        if string.lower(existingMount) == string.lower(mountName) then
            table.remove(favorites, index)

            print(
                "|cff00ff00Smart Favorite Mount:|r Removed "
                .. mountName
                .. " from "
                .. mountType
                .. " favorites."
            )

            return
        end
    end

    print(
        "|cffff4444Smart Favorite Mount:|r Favorite not found: "
        .. mountName
    )
end

local function ListFavorites()
    print("|cff00ccffSmart Favorite Mount Favorites|r")

    print("|cffffcc00Ground:|r")

    if #SmartFavoriteMountDB.ground == 0 then
        print("  None")
    else
        for _, mountName in ipairs(SmartFavoriteMountDB.ground) do
            print("  - " .. mountName)
        end
    end

    print("|cff66ccffFlying:|r")

    if #SmartFavoriteMountDB.flying == 0 then
        print("  None")
    else
        for _, mountName in ipairs(SmartFavoriteMountDB.flying) do
            print("  - " .. mountName)
        end
    end
end

local function SummonSmartFavorite()
    local favorites
    local mountType

    if IsFlyableArea() then
        favorites = SmartFavoriteMountDB.flying
        mountType = "Flying"
    else
        favorites = SmartFavoriteMountDB.ground
        mountType = "Ground"
    end

    local selectedMount = GetRandomFavorite(favorites)

    if not selectedMount then
        print(
            "|cffff4444Smart Favorite Mount:|r No "
            .. mountType
            .. " favorites found."
        )
        return
    end

    local mountID = FindMountByName(selectedMount)

    if not mountID then
        print(
            "|cffff4444Smart Favorite Mount:|r Mount not found: "
            .. selectedMount
        )
        return
    end

    print(
        "|cff00ccffSmart Favorite Mount:|r "
        .. mountType
        .. " → "
        .. selectedMount
    )

    C_MountJournal.SummonByID(mountID)
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "SmartFavoriteMount" then
        InitializeDatabase()

        print("|cff00ccffSmart Favorite Mount|r loaded!")

        self:UnregisterEvent("ADDON_LOADED")
    end
end)

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
                "|cffff4444Smart Favorite Mount:|r Type must be ground or flying."
            )
            return
        end

        AddFavorite(mountType, mountName)
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
                "|cffff4444Smart Favorite Mount:|r Type must be ground or flying."
            )
            return
        end

        RemoveFavorite(mountType, mountName)
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

SLASH_SFMFLY1 = "/sfmfly"

SlashCmdList["SFMFLY"] = function()
    local isFlyable = IsFlyableArea()

    if isFlyable then
        print("|cff00ff00Smart Favorite Mount:|r This area IS flyable.")
    else
        print("|cffff4444Smart Favorite Mount:|r This area is NOT flyable.")
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
          mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)

    print("|cff00ccffSmart Favorite Mount Debug|r")
    print("Name: " .. tostring(name))
    print("Mount ID: " .. tostring(mountID))
    print("Mount Type ID: " .. tostring(mountTypeID))
end