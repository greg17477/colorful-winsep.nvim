local fn = vim.fn
local M = {}

local ns_id = vim.api.nvim_create_namespace("colorful-winsep")

M.directions = { left = "h", down = "j", up = "k", right = "l" }

--- check if there is adjacent window in specified direction
---@param direction "h"|"l"|"k"|"j"
---@return boolean
function M.has_adjacent_win(direction)
  local winnum = vim.fn.winnr()
  if fn.winnr(direction) ~= winnum and fn.win_gettype(winnum) ~= "popup" then
    return true
  end
  return false
end

--- check if user enable the nvim winbar feature
---@return boolean
function M.has_winbar()
  return vim.o.winbar ~= ""
end

--- count the number of all windws except floating windows
---@return integer
function M.count_windows()
  local count = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      count = count + 1
    end
  end
  return count
end

function M.color(buf, line, col)
  -- set extmark for the character (line/col are 0-indexed)
  vim.api.nvim_buf_set_extmark(buf, ns_id, line - 1, col - 1, {
    end_col = col,      -- exclusive
    hl_group = "ColorfulWinSep",
    hl_eol = false,     -- do not highlight beyond EOL
  })
end

---@param a integer
---@param b integer
---@param t integer
---@return integer
function M.lerp(a, b, t)
  return a + (b - a) * t
end

return M
