local Separator = require("colorful-winsep.separator")
local config = require("colorful-winsep.config")
local utils = require("colorful-winsep.utils")
local api = vim.api
local fn = vim.fn
local directions = utils.directions

local M = {}
M.separators = {
  left = Separator:new(),
  down = Separator:new(),
  up = Separator:new(),
  right = Separator:new(),
}

---@param only_2wins boolean we should deal with 2 windows situation
function M.render_left(only_2wins)
  local sep_height = fn.winheight(0)
  local pos = api.nvim_win_get_position(0)
  local current_row, current_col = pos[1], pos[2]
  local anchor_row = current_row
  local anchor_col = current_col - 1
  local sep = M.separators.left
  -- sep.start_symbol = config.opts.border[2]
  sep.body_symbol = config.opts.border[2]
  -- sep.end_symbol = config.opts.border[2]
  sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_left
  sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_left

  -- vim.notify('render_left')

  if utils.has_winbar() then
    -- anchor_row = anchor_row + 1
    sep_height = sep_height + 1
  end

  -- inbetween top and bottom
  if utils.has_adjacent_win(directions.up) and utils.has_adjacent_win(directions.down) then
    sep.start_symbol = config.opts.border[3]   -- top left corner
    sep.end_symbol = config.opts.border[5]     -- bottom left corner
    anchor_row = anchor_row - 1 + config.opts.offset.top
    sep_height = sep_height + 2 - config.opts.offset.top

    -- top window
  elseif utils.has_adjacent_win(directions.down) then
    sep.start_symbol = config.opts.border[3]   -- top left corner
    sep.end_symbol = config.opts.border[5]     -- bottom left corner

    if config.opts.offset.top > 0 then
      anchor_row = anchor_row - 1 + config.opts.offset.top
      sep_height = sep_height + 2 - config.opts.offset.top
    else
      sep_height = sep_height + 1 - config.opts.offset.top
    end

    -- bottom window
  elseif utils.has_adjacent_win(directions.up) then
    sep.start_symbol = config.opts.border[3]   -- top left corner
    sep.end_symbol = config.opts.border[5]     -- bottom left corner
    anchor_row = anchor_row - 1 + config.opts.offset.top
    sep_height = sep_height + 2 - config.opts.offset.top
  end


  local highlight_start = true
  local highlight_end = true
  if only_2wins then
    -- anchor_row = 1
    -- sep_height = math.ceil(fn.winheight(0) / 2)
    if config.opts.indicator_for_2wins.position == "center" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_left
      highlight_start = false
    elseif config.opts.indicator_for_2wins.position == "start" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_left
      highlight_start = false
    elseif config.opts.indicator_for_2wins.position == "end" then
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_left
      highlight_end = false
    elseif config.opts.indicator_for_2wins.position == "both" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_left
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_left
      highlight_start = false
      highlight_end = false
    end
  end

  sep:vertical_init(sep_height, highlight_start, highlight_end)
  if not sep._show then
    sep:move(anchor_row, anchor_col)
    sep:show()
  elseif config.opts.animate.enabled == "shift" then
    sep:shift_move(anchor_row, anchor_col)
  else
    sep:move(anchor_row, anchor_col)
  end
end

---@param only_2wins boolean we should deal with 2 windows situation
function M.render_down(only_2wins)
  local sep_width = fn.winwidth(0)
  local pos = api.nvim_win_get_position(0)
  local current_row, current_col = pos[1], pos[2]
  -- local anchor_row = current_row + fn.winheight(0)
  local anchor_row = current_row
  local anchor_col = current_col
  local sep = M.separators.down
  sep.start_symbol = config.opts.border[1]
  sep.body_symbol = config.opts.border[1]
  sep.end_symbol = config.opts.border[1]
  -- sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_up
  -- sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_up

  -- vim.notify('render_down')

  -- if utils.has_winbar() then
  --   -- anchor_row = anchor_row + 1
  --   sep_height = sep_height + 1
  -- end

  -- inbetween window
  if utils.has_adjacent_win(directions.up) and utils.has_adjacent_win(directions.down) then
    anchor_row = anchor_row - 1 + config.opts.offset.top
    -- top window
  elseif utils.has_adjacent_win(directions.down) then
    if config.opts.offset.top > 0 then
      anchor_row = anchor_row - 1 + config.opts.offset.top
    end
  end

  local highlight_start = true
  local highlight_end = true
  if only_2wins then
    -- sep_width = math.ceil(sep_width / 2)
    if config.opts.indicator_for_2wins.position == "center" then
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_down
      highlight_end = false
    elseif config.opts.indicator_for_2wins.position == "start" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_down
      highlight_start = false
    elseif config.opts.indicator_for_2wins.position == "end" then
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_down
      highlight_end = false
    elseif config.opts.indicator_for_2wins.position == "both" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_down
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_down
      highlight_start = false
      highlight_end = false
    end
  end

  sep:horizontal_init(sep_width, highlight_start, highlight_end)
  if not sep._show then
    sep:move(anchor_row, anchor_col)
    if config.opts.horizontal_separator == "enabled" then
      sep:show()
    end
  elseif config.opts.animate.enabled == "shift" then
    sep:shift_move(anchor_row, anchor_col)
  else
    sep:move(anchor_row, anchor_col)
  end
end

---@param only_2wins boolean we should deal with 2 windows situation
function M.render_up(only_2wins)
  local sep_width = fn.winwidth(0)
  local pos = api.nvim_win_get_position(0)
  local current_row, current_col = pos[1], pos[2]
  -- local anchor_row = current_row - 1
  local anchor_row = current_row - 1
  local anchor_col = current_col
  local sep = M.separators.up
  sep.start_symbol = config.opts.border[1]
  sep.body_symbol = config.opts.border[1]
  sep.end_symbol = config.opts.border[1]
  -- sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_up
  -- sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_up

  -- vim.notify('render_up')

  -- if utils.has_winbar() then
  --   -- anchor_row = anchor_row + 1
  --   sep_height = sep_height + 1
  -- end

  if config.opts.offset.top > 0 then
    anchor_row = anchor_row + config.opts.offset.top
  end

  local highlight_start = true
  local highlight_end = true
  if only_2wins then
    -- anchor_col = sep_width - math.ceil(sep_width / 2)
    -- sep_width = math.ceil(sep_width / 2)
    if config.opts.indicator_for_2wins.position == "center" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_up
      highlight_start = false
    elseif config.opts.indicator_for_2wins.position == "start" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_up
      highlight_start = false
    elseif config.opts.indicator_for_2wins.position == "end" then
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_up
      highlight_end = false
    elseif config.opts.indicator_for_2wins.position == "both" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_up
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_up
      highlight_start = false
      highlight_end = false
    end
  end

  sep:horizontal_init(sep_width, highlight_start, highlight_end)
  if not sep._show then
    sep:move(anchor_row, anchor_col)
    if config.opts.horizontal_separator == "enabled" then
      sep:show()
    end
  elseif config.opts.animate.enabled == "shift" then
    sep:shift_move(anchor_row, anchor_col)
  else
    sep:move(anchor_row, anchor_col)
  end
end

---@param only_2wins boolean we should deal with 2 windows situation
function M.render_right(only_2wins)
  local sep_height = fn.winheight(0)
  local pos = api.nvim_win_get_position(0)
  local current_row, current_col = pos[1], pos[2]
  local anchor_row = current_row
  local anchor_col = current_col + fn.winwidth(0)
  local sep = M.separators.right
  -- sep.start_symbol = config.opts.border[2]
  sep.body_symbol = config.opts.border[2]
  -- sep.end_symbol = config.opts.border[2]
  sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_right
  sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_right

  -- vim.notify('render_right')

  if utils.has_winbar() then
    -- anchor_row = anchor_row + 1
    sep_height = sep_height + 1
  end

  -- inbetween top and bottom
  if utils.has_adjacent_win(directions.up) and utils.has_adjacent_win(directions.down) then
    sep.start_symbol = config.opts.border[4]   -- top left corner
    sep.end_symbol = config.opts.border[6]     -- bottom left corner
    anchor_row = anchor_row - 1 + config.opts.offset.top
    sep_height = sep_height + 2 - config.opts.offset.top

    -- top window
  elseif utils.has_adjacent_win(directions.down) then
    sep.start_symbol = config.opts.border[4]   -- top left corner
    sep.end_symbol = config.opts.border[6]     -- bottom left corner

    if config.opts.offset.top > 0 then
      anchor_row = anchor_row - 1 + config.opts.offset.top
      sep_height = sep_height + 2 - config.opts.offset.top
    else
      sep_height = sep_height + 1 - config.opts.offset.top
    end

    -- bottom window
  elseif utils.has_adjacent_win(directions.up) then
    sep.start_symbol = config.opts.border[4]   -- top left corner
    sep.end_symbol = config.opts.border[6]     -- bottom left corner
    anchor_row = anchor_row - 1 + config.opts.offset.top
    sep_height = sep_height + 2 - config.opts.offset.top
  end

  local highlight_start = true
  local highlight_end = true
  if only_2wins then
    -- anchor_row = math.ceil(fn.winheight(0) / 2)
    -- sep_height = math.ceil(fn.winheight(0) / 2) -- + 1 moves into status line
    -- anchor_row = 1
    -- sep_height = math.ceil(fn.winheight(0) / 2) -- + 1 moves into status line
    if config.opts.indicator_for_2wins.position == "center" then
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_right
      highlight_end = false
    elseif config.opts.indicator_for_2wins.position == "start" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_right
      highlight_start = false
    elseif config.opts.indicator_for_2wins.position == "end" then
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_right
      highlight_end = false
    elseif config.opts.indicator_for_2wins.position == "both" then
      sep.start_symbol = config.opts.indicator_for_2wins.symbols.start_right
      sep.end_symbol = config.opts.indicator_for_2wins.symbols.end_right
      highlight_start = false
      highlight_end = false
    end
  end

  sep:vertical_init(sep_height, highlight_start, highlight_end)
  if not sep._show then
    sep:move(anchor_row, anchor_col)
    sep:show()
  elseif config.opts.animate.enabled == "shift" then
    sep:shift_move(anchor_row, anchor_col)
  else
    sep:move(anchor_row, anchor_col)
  end
end

--- draw the progressive animation
---@param separator Separator
---@param animate_config table
---@param reverse boolean
local function vertical_progressive(separator, animate_config, reverse)
  local position = 0
  if separator.timer and not separator.timer:is_closing() then
    separator.timer:stop()
    separator.timer:close()
  end
  separator.timer = vim.uv.new_timer()
  separator.timer:start(
    1,
    animate_config.vertical_delay,
    vim.schedule_wrap(function()
      if separator._show then
        position = position + 1
        if reverse then
          utils.color(separator.buffer, separator.window.height - position + 1, 1)
        else
          utils.color(separator.buffer, position, 1)
        end
      end
      if position == separator.window.height and not separator.timer:is_closing() then
        separator.timer:stop()
        separator.timer:close()
      end
    end)
  )
end

--- draw the progressive animation
---@param separator Separator
---@param animate_config table
---@param reverse boolean
local function horizontal_progressive(separator, animate_config, reverse)
  local position = 0
  if separator.timer and not separator.timer:is_closing() then
    separator.timer:stop()
    separator.timer:close()
  end
  separator.timer = vim.uv.new_timer()

  local lines = api.nvim_buf_get_lines(separator.buffer, 0, 1, false)
  if #lines == 0 then
    return
  end
  local line_content = lines[1]
  local line_len = #line_content

  separator.timer:start(
    1,
    animate_config.horizontal_delay,
    vim.schedule_wrap(function()
      if separator._show then
        position = position + 1
        if reverse then
          utils.color(separator.buffer, 1, line_len - position + 1)
        else
          utils.color(separator.buffer, 1, position)
        end
      end
      if position >= line_len and not separator.timer:is_closing() then
        separator.timer:stop()
        separator.timer:close()
      end
    end)
  )
end

local function progressive_animate()
  local animate_config = config.opts.animate.progressive
  for dir, sep in pairs(M.separators) do
    if dir == "left" or dir == "right" then
      vertical_progressive(sep, animate_config, dir == "right")
    else
      horizontal_progressive(sep, animate_config, dir == "down")
    end
  end
end

--- the order of rendering a full set of separators:  left -> down -> up -> right (i.e. hjlkl)
function M.render()
  local only_2wins = utils.count_windows() == 2

  local render_map = {
    left = M.render_left,
    down = M.render_down,
    up = M.render_up,
    right = M.render_right,
  }

  for dir, render_func in pairs(render_map) do
    if utils.has_adjacent_win(directions[dir]) then
      render_func(only_2wins)
    else
      M.separators[dir]:hide()
    end
  end

  if config.opts.animate.enabled == "progressive" then
    progressive_animate()
  end
end

function M.hide_all()
  for _, sep in pairs(M.separators) do
    sep:hide()
  end
end

return M
