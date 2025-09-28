--[=====[
[[SND Metadata]]
author:  'Lis'
version: 0.0.1
description: |
  MarketBotty v2
  DO NOT USE YET, INCOMPLETE
  DO NOT ask for help with this script in Discord or any chats
  Use at your own risk
plugin_dependencies:
- vnavmesh
configs:
  Retainers:
    description: Enter your retainer names
    is_choice: false
    choices: []
  UndercutValue:
    default: 1
    description: How much you undercut
  PriceSanityChecking:
    default: false
    description: Ignores market results below half the trimmed mean
  HistoryTrimAmount:
    default: 5
    description: Trims this many from highest and lowest in history list
  HistoryMultiplier:
    default: round
    description: If not active sales then get average historical price and multiply
  UseAutoRetainer:
    default: true
    description: Use AutoRetainer to enter House
  IsLooping:
    default: true
    description: Loop da Hoop
  LoopTime:
    default: 600
    description: How long until next loop starts
  NameRechecks:
    default: 10
    description: Latency sensitive tunable. Probably sets wrong price if below 5
[[End Metadata]]
--]=====]

UseAutoRetainer = Config.Get("UseAutoRetainer")
Retainers = Config.Get("Retainers")
myRetainers = {}
name_rechecks = Config.Get("NameRechecks")

for name in luanet.each(Retainers) do
    table.insert(myRetainers, name)
end

function EnterHouse()
    zoneID = Svc.ClientState.TerritoryType
    if zoneID == 339 or zoneID == 340 or zoneID == 341 or zoneID == 641 or zoneID == 979 or zoneID == 136 then
        Dalamud.Log("Entering House")
        if UseAutoRetainer then
            yield("/ays het")
        else
            yield("/target Entrance")
            yield("/target Apartment Building Entrance")
        end
        yield("/wait 1")
        if string.find(string.lower(Entity.Target.Name), "entrance") then
            while zoneID == 339 or zoneID == 340 or zoneID == 341 or zoneID == 641 or zoneID == 979 or zoneID == 136 do
                if not UseAutoRetainer then
                    yield("/lockon on")
                    yield("/automove on")
                end
                yield("/wait 1.2")
                zoneID = Svc.ClientState.TerritoryType
            end
            het_tick = 0
            while het_tick < 3 do
                if Player.IsBusy then het_tick = 0
                elseif Player.IsMoving then het_tick = 0
                else het_tick = het_tick + 0.2
                end
                yield("/wait 0.200")
            end
        else
            Dalamud.Log("Not entering house?")
        end
    end
end

function OpenBell()
    EnterHouse()
    target_tick = 1
    while not Svc.Condition[50] do
	    yield("/target Summoning Bell")
		yield("/wait 0.2")
        if target_tick > 99 then
            break
        elseif string.lower(Entity.Target.Name)~="summoning bell" then
            Dalamud.Log("Finding summoning bell...")
            yield("/target Summoning Bell")
            target_tick = target_tick + 1
        elseif Entity.Target.DistanceTo < 20 then
           yield("/lockon on")
           yield("/automove on")
           yield("/pinteract")
        else
           yield("/automove off")
           yield("/pinteract")
        end
        yield("/lockon on")
        yield("/wait 0.511")
    end
    if Svc.Condition[50] then
        yield("/lockon off")
        while not IsAddonVisible("RetainerList") do yield("/wait 0.100") end
        yield("/wait 0.4")
        return true
    else
        return false
    end
end

function SomethingBroke(what_should_be_visible, extra_info)
    for broken_rechecks = 1, 20 do
        if Addons.GetAddon(what_should_be_visible).Ready then
            still_broken = false
            break
        else
            yield("/wait 0.1")
        end
    end
    if still_broken then
        yield("/echo It looks like something has gone wrong.")
        if what_should_be_visible then
            yield("/echo " .. what_should_be_visible .. " should be visible, but it isn't.")
        end
        yield("/echo Attempting to fix this, please wait.")
        if extra_info then
            yield("/echo " .. extra_info)
        end
        yield("/echo On second thought, I haven't finished this yet.")
        yield("/echo Oops!")
        yield("/pcraft stop")
    end
end

function CountRetainers()
    myRetainers = {}
    for name in luanet.each(Retainers) do
        table.insert(myRetainers, name)
    end

    return #myRetainers
end

function OpenRetainer(retainerIndex)
    yield("/waitaddon RetainerList")
    yield("/wait 0.3")
    yield("/click RetainerList Retainers["..retainerIndex.."].Select")
    yield("/wait 0.5")
    yield("/waitaddon SelectString")
    yield("/wait 0.3")
    yield("/click SelectString Entries[3].Select")
    yield("/waitaddon RetainerSellList")
end

function CloseRetainer()
    while not (Addons.GetAddon("RetainerList") and Addons.GetAddon("RetainerList").Ready) do
        if Addons.GetAddon("RetainerSellList") and Addons.GetAddon("RetainerSellList").Ready then
            yield("/callback RetainerSellList true -1")
        end
        if Addons.GetAddon("SelectString") and Addons.GetAddon("SelectString").Ready then
            yield("/callback SelectString true -1")
        end
        if Addons.GetAddon("Talk") and Addons.GetAddon("Talk").Ready then
            yield("/click Talk Click")
        end
        yield("/wait 0.1")
    end
end

function CountItems()
    yield("/waitaddon RetainerSellList")

    while string.gsub(Addons.GetAddon("RetainerSellList"):GetNode(1, 14,19).Text, "%d", "") == "" do
        yield("/wait 0.1")
    end
    
    count_wait_tick = 0
    
    while Addons.GetAddon("RetainerSellList"):GetNode(1, 14,19).Text == raw_item_count and count_wait_tick < 5 do
        count_wait_ticket = count_wait_tick + 1
        yield("/wait 0.1")
    end
    
    yield("/wait 0.1")
    raw_item_count = Addons.GetAddon("RetainerSellList"):GetNode(1, 14,19).Text
    item_count_trimmed = string.sub(raw_item_count, 1, 2)
    item_count = string.gsub(item_count_trimmed, "%D", "")
    Dalamud.Log("Items for sale on this retainer: "..item_count)
    return item_count
end

function ClickItem(item)
    CloseSales()
    while Addons.GetAddon("RetainerSell").Ready == false do
        if Addons.GetAddon("ContextMenu").Ready then
            SafeCallback("ContextMenu", true, 0, 0)
            yield("/wait 0.2")
        elseif Addons.GetAddon("RetainerSellList").Ready then
            SafeCallback("RetainerSellList", true, 0, item - 1, 1)
        else
            SomethingBroke("RetainerSellList", "ClickItem()")
        end
        yield("/wait 0.05")
    end
end

function ReadOpenItem()
    last_item = open_item
    open_item = ""
    item_name_checks = 0
    while item_name_checks < name_rechecks and (open_item == last_item or open_item == "") do
        item_name_checks = item_name_checks + 1
        yield("/wait 0.1")
        open_item = string.gsub(Addons.GetAddon("RetainerSell"):GetNode(1, 5, 7).Text, "%W", "")
    end
end

function CloseSales()
    CloseSearch()
    while Addons.GetAddon("RetainerSell").Ready do
        yield("/wait 0.1")
        if Addons.GetAddon("RetainerSell").Ready then
            SafeCallback("RetainerSell", true, -1)
        end
    end
end

function SafeCallback(...)
    local callback_table = table.pack(...)
    local addon = nil
    local update = nil
    if type(callback_table[1])=="string" then
        addon = callback_table[1]
        table.remove(callback_table, 1)
    end
    if type(callback_table[1])=="boolean" then
        update = tostring(callback_table[1])
        table.remove(callback_table, 1)
    elseif type(callback_table[1])=="string" then
        if string.find(callback_table[1], "t") then
            update = "true"
        elseif string.find(callback_table[1], "f") then
            update = "false"
        end
        table.remove(callback_table, 1)
    end

    local call_command = "/pcall " .. addon .. " " .. update
    for _, value in pairs(callback_table) do
        if type(value)=="number" then
            call_command = call_command .. " " .. tostring(value)
        end
    end
    if Addons.GetAddon(addon).Ready then
        yield(call_command)
    end
end

function CloseSearch()
    while Addons.GetAddon("ItemSearchResult").Ready do
        yield("/wait 0.1")
        if Addons.GetAddon("ItemSearchResult").Ready then
            SafeCallback("ItemSearchResult", true, -1)
        end
        if Addons.GetAddon("ItemHistory").Ready then
            SafeCallback("ItemHistory", true, -1)
        end
    end
end

function SearchResults()
    if Addons.GetAddon("ItemSearchResult").Ready == false then
        yield("/wait 0.1")
        if Addons.GetAddon("ItemSearchResult").Ready == false then
            SafeCallback("RetainerSell", true, 4)
        end
    end
    yield("/waitaddon ItemSearchResult")
    if Addons.GetAddon("ItemHistory").Ready == false then
        yield("/wait 0.1")
        if Addons.GetAddon("ItemHistory").Ready == false then
            SafeCallback("ItemSearchResult", true, 0)
        end
    end

    yield("/wait 0.1")
    ready = false
    search_hits = ""
    search_wait_tick = 10
    while ready == false do
        search_hits = Addons.GetAddon("ItemSearchResult"):GetNode(1, 29).Text
        first_price = string.gsub(Addons.GetAddon("ItemSearchResult"):GetNode(1, 26, 4, 5).Text, "%D", "")
        if search_wait_tick > 20 and Addons.GetAddon("ItemSearchResult"):GetNode(1, 5).IsVisible and string.find(Addons.GetAddon("ItemSearchResult"):GetNode(1, 5).Text, "No items found") then
            ready = true
            Dalamud.Log("No items found")
        end
        if (string.find(search_hits, "hit") and first_price ~= "") and (old_first_price ~= first_price or search_wait_tick > 20) then
            ready = true
            Dalamud.Log("Ready!")
        else
            search_wait_tick = search_wait_tick + 1
            if (search_wait_tick > 50) or (string.find(Addons.GetAddon("ItemSearchResult"):GetNode(1, 5).Text, "Please wait") and search_wait_tick > 10) then
                SafeCallback("RetainerSell", true, 4)
                yield("/wait 0.1")
                if Addons.GetAddon("ItemHistory").Ready == false then
                    SafeCallback("ItemSearchResult", true, 0)
                end
                yield("/wait 0.1")
                search_wait_tick = 0
            end
        end
        yield("/wait 0.1")
    end

    old_first_price = first_price
    search_results = string.gsub(Addons.GetAddon("ItemSearchResult"):GetNode(1, 29).Text, "%D", "")
    Dalamud.Log("Search results: "..search_results)

    yield("/echo Search results: " .. search_results)

    -- #TODO remove comment to enable using search results
    -- return search_results
end

function SearchPrices()
    yield("/waitaddon ItemSearchResult")
    prices_list = {}
    prices_list_length = 0

    raw_price = Addons.GetAddon("ItemSearchResult"):GetNode(1, 26, 4, 5).Text
    if raw_price ~= "" then
        trimmed_price = string.gsub(raw_price, "%D", "")
        prices_list[1] = tonumber(trimmed_price)
    end

    for i = 41001, 41009 do
        raw_price = Addons.GetAddon("ItemSearchResult"):GetNode(1,26, i, 5).Text
        if raw_price ~= "" then
            trimmed_price = string.gsub(raw_price, "%D", "")
            pos = (i - 41000) + 1
            prices_list[pos] = tonumber(trimmed_price)
        end
    end

    Dalamud.Log(open_item .. " Prices")

    for price_number, _ in pairs(prices_list) do
        Dalamud.Log(prices_list[price_number])
        prices_list_length = prices_list_length + 1
    end
end

function SearchRetainers()
    search_retainers = {}
    market_search_retainers = Addons.GetAddon("ItemSearchResult"):GetNode(1, 26, 4, 10).Text
    if market_search_retainers ~= "" then
        search_retainers[1] = market_search_retainers
    end

    for i = 41001, 41009 do
        market_search_retainers = Addons.GetAddon("ItemSearchResult"):GetNode(1, 26, i, 10).Text
        if market_search_retainers ~= "" then
            pos = (i - 41000) + 1
            search_retainers[pos] = market_search_retainers
        end
    end

    for i = 1, 10 do
        if search_retainers[1] then
            Dalamud.Log("Search Retainers: " .. search_retainers[i])
        end
    end
end

function HistoryAverage()
    first_history = string.gsub(Addons.GetAddon("ItemHistory"):GetNode(1, 10, 4, 4).Text, "%D", "")
end

function Clear()
    next_retainer = 0
    prices_list = {}
    item_list = {}
    item_count = 0
    search_retainers = {}
    last_item = ""
    open_item = ""
    is_single_retainer_mode = false
    undercut = 1
    target_sale_slot = 1
end

Clear()
ClickItem(1)
ReadOpenItem()
SearchResults()
SearchPrices()
SearchRetainers()