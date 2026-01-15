-- Ghost text rendering for nvim-codestral
-- Uses extmarks to display inline suggestions

local config = require('fim.config')

local M = {}

--- Namespace for extmarks
M.ns_id = vim.api.nvim_create_namespace("fim")

--- Render a suggestion as ghost text
---@param suggestion string Suggestion text to render
function M.render_suggestion(suggestion)
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- Clear any existing suggestion
  M.clear_suggestion()
  
  -- Get cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1  -- Convert to 0-based index
  local col = cursor[2]
  
  -- Split suggestion into lines
  local lines = vim.split(suggestion, "\n", true)
  
  -- Handle first line (inline)
  local first_line = lines[1]
  local virt_text = {{first_line, config.options.highlight}}
  
  -- Choose positioning strategy:
  --   - "inline": Continuation from cursor (no text after cursor)
  --   - "eol": Text exists after cursor, show at end of line to avoid overlap
  local virt_text_pos = "inline"
  local text_after_cursor = vim.api.nvim_buf_get_text(bufnr, line, col, line, -1, {})[1]
  if text_after_cursor and text_after_cursor ~= "" then
    virt_text_pos = "eol"
  end
  
  -- Create extmark for first line
  -- Using fixed id=1 allows us to easily replace/clear the suggestion
  vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, line, col, {
    id = 1,
    virt_text = virt_text,
    virt_text_pos = virt_text_pos,
    hl_mode = "combine",
  })
  
  -- Handle additional lines (virt_lines)
  if #lines > 1 then
    local virt_lines = {}
    for i = 2, #lines do
      table.insert(virt_lines, {{lines[i], config.options.highlight}})
    end
    
    vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, line, col, {
      id = 1,
      virt_lines = virt_lines,
      virt_lines_above = false,
    })
  end
end

--- Clear the current suggestion
function M.clear_suggestion()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_del_extmark(bufnr, M.ns_id, 1)
end

return M