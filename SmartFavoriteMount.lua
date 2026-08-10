print("|cff00ccffSmart Favorite Mount|r loaded!")

SLASH_SMARTFAVORITEMOUNT1 = "/sfm"

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

local groundFavorites = {
    "Raven Lord",
    "Swift Spectral Tiger",
}

local flyingFavorites = {
    "Invincible",
    "Cindertuft Groveglider",
}

SlashCmdList["SMARTFAVORITEMOUNT"] = function()
    local favorites
    local mountType

    if IsFlyableArea() then
        favorites = flyingFavorites
        mountType = "Flying"
    else
        favorites = groundFavorites
        mountType = "Ground"
    end

    local selectedMount = GetRandomFavorite(favorites)

    if not selectedMount then
        print("|cffff4444Smart Favorite Mount:|r No " .. mountType .. " favorites found.")
        return
    end

    local mountID = FindMountByName(selectedMount)

    if not mountID then
        print("|cffff4444Smart Favorite Mount:|r Mount not found: " .. selectedMount)
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
        print("|cffff4444Smart Favorite Mount:|r Mount not found: " .. msg)
        return
    end

    local name = C_MountJournal.GetMountInfoByID(mountID)

    local creatureDisplayID, description, source, isSelfMount,
          mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)

    print("|cff00ccffSmart Favorite Mount Debug|r")
    print("Name: " .. tostring(name))
    print("Mount ID: " .. tostring(mountID))
    print("Mount Type ID: " .. tostring(mountTypeID))
end