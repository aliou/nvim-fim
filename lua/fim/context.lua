-- Context extraction for nvim-codestral
-- Extracts prefix and suffix around cursor for FIM requests

local config = require('fim.config')

local M = {}

--- Get the current context around cursor for FIM request
---@return {prefix:string, suffix:string, cursor:{line:number, col:number}}|nil Context or nil if disabled
function M.get_current_context()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  
  -- Check if filetype is disabled
  if vim.tbl_contains(config.options.disabled_filetypes, filetype) then
    return nil
  end
  
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1  -- Convert to 0-based index
  local col = cursor[2]
  
  -- Get current line
  local current_line = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
  
  -- Extract prefix: lines before cursor line + current line up to cursor
  local prefix_start_line = math.max(0, line - config.options.context.prefix_lines + 1)
  local prefix_lines = vim.api.nvim_buf_get_lines(bufnr, prefix_start_line, line, false)
  -- Add current line up to cursor position
  table.insert(prefix_lines, current_line:sub(1, col))
  local prefix = table.concat(prefix_lines, "\n")
  
  -- Extract suffix: current line from cursor + lines after cursor line
  local suffix_end_line = math.min(
    vim.api.nvim_buf_line_count(bufnr),
    line + config.options.context.suffix_lines + 1
  )
  local suffix_lines = vim.api.nvim_buf_get_lines(bufnr, line + 1, suffix_end_line, false)
  -- Add current line from cursor position at the beginning
  table.insert(suffix_lines, 1, current_line:sub(col + 1))
  local suffix = table.concat(suffix_lines, "\n")
  
  -- Truncate to max character limits
  prefix = prefix:sub(-config.options.context.max_prefix_chars)
  suffix = suffix:sub(1, config.options.context.max_suffix_chars)
  
  return {
    prefix = prefix,
    suffix = suffix,
    cursor = { line = line, col = col }
  }
end

return M