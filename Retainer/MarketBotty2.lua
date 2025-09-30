--[=====[
[[SND Metadata]]
author:  'Lis'
version: 1.0.3
description: >-
  MarketBotty v2
  Do not ask about this script in Discord servers or support chats. Use at your own risk.
plugin_dependencies:
- vnavmesh
configs:
  UndercutValue:
    default: 1
    description: How much you undercut
  PriceSanityChecking:
    default: true
    description: Ignores market results below half the trimmed mean
  HistoryTrimAmount:
    default: 5
    description: Trims this many from highest and lowest in history list
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
  Debug:
    default: false
    description: Enable debug logging
[[End Metadata]]
--]=====]

my_characters = {
    'Lisera Mistica@Shiva',
    'Character Name@Server',
}

my_retainers = {
    'Lisiantus',
    'Aroleca',
    'Marilynn',
    'Haaselia',
    'Aimer',
    'Yorushika',
}

item_overrides = {
    StuffedAlpha = { maximum = 450 },
    StuffedBomBoko = { minimum = 450 },
    Coke = { minimum = 450, maximum = 5000 },
    RamieTabard = { default = 25000 },
}

undercut = Config.Get("UndercutValue")
history_trim_amount = Config.Get("HistoryTrimAmount")
is_price_sanity_checking = Config.Get("PriceSanityChecking")
UseAutoRetainer = Config.Get("UseAutoRetainer")
is_looping = Config.Get("IsLooping")
loop_time = Config.Get("LoopTime")
name_rechecks = Config.Get("NameRechecks")
is_debug = Config.Get("Debug")
config_folder = os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\"
marketbotty_settings = "marketbotty_settings.lua"
retainers_file = "my_retainers.txt"
au = 1
override_items_count = 0
override_report = {}
one_gil_items_count = 0
one_gil_report = {}
sanity_items_count = 0
sanity_report = {}

function EnterHouse()
    zoneID = Svc.ClientState.TerritoryType
    if zoneID == 339 or zoneID == 340 or zoneID == 341 or zoneID == 641 or zoneID == 979 or zoneID == 136 then
        echo("Entering House")
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
        while not Addons.GetAddon("RetainerList").Ready do
            yield("/wait 0.100")
        end
        yield("/wait 0.4")
        return true
    else
        return false
    end
end

function SomethingBroke(what_should_be_visible, extra_info)
    for _ = 1, 20 do
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
    if not Addons.GetAddon("RetainerList").Ready then
        SomethingBroke("RetainerList", "CountRetainers()")
    end

    while string.gsub(Addons.GetAddon("RetainerList"):GetNode(1, 27, 4, 2, 3).Text, "%d", "") == "" do
        yield("/wait 0.1")
    end

    yield("/wait 0.1")
    total_retainers = 0
    retainers_to_run = {}
    yield("/wait 0.1")

    CountRetainersLoop(4)

    for id = 41001, 41009 do
        CountRetainersLoop(id)
    end

    return total_retainers
end

function CountRetainersLoop(id)
    yield("/wait 0.01")
    include_retainer = true

    retainer_name = Addons.GetAddon("RetainerList"):GetNode(1, 27, id, 2, 3).Text
    if retainer_name ~= "" then
        if Addons.GetAddon("RetainerList"):GetNode(1, 27, id, 2, 11).Text == "None" then
            include_retainer = false
        end

        if include_retainer then
            if id == 4 then
                pos = 0
            else
                pos = (id - 41000)
            end

            total_retainers = total_retainers + 1
            retainers_to_run[total_retainers] = pos
        end

        if type(file_retainers) == "userdata" then
            is_add_to_file = true
            for _, known_retainer in pairs(my_retainers) do
                if retainer_name == known_retainer then
                    is_add_to_file = false
                    break
                end
            end

            if is_add_to_file then
                file_retainers = io.open(config_folder .. retainers_file, "a")
                file_retainers:write("\n" .. retainer_name)
                io.close(file_retainers)
            end
        end
    end
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
        count_wait_tick = count_wait_tick + 1
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
    local addon
    local update
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

    echo("Search results: " .. search_results)

    return search_results
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
    if market_search_retainers ~= "" then -- TODO check Node 5, 1, 5
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
            if search_retainers[i] and search_retainers ~= "" then
                Dalamud.Log("Search Retainers: " .. search_retainers[i])
            end
        end
    end
end

function HistoryAverage()
    while (Addons.GetAddon("ItemHistory").Ready == false) do
        SafeCallback("ItemSearchResult", true, 0)
        yield("/wait 0.3")
    end

    yield("/waitaddon ItemHistory")
    history_tm_count = 0
    history_tm_running = 0
    history_list = {}
    first_history = string.gsub(Addons.GetAddon("ItemHistory"):GetNode(1, 10, 4, 4).Text, "%D", "")

    echo("First history entry: " .. first_history)

    while first_history == "" do
        yield("/wait 0.1")
        first_history = string.gsub(Addons.GetAddon("ItemHistory"):GetNode(1, 10, 4, 4).Text, "%D", "")
    end

    yield("/wait 0.1")

    local i  = 2
    for id = 41001, 41019 do
        raw_history_price = Addons.GetAddon("ItemHistory"):GetNode(1, 10, id, 4).Text
        echo("History entry " .. (i - 1) .. ": " .. raw_history_price)
        if raw_history_price ~= "" then
            trimmed_history_price = string.gsub(raw_history_price, "%D", "")
            history_list[i - 1] = tonumber(trimmed_history_price)
            history_tm_count = history_tm_count + 1
        end
        i = i + 1
    end

    Dalamud.Log("History count: " .. history_tm_count)
    table.sort(history_list)

    for _ = 1, history_trim_amount do
        if history_tm_count > 2 then
            table.remove(history_list, history_tm_count)
            table.remove (history_list, 1)
            history_tm_count = history_tm_count - 2
        else
            break
        end
    end

    for _, history_tm_price in pairs(history_list) do
        history_tm_running = history_tm_running + history_tm_price
    end

    history_trimmed_mean = history_tm_running // history_tm_count
    Dalamud.Log("History trimmed mean: " .. history_trimmed_mean)

    return history_trimmed_mean
end

function ItemOverride(mode)
    itemor = nil
    is_price_overridden = false
    for item_test, _ in pairs(item_overrides) do
        if open_item == string.gsub(item_test,"%W","") then
            itemor = item_overrides[item_test]
            break
        end
    end
    if not itemor then
        return false
    end
    if itemor.default and mode == "default" then
        price = tonumber(itemor.default)
        is_price_overridden = true
        Dalamud.Log(open_item.." default price: "..itemor.default.." applied!")
    end
    if itemor.minimum then
        if price < itemor.minimum then
            price = tonumber(itemor.minimum)
            is_price_overridden = true
            Dalamud.Log(open_item.." minimum price: "..itemor.minimum.." applied!")
        end
    end
    if itemor.maximum then
        if price > itemor.maximum then
            price = tonumber(itemor.maximum)
            is_price_overridden = true
            Dalamud.Log(open_item.." maximum price: "..itemor.maximum.." applied!")
        end
    end
end

function SetPrice(price)
    Dalamud.Log("Setting price to: ".. price)
    CloseSearch()
    SafeCallback("RetainerSell", true, 2, price)
    SafeCallback("RetainerSell", true, 0)
    CloseSales()
end

function CloseSearch()
    while Addons.GetAddon("ItemSearchResult").Ready or Addons.GetAddon("ItemHistory").Ready do
        yield("/wait 0.1")
        if Addons.GetAddon("ItemSearchResult").Ready then
            SafeCallback("ItemSearchResult", true, -1)
        end
        if Addons.GetAddon("ItemHistory").Ready then
            SafeCallback("ItemHistory", true, -1)
        end
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

function WaitARFinish(ar_time)
    title_wait = 0
    if not ar_time then
        ar_time = 15
    end

    while Addons.GetAddon("_TitleMenu").Ready == false do
        yield("/wait 5.01")
    end

    while true do
        if Addons.GetAddon("_TitleMenu").Ready and Addons.GetAddon("NowLoading").Ready == false then
            title_wait = title_wait + 1
        else
            title_wait = 0
        end

        if title_wait > ar_time then
            break
        end
        yield("/wait 1.0" .. ar_time - title_wait)
    end
end

function echo(input)
    if is_debug then
        yield("/echo [MarketBotty] " .. input)
    else
        yield("/wait 0.01")
    end
end

function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function readFiles()
    if file_exists(config_folder..marketbotty_settings) then
        chunk = loadfile(config_folder..marketbotty_settings)
        chunk()
    end

    file_retainers = config_folder..retainers_file
    if file_exists(file_retainers) then
        my_retainers = {}
        file_retainers = io.input(file_retainers)
        next_line = file_retainers:read("l")
        i = 0
        while next_line do
            i = i + 1
            my_retainers[i] = next_line
            Dalamud.Log("Retainer " ..i.." from file: "..next_line)
            next_line = file_retainers:read("l")
        end
        file_retainers:close()
        echo("Retainers loaded from file: "..i)
    else
        echo(file_retainers.." not found!")
    end

    one_gil_items_count = 0
    one_gil_report = {}
    sanity_items_count = 0
    sanity_report = 0

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

::Startup::
Clear()
while IPC.AutoRetainer.IsBusy() do
    yield("/wait 1.0")
end
IPC.AutoRetainer.SetSuppressed(true)
if Svc.Condition[50] == false then
    echo("Not at a summoning bell.")
    OpenBell()
    goto Startup
elseif Addons.GetAddon("RetainerList").Ready then
    CountRetainers()
    goto NextRetainer
elseif Addons.GetAddon("RetainerSell").Ready then
    echo("Starting in single item mode!")
    is_single_item_mode = true
    goto RepeatItem
elseif Addons.GetAddon("SelectString").Ready then
    echo("Starting in single retainer mode!")
    SafeCallback("SelectString", true, 2)
    yield("/waitaddon RetainerSellList")
    is_single_retainer_mode = true
    goto Sales
elseif Addons.GetAddon("RetainerSellList").Ready then
    echo("Starting in single retainer mode!")
    is_single_retainer_mode = true
    goto Sales
else
    echo("Unexpected starting conditions!")
    echo("You broke it. It's your fault.")
    echo("Do not message me asking for help.")
    yield("/pcraft stop")
end

::NextRetainer::
if next_retainer < total_retainers then
    next_retainer = next_retainer + 1
else
    if is_looping then
        IPC.AutoRetainer.SetSuppressed(false)
        yield("/wait " .. loop_time)
        goto Startup
    else
        goto EndOfScript
    end
end
yield("/wait 0.1")
target_sale_slot = 1
OpenRetainer(retainers_to_run[next_retainer])

:: Sales ::
if CountItems() == 0 then
    goto Loop
end

:: NextItem ::
ClickItem(target_sale_slot)

:: Helper ::
au = undercut
while Addons.GetAddon("RetainerSell").Ready == false do
    yield("/wait 0.5")
    if Svc.Condition[50] == false or Addons.GetAddon("RecommendList").Ready then
        goto EndOfScript
    end
end

:: RepeatItem ::
ReadOpenItem()
if last_item ~= "" then
    if open_item == last_item then
        echo("Repeat: " .. open_item .. " set to " .. price)
        goto Apply
    end
end

:: ReadPrices ::
SearchResults()
current_price = string.gsub(Addons.GetAddon("RetainerSell"):GetNode(1, 17, 19).Text, "%D", "")
if Addons.GetAddon("ItemSearchResult"):GetNode(1, 5).IsVisible and string.find(Addons.GetAddon("ItemSearchResult"):GetNode(1, 5).Text, "No items found") then
    price_length = string.len(tostring(HistoryAverage()))
    price = math.tointeger(10 ^ price_length)
    CloseSearch()
    ItemOverride("default")
    goto Apply
end
target_price = 1
SearchPrices()
SearchRetainers()
HistoryAverage()
CloseSearch()

:: PricingLogic ::
if target_price < prices_list_length then
    if prices_list[target_price] == 1 then
        target_price = target_price + 1
        goto PricingLogic
    end

    if prices_list[target_price] <= (history_trimmed_mean // 2) then
        target_price = target_price + 1
        goto PricingLogic
    end

    Dalamud.Log("Price sanity checking results:")
    Dalamud.Log("target_price " .. target_price)
    Dalamud.Log("prices_list[target_price] " .. prices_list[target_price])
end

for _, retainer_test in pairs(my_retainers) do
    if retainer_test == search_retainers[target_price] then
        au = 0
        Dalamud.Log("Matching price with own retainer: " .. retainer_test)
        break
    end
end
price = prices_list[target_price] - au
ItemOverride()
if is_price_overridden then
    override_items_count = override_items_count + 1
    override_report[override_items_count] = open_item .. " set: " .. price .. ". Low: " .. prices_list[1]
elseif price <= 1 then
    echo("Should probably vendor this crap instead of setting it to 1. Since this script isn't *that* good yet, I'm just going to set it to...69. That's a nice number. You can deal with it yourself.")
    price = 69
    one_gil_items_count = one_gil_items_count + 1
    one_gil_report[one_gil_items_count] = open_item
elseif target_price ~=1 then
    sanity_items_count = sanity_items_count + 1
    sanity_report[sanity_items_count] = open_item .. " set: " .. price .. ". Low: " .. prices_list[1]
end

:: Apply ::
if price ~= tonumber(string.gsub(Addons.GetAddon("RetainerSell"):GetNode(1, 17, 19).Text, "%D", "")) then
    SetPrice(price)
end
CloseSales()

:: Loop ::
if helper_mode then
    yield("/wait 1")
    goto Helper
elseif is_single_item_mode then
    yield("/pcraft stop")
elseif not (tonumber(item_count) <= target_sale_slot) then
    target_sale_slot = target_sale_slot + 1
    goto NextItem
elseif is_single_retainer_mode then
    goto EndOfScript
elseif is_single_retainer_mode == false then
    CloseRetainer()
    goto NextRetainer
end

:: EndOfScript ::
while (Addons.GetAddon("RecommendList").Ready) do
    SafeCallback("RecommendList", true, -1)
    yield("/wait 0.1")
end
echo("---------------------")
echo("MarketBotty finished!")
echo("---------------------")
if override_items_count ~= 0 then
    echo("Items that triggered override: " .. override_items_count)
    for i = 1, override_items_count do
        echo(override_report[i])
    end
    echo("---------------------")
end
if one_gil_items_count ~= 0 then
    echo("Items that triggered 1 gil check: " .. one_gil_items_count)
    for i = 1, one_gil_items_count do
        echo(one_gil_report[i])
    end
    echo("---------------------")
end
if sanity_items_count ~= 0 then
    echo("Items that triggered sanity check: " .. sanity_items_count)
    for i = 1, sanity_items_count do
        echo(sanity_report[i])
    end
    echo("---------------------")
end
yield("/pcraft stop")
yield("/pcraft stop")
yield("/pcraft stop")