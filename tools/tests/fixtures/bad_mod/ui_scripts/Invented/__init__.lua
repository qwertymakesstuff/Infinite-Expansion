-- [lua] three invented API names; Engine.Fake() in this comment is fine
local function helper(menu)
    return string.lower("A")
end

local menu = LUI.UIElement.new()
Engine.Exec("set ix_test 1")
LUI.FlowManager.RequestAddMenu("ModSelectMenu", true, 0, false)
helper(menu)
local text = "Engine.Fake2( inside a string is fine"
Engine.SetPlayerData("cp", 1)
menu:SetMagicColor(1)
MakeMagicHappen()
