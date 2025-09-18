--[=====[
[[SND Metadata]]
author:  'Lis'
version: 1.0.0
description: Spearfish Auto Desynth
plugin_dependencies:
- AutoHook
- visland
- vnavmesh
configs:
  RepairAmount:
    default: 50
    description: When do you want to repair your own gear?
    min: 0
    max: 100
  RouteName:
    default: Sungilt Aethersand
    description: Visland route name
  SlotsRemaining:
    default: 5
    description: How many remaining slots do you want have before it starts to desynth?
[[End Metadata]]
--]=====]

RepairAmount = Config.Get("RepairAmount")
RouteName = Config.Get("RouteName")
SlotsRemaining = Config.Get("SlotsRemaining")

FishingStart = 0
i_count = Inventory.GetFreeInventorySlots()

function NeedsRepair(pcct)
    repairList = Inventory.GetItemsInNeedOfRepairs(pcct)
    if repairList.Count == 0 then
        return false
    else
        return true
    end
end

function RepairMode()
    if NeedsRepair(RepairAmount) then
        yield("/generalaction repair")
        yield("/waitaddon Repair")
        yield("/pcall Repair true 0")
        yield("/wait 0.1")

        if Addons.GetAddon("SelectYesno") then
            yield("/pcall SelectYesno true 0")
            yield("/wait 0.1")
        end

        while Svc.Condition[39] do
            yield("/wait 1")
        end

        yield("/wait 1")
        yield("/pcall Repair true -1")
    end
end

function StartFish()
    if FishingStart == 0 then
        yield("/visland exec "..RouteName)
        yield("/visland resume")
        yield("/wait 1")
        FishingStart = FishingStart + 1
    end
end

function CheckInventory()
    while not (i_count <= SlotsRemaining) do
        yield("/wait 1")
        i_count = Inventory.GetFreeInventorySlots()
    end

    yield("/echo Inventory has reached "..i_count)
    yield("/echo Time to Desynth")
end

function GatherTest()
    while Svc.Condition[6] do
        yield("/visland pause")
        yield("/wait 5")
    end
end

function StartDesynth()
    while (not Svc.Condition[6]) and not (Svc.Condition[39]) do
        yield("/visland pause")
        yield("/wait 1")

        while Svc.Condition[27] do
            yield("/wait 1")
        end
        
        if Svc.Condition[4] then
            yield("/ac dismount")
            yield("/wait 3")
        end

        yield("/wait 0.5")

        if Addons.GetAddon("PurifyResult") then
            yield('/ac "Aetherial Reduction"')
            yield("/wait 4")
            yield("/echo Desynth all items in a row")
            break
        elseif (not Addons.GetAddon("PurifyResult")) and Addons.GetAddon("PurifyItemSelector") then
            yield("/pcall PurifyItemSelector true 12 0")
            yield("/wait 4")
            yield("/echo Selecting first item")
        elseif (not Addons.GetAddon("PurifyItemSelector")) and (not Svc.Condition[4]) then
            yield('/ac "Aetherial Reduction"')
            yield("/wait 0.5")
            yield("/echo Opening Desynth Menu")
        elseif Addons.GetAddon("PurifyItemSelector") and Svc.Condition[4] then
            yield("/pcall PurifyItemSelector True -1")
            yield("/wait 0.5")
            yield("/echo Desynth window was open while on mount")
        elseif Svc.Condition[4] then
            yield("/ac dismount")
            yield("/wait 3")
            yield("/echo Dismount Test")
        end
    end
end

function DesynthAll()
    yield("/echo start desynth")
    while Svc.Condition[39] do
        yield("/echo waiting...")
        yield("/wait 3")
    end
    
    while (not Svc.Condition[39]) and Addons.GetAddon("PurifyItemSelector") and not Addons.GetAddon("PurifyItemSelector"):GetNode(1, 7).IsVisible do
        -- Check if the PurifyResult is visible
        if Addons.GetAddon("PurifyResult") then
            yield("/callback PurifyItemSelector true 12")
            yield("/wait 4")

            -- Check if the PurifyItemSelector is visible but PurifyResult is not
        elseif not Addons.GetAddon("PurifyResult") and Addons.GetAddon("PurifyItemSelector") then
            yield("/callback PurifyItemSelector true 12 0")
            yield("/wait 4")

            -- Handle PurifyAutoDialog if it appears
        elseif Addons.GetAddon("PurifyAutoDialog") and
            Addons.GetAddon("PurifyAutoDialog"):GetNode(2, 2).Text == "Exit" then
            yield("/callback PurifyAutoDialog true 0")
        end
    end

    yield("/callback PurifyItemSelector true -1")
    yield("/visland resume")
end

while true do
    RepairMode()
    StartFish()
    CheckInventory()
    GatherTest()
    StartDesynth()
	DesynthAll()
end