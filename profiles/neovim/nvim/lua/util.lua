local M = {}

local as_byte = function(value, offset)
  return bit.band(bit.rshift(value, offset), 0xFF)
end

local blend_channel = function(from, to, amount)
  local ret = amount * from + (1 - amount) * to
  return math.floor(math.min(math.max(0, ret), 255) + 0.5)
end

M.blend = function(from, to, amount)
  if type(from) == 'string' then
    from = vim.api.nvim_get_color_by_name(from)
  end
  local from_parts = { as_byte(from, 16), as_byte(from, 8), as_byte(from, 0) }

  if type(to) == 'string' then
    to = vim.api.nvim_get_color_by_name(to)
  end
  local to_parts = { as_byte(to, 16), as_byte(to, 8), as_byte(to, 0) }

  local r = blend_channel(from_parts[1], to_parts[1], amount)
  local g = blend_channel(from_parts[2], to_parts[2], amount)
  local b = blend_channel(from_parts[3], to_parts[3], amount)
  return ('#%02X%02X%02X'):format(r, g, b)
end

M.luminance = function(hex)
  if type(hex) == 'number' then
    hex = ('%06x'):format(hex)
  end
  local red = tonumber(hex:sub(1, 2), 16)
  local green = tonumber(hex:sub(3, 4), 16)
  local blue = tonumber(hex:sub(5, 6), 16)

  return (red * 299 + green * 587 + blue * 114) / 1000
end

return M
