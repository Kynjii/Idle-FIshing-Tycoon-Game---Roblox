local TweenService = game:GetService("TweenService")

-- Weak-key map so entries vanish when parts GC
local _active = setmetatable({}, { __mode = "k" })

-- opts:
--   duration: number? (default 0.5)
--   easingStyle: Enum.EasingStyle? (default Linear)
--   easingDir: Enum.EasingDirection? (default Out)
--   from: "bottom" | "top" (default "bottom")
--   cleaner: any?  -- your cleaner with :add(tween)
--   ratio: number? -- 0..1; if given with maxHeight, overrides targetHeight
--   maxHeight: number? -- used with ratio
--   targetHeight: number? -- direct height; clamped to maxHeight if both provided
local function ResizeY(
	part: BasePart,
	opts: {
		duration: number?,
		easingStyle: Enum.EasingStyle?,
		easingDir: Enum.EasingDirection?,
		from: string?,
		cleaner: any?,
		ratio: number?,
		maxHeight: number?,
		targetHeight: number?,
	}
)
	if not part or not part.Parent then return end
	opts = opts or {}

	-- Cancel any previous tween on this part
	local prev = _active[part]
	if prev then
		pcall(function()
			prev:Cancel()
		end)
		_active[part] = nil
	end

	local minH = tonumber(opts.minHeight) or 0
	local maxH = tonumber(opts.maxHeight) or math.huge

	local targetH
	if opts.ratio ~= nil and opts.maxHeight ~= nil then
		local r = math.clamp(tonumber(opts.ratio) or 0, 0, 1)
		targetH = r * maxH
	else
		targetH = tonumber(opts.targetHeight) or part.Size.Y
	end

	targetH = math.clamp(targetH, minH, maxH)

	local oldSize = part.Size
	local newSize = Vector3.new(oldSize.X, targetH, oldSize.Z)

	-- Offset so chosen edge stays fixed
	local dy = (targetH - oldSize.Y) * 0.5
	if (opts.from or "bottom") == "bottom" then
		-- grow upward: shift center up
		-- keep orientation by multiplying a pure translation
		local newCF = part.CFrame * CFrame.new(0, dy, 0)
		local info = TweenInfo.new(opts.duration or 0.5, opts.easingStyle or Enum.EasingStyle.Linear, opts.easingDir or Enum.EasingDirection.Out)
		local tween = TweenService:Create(part, info, { Size = newSize, CFrame = newCF })
		_active[part] = tween
		if opts.cleaner and type(opts.cleaner.add) == "function" then opts.cleaner:add(tween) end
		tween.Completed:Once(function()
			if _active[part] == tween then _active[part] = nil end
			pcall(function()
				tween:Destroy()
			end)
		end)
		tween:Play()
		return tween
	else
		-- grow downward from the top
		local newCF = part.CFrame * CFrame.new(0, -dy, 0)
		local info = TweenInfo.new(opts.duration or 0.5, opts.easingStyle or Enum.EasingStyle.Linear, opts.easingDir or Enum.EasingDirection.Out)
		local tween = TweenService:Create(part, info, { Size = newSize, CFrame = newCF })
		_active[part] = tween
		if opts.cleaner and type(opts.cleaner.add) == "function" then opts.cleaner:add(tween) end
		tween.Completed:Once(function()
			if _active[part] == tween then _active[part] = nil end
			pcall(function()
				tween:Destroy()
			end)
		end)
		tween:Play()
		return tween
	end
end

-- Convenience wrappers
local M = {}

-- Grow by ratio (0..1) up to maxHeight, from "bottom" by default
function M.ResizeByRatio(part: BasePart, ratio: number, maxHeight: number, opts)
	opts = opts or {}
	opts.ratio = ratio
	opts.maxHeight = maxHeight
	return ResizeY(part, opts)
end

-- Grow to an absolute height (clamped to maxHeight if provided)
function M.ResizeToHeight(part: BasePart, targetHeight: number, opts)
	opts = opts or {}
	opts.targetHeight = targetHeight
	return ResizeY(part, opts)
end

-- Cancel any active tween on this part (optional utility)
function M.Cancel(part: BasePart)
	local t = _active[part]
	if t then
		pcall(function()
			t:Cancel()
		end)
		_active[part] = nil
	end
end

return M
