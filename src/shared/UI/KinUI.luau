--!strict
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local camera = workspace.CurrentCamera
local playerGui: PlayerGui? = nil

pcall(function()
	if RunService:IsRunning() and Players.LocalPlayer then playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") end
end)

-- Detect if we're in a plugin / UILabs context
local function isUILabs(): boolean
	return (not RunService:IsRunning()) and RunService:IsEdit() and not Players.LocalPlayer
end

export type TextToken = "title" | "h1" | "h2" | "body" | "caption"
export type SizeBand = "S" | "M" | "L"

local KinUI = {}

function KinUI.GetPlayerGui(): PlayerGui?
	if playerGui and playerGui.Parent then return playerGui end
	if isUILabs() then
		warn("[KinUI] Running under UILabs or Studio — PlayerGui unavailable, using fallback")
		return nil
	end
	return nil
end

-- //SECTION -  Band resolution (S / M / L)
local function band(): SizeBand
	-- Prefer Roblox's size classes
	local ok, sizeEnum = pcall(function()
		return GuiService.ViewportDisplaySize
	end)
	if ok and sizeEnum then
		if sizeEnum == Enum.DisplaySize.Small then return "S" end
		if sizeEnum == Enum.DisplaySize.Medium then return "M" end
		return "L"
	end
	-- Fallback: short side heuristic
	local v = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local shortSide = math.min(v.X, v.Y)
	if shortSide <= 720 then return "S" end
	if shortSide <= 1080 then return "M" end
	return "L"
end
-- //!SECTION

-- //SECTION - Tokens

KinUI.Padding = { XS = 0.001, S = 0.01, M = 0.03, L = 0.05, XL = 0.1 } -- scale units

KinUI.Text = {
	-- min, max per band + relative scale to body
	title = { S = { 20, 28 }, M = { 24, 36 }, L = { 28, 44 }, scale = 1.9 },
	h1 = { S = { 16, 22 }, M = { 20, 28 }, L = { 24, 34 }, scale = 1.6 },
	h2 = { S = { 12, 18 }, M = { 14, 22 }, L = { 16, 26 }, scale = 1.4 },
	body = { S = { 10, 14 }, M = { 12, 16 }, L = { 14, 18 }, scale = 1.0 },
	caption = { S = { 8, 10 }, M = { 8, 12 }, L = { 8, 12 }, scale = 0.85 },
	LineHeight = 1.2,
}

KinUI.CornerPx = { S = 8, M = 10, L = 12 }
KinUI.StrokePx = { S = 0.5, M = 1, L = 2 }
-- //!SECTION

-- //SECTION - Internals
local function clamp(n: number, lo: number, hi: number): number
	return math.max(lo, math.min(hi, n))
end

local function currentShortSide(): number
	local v = camera and camera.ViewportSize or Vector2.new(1280, 720)
	return math.min(v.X, v.Y)
end

-- Body target ~ shortSide/40, clamped per band; other tokens scale off body
function KinUI.ComputeFontSize(token: TextToken): (number, number, number)
	local b: SizeBand = band()
	local t = KinUI.Text :: any
	local tokenSpec = t[token]
	local bodyMin, bodyMax = table.unpack(t.body[b])
	local bodyTarget = clamp(math.floor(currentShortSide() / 40 + 0.5), bodyMin, bodyMax)
	local minV, maxV = table.unpack(tokenSpec[b])
	local target = clamp(math.floor(bodyTarget * tokenSpec.scale + 0.5), minV, maxV)
	return target, minV, maxV
end

-- Attach/refresh UITextSizeConstraint; set TextScaled and LineHeight
function KinUI.ApplyTextConstraints(textObj: TextLabel | TextButton, token: "title" | "h1" | "h2" | "body" | "caption")
	local okToken = (KinUI.Text :: any)[token] and token or "body"

	local target, minV, maxV = KinUI.ComputeFontSize(okToken)

	target = math.clamp(math.floor(target + 0.5), 1, 200)
	minV = math.clamp(math.floor(minV + 0.5), 1, 200)
	maxV = math.clamp(math.floor(maxV + 0.5), 1, 200)

	if minV > maxV then
		minV, maxV = maxV, minV
	end

	target = math.clamp(target, minV, maxV)

	local constraint = textObj:FindFirstChildOfClass("UITextSizeConstraint")
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.Parent = textObj
	end

	if constraint then
		constraint.MaxTextSize = maxV
		constraint.MinTextSize = minV
	end

	textObj.TextScaled = true
	textObj.TextSize = target
	textObj.LineHeight = (KinUI.Text :: any).LineHeight
end

-- Panel look: pixel-consistent corners & strokes
function KinUI.ApplyPanelStyle(frame: Frame | TextLabel | ImageLabel, panelColor: Color3?)
	local bg = frame:FindFirstChildOfClass("ImageLabel") or Instance.new("ImageLabel")
	bg.Image = FFGEnum.UI.Frames.InnerPanel
	bg.BackgroundTransparency = 1
	bg.ImageColor3 = panelColor or FFGEnum.THEME.color.Blue
	bg.ScaleType = Enum.ScaleType.Slice
	bg.SliceCenter = Rect.new(35, 35, 35, 35)
	bg.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	bg.Position = FFGEnum.THEME.alignment.position.center
	bg.ZIndex = 0
	bg.Size = UDim2.fromScale(1, 1)
	bg.Parent = frame
end

function KinUI.AddStroke(instance: Instance, thickness: "S" | "M" | "L")
	local t = (KinUI.StrokePx :: any)[thickness]
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = t
	stroke.Parent = instance
end

-- Safe area helper: for ScreenGui with IgnoreGuiInset = true
-- Applies UIPadding (Scale) approximately matching the device inset.
function KinUI.ApplySafeAreaPadding(container: Instance)
	-- If IgnoreGuiInset=true, call this once on root container.
	local insetTopLeft, insetBottomRight = GuiService:GetGuiInset()
	-- Convert pixel inset to scale, relative to current viewport
	local v = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local pad = container:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
	pad.Parent = container

	local function pxToScaleX(px: number)
		return (v.X > 0) and (px / v.X) or 0
	end
	local function pxToScaleY(px: number)
		return (v.Y > 0) and (px / v.Y) or 0
	end

	pad.PaddingTop = UDim.new(pxToScaleY(insetTopLeft.Y), 0)
	pad.PaddingLeft = UDim.new(pxToScaleX(insetTopLeft.X), 0)
	pad.PaddingBottom = UDim.new(pxToScaleY(insetBottomRight.Y), 0)
	pad.PaddingRight = UDim.new(pxToScaleX(insetBottomRight.X), 0)
end

-- Set padding tokens on a UIPadding / UIListLayout
function KinUI.SetPadding(pad: UIPadding, token: "XS" | "S" | "M" | "L" | "XL")
	local s = (KinUI.Padding :: any)[token]
	pad.PaddingTop = UDim.new(s, 0)
	pad.PaddingBottom = UDim.new(s, 0)
	pad.PaddingLeft = UDim.new(s, 0)
	pad.PaddingRight = UDim.new(s, 0)
end

function KinUI.AddPadding(instance: Instance, token: "XS" | "S" | "M" | "L" | "XL")
	local s = (KinUI.Padding :: any)[token]
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(s, 0)
	pad.PaddingBottom = UDim.new(s, 0)
	pad.PaddingLeft = UDim.new(s, 0)
	pad.PaddingRight = UDim.new(s, 0)
	pad.Parent = instance
end

function KinUI.SetGap(layout: UIListLayout | UIGridLayout, token: "XS" | "S" | "M" | "L" | "XL")
	local s = (KinUI.Padding :: any)[token]
	if layout:IsA("UIGridLayout") then
		layout.CellPadding = UDim2.new(s, 0, s, 0)
	else
		layout.Padding = UDim.new(s, 0)
	end
end

-- //!SECTION

-- //SECTION - Aspect Constraints
function KinUI.ApplyAspect(frame: Frame | ImageLabel | ImageButton, ratio: number?, axis: Enum.DominantAxis?, aspectType: Enum.AspectType?)
	local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = ratio or 1 -- default: square
	aspect.DominantAxis = axis or Enum.DominantAxis.Width
	aspect.AspectType = aspectType or Enum.AspectType.ScaleWithParentSize
	aspect.Parent = frame
end

-- //SECTION - Apply List
function KinUI.ApplyList(
	frame: Instance,
	axis: Enum.FillDirection?,
	options: {
		HAlign: Enum.HorizontalAlignment?,
		VAlign: Enum.VerticalAlignment?,
		HFlex: Enum.UIFlexAlignment?,
		VFlex: Enum.UIFlexAlignment?,
		Padding: "XS" | "S" | "M" | "L" | "XL"?,
	}?
): UIListLayout
	local list = Instance.new("UIListLayout")
	list.FillDirection = axis or Enum.FillDirection.Horizontal
	if options and options.HAlign then list.HorizontalAlignment = options.HAlign end
	if options and options.VAlign then list.VerticalAlignment = options.VAlign end
	if options and options.HFlex then list.HorizontalFlex = options.HFlex end
	if options and options.VFlex then list.VerticalFlex = options.VFlex end
	if options and options.Padding then
		local s = (KinUI.Padding :: any)[options.Padding]
		list.Padding = UDim.new(s, 0)
	end
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = frame

	return list
end
-- //!SECTION

-- //!SECTION

-- //SECTION -  Live updates on viewport change
local connections: { RBXScriptConnection } = {}

-- Reapply callback whenever the size band may change
-- Supply a function that re-applies constraints to the current UI.
function KinUI.ObserveViewport(onUpdate: () -> ())
	-- Disconnect prior observers
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)

	-- GuiService class change
	table.insert(
		connections,
		GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(function()
			onUpdate()
		end)
	)

	-- Camera viewport change
	if camera then table.insert(
		connections,
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			onUpdate()
		end)
	) end

	-- Some UIs are recreated under PlayerGui; watch top-level ScreenGuis if needed
	local pg = KinUI.GetPlayerGui()
	if pg then
		table.insert(
			connections,
			pg.ChildAdded:Connect(function()
				onUpdate()
			end)
		)
		table.insert(
			connections,
			pg.ChildRemoved:Connect(function()
				onUpdate()
			end)
		)
	end

	-- Fire once on attach
	onUpdate()
end
-- //!SECTION

-- //SECTION - ValueBases
function KinUI.SetState(name: string, value: any, parent: Instance): ValueBase
	local valueType = typeof(value)
	local valueBase: ValueBase?

	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("ValueBase") then
		valueBase = existing :: ValueBase

		local correctType = false
		if valueType == "string" and valueBase:IsA("StringValue") then
			correctType = true
		elseif valueType == "number" and valueBase:IsA("NumberValue") then
			correctType = true
		elseif valueType == "boolean" and valueBase:IsA("BoolValue") then
			correctType = true
		elseif valueType == "Vector3" and valueBase:IsA("Vector3Value") then
			correctType = true
		elseif valueType == "Color3" and valueBase:IsA("Color3Value") then
			correctType = true
		elseif valueType == "CFrame" and valueBase:IsA("CFrameValue") then
			correctType = true
		elseif valueType == "Instance" and valueBase:IsA("ObjectValue") then
			correctType = true
		elseif valueType == "Ray" and valueBase:IsA("RayValue") then
			correctType = true
		end

		if not correctType then
			existing:Destroy()
			valueBase = nil
		end
	end

	if not valueBase then
		if valueType == "string" then
			valueBase = Instance.new("StringValue")
		elseif valueType == "number" then
			valueBase = Instance.new("NumberValue")
		elseif valueType == "boolean" then
			valueBase = Instance.new("BoolValue")
		elseif valueType == "Vector3" then
			valueBase = Instance.new("Vector3Value")
		elseif valueType == "Color3" then
			valueBase = Instance.new("Color3Value")
		elseif valueType == "CFrame" then
			valueBase = Instance.new("CFrameValue")
		elseif valueType == "Instance" then
			valueBase = Instance.new("ObjectValue")
		elseif valueType == "Ray" then
			valueBase = Instance.new("RayValue")
		else
			valueBase = Instance.new("StringValue")
		end

		valueBase.Name = name
		valueBase.Parent = parent
	end

	assert(valueBase, "Failed to create or find ValueBase")
	if valueType == "string" then
		(valueBase :: StringValue).Value = value
	elseif valueType == "number" then
		(valueBase :: NumberValue).Value = value
	elseif valueType == "boolean" then
		(valueBase :: BoolValue).Value = value
	elseif valueType == "Vector3" then
		(valueBase :: Vector3Value).Value = value
	elseif valueType == "Color3" then
		(valueBase :: Color3Value).Value = value
	elseif valueType == "CFrame" then
		(valueBase :: CFrameValue).Value = value
	elseif valueType == "Instance" then
		(valueBase :: ObjectValue).Value = value
	elseif valueType == "Ray" then
		(valueBase :: RayValue).Value = value
	else
		(valueBase :: StringValue).Value = tostring(value)
	end

	return valueBase
end
-- //!SECTION

return KinUI
