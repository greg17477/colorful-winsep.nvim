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
        -- api.nvim_buf_add_highlight(self.buffer, ns_id, "ColorfulWinSepStart", 0, 0, -1)
        api.nvim_buf_set_extmark(self.buffer, ns_id, 0, 0, {
            end_row = 1,
            end_col = 1,
            hl_group = "ColorfulWinSepStart",
        })
    end
    -- Highlight last line (end)
    if highlight_end ~= false then
        -- api.nvim_buf_add_highlight(self.buffer, ns_id, "ColorfulWinSepEnd", height - 1, 0, -1)
        api.nvim_buf_set_extmark(self.buffer, ns_id, height - 1, 0, {
            end_row = height - 1,
            end_col = 1,
            hl_group = "ColorfulWinSepEnd",
        })
    end
end

--- horizontally initialize the separator window and buffer
---@param width integer
---@param highlight_start boolean?
---@param highlight_end boolean?
function Separator:horizontal_init(width, highlight_start, highlight_end)
    self.window.height = 1
    self.window.width = width
    local start_text = self.start_symbol
    local body_text = string.rep(self.body_symbol, width - 2)
    local end_text = self.end_symbol

    local line_content = start_text .. body_text .. end_text
    api.nvim_buf_set_lines(self.buffer, 0, -1, false, { line_content })

    -- Apply specific highlights
    local ns_id = api.nvim_create_namespace("colorful-winsep-symbols")
    api.nvim_buf_clear_namespace(self.buffer, ns_id, 0, -1)

    -- Highlight start_symbol
    if highlight_start ~= false then
        -- api.nvim_buf_add_highlight(self.buffer, ns_id, "ColorfulWinSepStart", 1, 0, #start_text)
        api.nvim_buf_set_extmark(self.buffer, ns_id, 0, 0, {
            end_col = #start_text - 1,
            hl_group = "ColorfulWinSepStart",
        })
    end
    -- Highlight end_symbol
    if highlight_end ~= false then
        -- api.nvim_buf_add_highlight(self.buffer, ns_id, "ColorfulWinSepEnd", 0, #line_content - #end_text, 0)
        api.nvim_buf_set_extmark(self.buffer, ns_id, 0, #line_content - #end_text, {
            end_col = #line_content - 1,
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
    -- local current_row, current_col = unpack(api.nvim_win_get_position(self.winid))
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
            self:move(math.floor(current_row + 0.5), math.floor(current_col + 0.5)) -- round

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
