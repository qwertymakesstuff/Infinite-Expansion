-- API names that iw7-mod's own ui_scripts use
if not Engine.InFrontend() then
    return
end

local function label(text)
    return ToUpperCase(text)
end

local button = MenuBuilder.BuildRegisteredType("MenuButton", { controllerIndex = 0 })
button.Text:setText(label("Example"), 0)
button:addEventHandler("button_action", function(element, eventArgs)
    LUI.FlowManager.RequestAddMenu("ModSelectMenu", true, eventArgs.controller, false)
end)
