--!nonstrict

local Theme = {}

function Theme.color(name, modifier)
	return settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor[name], modifier or Enum.StudioStyleGuideModifier.Default)
end

function Theme.paint(object)
	local role = object:GetAttribute("VBRole")
	if not role then return end
	if role == "surface" then
		object.BackgroundColor3 = Theme.color("MainBackground")
	elseif role == "line" then
		object.BackgroundColor3 = Theme.color("Border")
	elseif role == "border" then
		object.Color = Theme.color("Border")
	elseif role == "text" or role == "muted" or role == "error" then
		object.TextColor3 = Theme.color(if role == "error" then "ErrorText" else if role == "muted" then "DimmedText" else "MainText")
	elseif role == "input" then
		object.BackgroundColor3 = Theme.color("InputFieldBackground")
		object.TextColor3 = Theme.color("MainText")
		object.PlaceholderColor3 = Theme.color("DimmedText")
	elseif role == "image" then
		object.BackgroundColor3 = Theme.color("InputFieldBackground")
	elseif role == "button" then
		local modifier = if not object.Active then Enum.StudioStyleGuideModifier.Disabled
			elseif object:GetAttribute("Pressed") then Enum.StudioStyleGuideModifier.Pressed
			elseif object:GetAttribute("Hover") then Enum.StudioStyleGuideModifier.Hover
			else Enum.StudioStyleGuideModifier.Default
		local primary = object:GetAttribute("Primary") or object:GetAttribute("Selected")
		object.BackgroundColor3 = Theme.color(if primary then "DialogMainButton" else "Button", modifier)
		object.TextColor3 = Theme.color(if primary then "DialogMainButtonText" else "ButtonText", modifier)
	end
end

function Theme.apply(root)
	Theme.paint(root)
	for _, child in root:GetDescendants() do Theme.paint(child) end
end

return Theme
