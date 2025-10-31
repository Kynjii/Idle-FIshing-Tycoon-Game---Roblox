local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

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

local UIConfig = {}

function UIConfig.getPlayerGui(): PlayerGui?
	if playerGui and playerGui.Parent then return playerGui end
	if isUILabs() then
		warn("[UIConfig] Running under UILabs or Studio — PlayerGui unavailable, using fallback")
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

UIConfig.Padding = { XS = 0.008, S = 0.012, M = 0.016, L = 0.024, XL = 0.032 } -- scale units

UIConfig.Text = {
	-- min, max per band + relative scale to body
	title = { S = { 28, 36 }, M = { 32, 44 }, L = { 36, 52 }, scale = 1.9 },
	h1 = { S = { 24, 30 }, M = { 28, 36 }, L = { 32, 42 }, scale = 1.6 },
	h2 = { S = { 20, 26 }, M = { 22, 30 }, L = { 24, 34 }, scale = 1.4 },
	body = { S = { 14, 18 }, M = { 16, 20 }, L = { 18, 22 }, scale = 1.0 },
	caption = { S = { 12, 14 }, M = { 12, 16 }, L = { 12, 16 }, scale = 0.85 },
	LineHeight = 1.2,
}

UIConfig.CornerPx = { S = 8, M = 10, L = 12 }
UIConfig.StrokePx = { S = 1, M = 1, L = 2 }
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
function UIConfig.computeFontSize(token: TextToken): (number, number, number)
	local b: SizeBand = band()
	local t = UIConfig.Text :: any
	local tokenSpec = t[token]
	local bodyMin, bodyMax = table.unpack(t.body[b])
	local bodyTarget = clamp(math.floor(currentShortSide() / 40 + 0.5), bodyMin, bodyMax)
	local minV, maxV = table.unpack(tokenSpec[b])
	local target = clamp(math.floor(bodyTarget * tokenSpec.scale + 0.5), minV, maxV)
	return target, minV, maxV
end

-- Attach/refresh UITextSizeConstraint; set TextScaled and LineHeight
function UIConfig.applyTextConstraints(textObj: TextLabel | TextButton, token: TextToken)
	local target, minV, maxV = UIConfig.computeFontSize(token)
	textObj.TextScaled = true
	textObj.TextSize = target
	textObj.LineHeight = (UIConfig.Text :: any).LineHeight

	local constraint = textObj:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.Parent = textObj
	end
	constraint.MinTextSize = minV
	constraint.MaxTextSize = maxV
end

-- Panel look: pixel-consistent corners & strokes
function UIConfig.applyPanelStyle(frame: Frame | TextLabel | ImageLabel)
	local b: SizeBand = band()

	local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerPx[b])
	corner.Parent = frame

	local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Thickness = UIConfig.StrokePx[b]
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
end

-- Safe area helper: for ScreenGui with IgnoreGuiInset = true
-- Applies UIPadding (Scale) approximately matching the device inset.
function UIConfig.applySafeAreaPadding(container: Instance)
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
function UIConfig.setPadding(pad: UIPadding, token: "XS" | "S" | "M" | "L" | "XL")
	local s = (UIConfig.Padding :: any)[token]
	pad.PaddingTop = UDim.new(s, 0)
	pad.PaddingBottom = UDim.new(s, 0)
	pad.PaddingLeft = UDim.new(s, 0)
	pad.PaddingRight = UDim.new(s, 0)
end

function UIConfig.setGap(layout: UIListLayout | UIGridLayout, token: "XS" | "S" | "M" | "L" | "XL")
	local s = (UIConfig.Padding :: any)[token]
	if layout:IsA("UIGridLayout") then
		layout.CellPadding = UDim2.new(s, 0, s, 0)
	else
		layout.Padding = UDim.new(s, 0)
	end
end

-- //!SECTION

-- //SECTION - Aspect Constraints
function UIConfig.applyAspect(frame: Frame, ratio: number?, axis: Enum.DominantAxis?)
	local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = ratio or 1 -- default: square
	aspect.DominantAxis = axis or Enum.DominantAxis.Width
	aspect.AspectType = Enum.AspectType.ScaleWithParentSize
	aspect.Parent = frame
end

-- //!SECTION

-- //SECTION -  Live updates on viewport change
local connections: { RBXScriptConnection } = {}

-- Reapply callback whenever the size band may change
-- Supply a function that re-applies constraints to the current UI.
function UIConfig.observeViewport(onUpdate: () -> ())
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
	local pg = UIConfig.getPlayerGui()
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

return UIConfig
