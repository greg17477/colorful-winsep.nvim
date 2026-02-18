local utils = require("colorful-winsep.utils")
local config = require("colorful-winsep.config")
local api = vim.api
local uv = vim.uv

---@class Separator
---@field start_symbol string
---@field body_symbol string
---@field end_symbol string
---@field buffer integer
---@field winid integer?
---@field window { style: string, border: string, relative: string, zindex: integer, focusable: boolean, height: integer, width: integer, row: integer, col: integer }
---@field extmarks table
---@field _show boolean
local Separator = {}

--- create a new separator
---@return Separator
function Separator:new()
  local buf = api.nvim_create_buf(false, true)
  api.nvim_set_option_value("buftype", "nofile", { buf = buf })

  local o = {
    start_symbol = "",
    body_symbol = "",
    end_symbol = "",
    buffer = buf,
    winid = nil,
    -- for nvim_open_win
    window = {
      style = "minimal",
      border = "none",
      relative = "editor",
      zindex = 1,
      focusable = false,
      height = 1,
      width = 1,
      row = 0,
      col = 0,
    },
    extmarks = {},
    timer = uv.new_timer(),
    _show = false,
  }

  self.__index = self
  setmetatable(o, self)
  return o
end

--- vertically initialize the separator window and buffer
---@param height integer
---@param highlight_start boolean?
---@param highlight_end boolean?
function Separator:vertical_init(height, highlight_start, highlight_end)
  self.window.height = height
  self.window.width = 1

  local content = { self.start_symbol }
  for i = 2, height - 1 do
    content[i] = self.body_symbol
  end
  content[height] = self.end_symbol
  api.nvim_buf_set_lines(self.buffer, 0, -1, false, content)

  local ns_id = api.nvim_create_namespace("colorful-winsep-symbols")
  api.nvim_buf_clear_namespace(self.buffer, ns_id, 0, -1)

  -- Highlight first line (start)
  if highlight_start ~= false then
    api.nvim_buf_set_extmark(self.buffer, ns_id, 0, 0, {
      end_row = 1,
      end_col = #self.start_symbol - 1,
      -- end_col = 1,
      hl_group = "ColorfulWinSepStart",
    })
  end
  -- Highlight last line (end)
  if highlight_end ~= false then
    api.nvim_buf_set_extmark(self.buffer, ns_id, height - 1, 0, {
      end_row = height - 1,
      end_col = #self.end_symbol - 1,
      -- end_col = 1,
      hl_group = "ColorfulWinSepEnd",
    })
  end
end

--- horizontally initialize the separator window and buffer
---@param width integer
---@param highlight_start boolean?
---@param highlight_end boolean?
---@param title string?
function Separator:horizontal_init(width, highlight_start, highlight_end, title)
  self.window.height = 1
  self.window.width = width
  local start_symbol = self.start_symbol
  local end_symbol = self.end_symbol
  local body_symbol = self.body_symbol

  local ns_id = api.nvim_create_namespace("colorful-winsep-symbols")
  api.nvim_buf_clear_namespace(self.buffer, ns_id, 0, -1)

  local line_content = ""
  local title_start_byte = -1
  local title_end_byte = -1

  if title and title ~= "" and config.opts.header and config.opts.header.enabled then
    local display_title = " " .. title .. " "
    local title_w = vim.fn.strwidth(display_title)
    local start_w = vim.fn.strwidth(start_symbol)
    local end_w = vim.fn.strwidth(end_symbol)
    local body_w = width - start_w - end_w

    if title_w <= body_w then
      local left_pad_w = math.floor((body_w - title_w) / 2)
      local right_pad_w = body_w - title_w - left_pad_w

      local left_body = string.rep(body_symbol, left_pad_w)
      local right_body = string.rep(body_symbol, right_pad_w)

      line_content = start_symbol .. left_body .. display_title .. right_body .. end_symbol
      title_start_byte = #start_symbol + #left_body
      title_end_byte = title_start_byte + #display_title
    else
      line_content = start_symbol .. string.rep(body_symbol, body_w) .. end_symbol
    end
  else
    local start_w = vim.fn.strwidth(start_symbol)
    local end_w = vim.fn.strwidth(end_symbol)
    line_content = start_symbol .. string.rep(body_symbol, width - start_w - end_w) .. end_symbol
  end

  api.nvim_buf_set_lines(self.buffer, 0, -1, false, { line_content })

  -- Highlight start
  if highlight_start ~= false then
    api.nvim_buf_set_extmark(self.buffer, ns_id, 0, 0, {
      end_col = #start_symbol,
      hl_group = "ColorfulWinSepStart",
    })
  end

  -- Highlight title
  if title_start_byte ~= -1 then
    api.nvim_buf_set_extmark(self.buffer, ns_id, 0, title_start_byte, {
      end_col = title_end_byte,
      hl_group = config.opts.header.highlight or "ColorfulWinSepHeader",
    })
  end

  -- Highlight end
  if highlight_end ~= false then
    api.nvim_buf_set_extmark(self.buffer, ns_id, 0, #line_content - #end_symbol, {
      end_col = #line_content,
      hl_group = "ColorfulWinSepEnd",
    })
  end
end

--- reload the separator window config immediately
function Separator:reload_config()
  if self.winid ~= nil and api.nvim_win_is_valid(self.winid) then
    api.nvim_win_set_config(self.winid, self.window)
  end
end

---move the window to a sepcified coordinate relative to window
---@param row integer
---@param col integer
function Separator:move(row, col)
  self.window.row = row
  self.window.col = col
  self:reload_config()
end

--- move the windows with shift animate
---@param row integer
---@param col integer
function Separator:shift_move(row, col)
  local pos = api.nvim_win_get_position(self.winid)
  local current_row, current_col = pos[1], pos[2]
  if not self.timer:is_closing() then
    self.timer:stop()
    self.timer:close()
  end
  self.timer = vim.uv.new_timer()

  local animate_config = config.opts.animate.shift
  self.timer:start(
    0,
    animate_config.delay,
    vim.schedule_wrap(function()
      -- calculate exponential decay
      local decay_factor = math.exp(-animate_config.smooth_speed * animate_config.delta_time)

      -- perform linear interpolation
      current_row = utils.lerp(row, current_row, decay_factor)
      current_col = utils.lerp(col, current_col, decay_factor)

      -- update line position
      self:move(math.floor(current_row + 0.5), math.floor(current_col + 0.5))       -- round

      -- check if position is close enough to the target
      if math.abs(current_row - row) < 0.5 and math.abs(current_col - col) < 0.5 then
        if not self.timer:is_closing() then
          self.timer:stop()
          self.timer:close()
        end
      end
    end)
  )
end

--- show the separator window
function Separator:show()
  if api.nvim_buf_is_valid(self.buffer) then
    local win = api.nvim_open_win(self.buffer, false, self.window)
    self.winid = win
    self._show = true
    if config.opts.animate.enabled ~= "progressive" then
      api.nvim_set_option_value("winhl", "Normal:ColorfulWinSep", { win = win })
    else
      api.nvim_set_option_value("winhl", "Normal:WinSeparator", { win = win })
    end
    api.nvim_set_option_value("winblend", 100, { win = win })
  end
end

--- hide the separator window
function Separator:hide()
  if self.winid ~= nil and api.nvim_win_is_valid(self.winid) then
    api.nvim_win_hide(self.winid)
    self.winid = nil
    self._show = false
  end
end

return Separator
