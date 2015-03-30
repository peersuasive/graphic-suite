--[[

set all wished filters here

--]]

local mods = {
    "grayscale",
    "transform",
    "denoise",
    "twirl",
    "oil",
    "jitter",
    "wgn",
    "normalise",
    "modulate",
    "average",
    "histogram",
    "histogramHSL",
}

---

local verb = function()end
if DEBUG then verb=function(s,...) print(string.format(s),...) end end

local plugins = {}
for _,mod in next,mods do
    local r,p = pcall(require,"imfilters."..mod)
    if r then verb(string.format("LOADED: %s (%s)", mod, r)) plugins[mod] = p
    else verb(string.format("WARNING: couldn't load filter: %s", mod)) end
end
return plugins
