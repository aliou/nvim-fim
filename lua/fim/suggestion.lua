-- Suggestion state management for nvim-fim
-- Handles current suggestion and request tracking

local render = require('fim.render')
local config = require('fim.config')

local M = {}

---@class SuggestionState
---@field suggestion string|nil Current suggestion text
---@field cursor_pos {line:number, col:number} Position when requested
---@field request_id number Incremented per request, for stale detection
---@field bufnr number Buffer where suggestion is active

--- Current suggestion state
M.state = {
  suggestion = nil,
  cursor_pos = nil,
  request_id = 0,
  bufnr = nil,
}

--- Setup suggestion module
function M.setup()
  -- Clear state on buffer change
  vim.api.nvim_create_autocmd({"BufLeave"}, {
    group = vim.api.nvim_create_augroup("FimSuggestion", { clear = true }),
    callback = function()
      M.clear_suggestion()
    end
  })
end

--- Request a completion from the active provider
---@param ctx {prefix:string, suffix:string, cursor:{line:number, col:number}} Context for request
function M.request_completion(ctx)
  -- Get active provider
  local providers = require('fim.providers')
  local provider = providers.get(config.options.provider)
  
  if not provider then
    return
  end
  
  -- Increment request ID to track stale responses
  M.state.request_id = M.state.request_id + 1
  local current_request_id = M.state.request_id
  
  -- Store cursor position for validation
  M.state.cursor_pos = ctx.cursor
  M.state.bufnr = vim.api.nvim_get_current_buf()
  
  -- Make provider request
  provider.request_completion(ctx.prefix, ctx.suffix, function(response, err)
    -- Check if this response is stale
    if current_request_id ~= M.state.request_id then
      return
    end
    
    -- Check if we're still in insert mode
    if vim.fn.mode() ~= 'i' then
      M.clear_suggestion()
      return
    end
    
    -- Check if cursor position changed
    local current_cursor = vim.api.nvim_win_get_cursor(0)
    if current_cursor[1] - 1 ~= ctx.cursor.line or current_cursor[2] ~= ctx.cursor.col then
      M.clear_suggestion()
      return
    end
    
    if err then
      vim.notify_once("nvim-fim: " .. err, vim.log.levels.WARN)
      return
    end
    
    -- Extract completion from response
    local completion = response.choices[1].message.content
    if not completion or completion == "" then
      M.clear_suggestion()
      return
    end
    
    -- Store and render suggestion
    M.state.suggestion = completion
    render.render_suggestion(completion)
  end)
end

--- Clear the current suggestion
function M.clear_suggestion()
  M.state.suggestion = nil
  M.state.cursor_pos = nil
  M.state.bufnr = nil
  render.clear_suggestion()
end

--- Strip suffix duplication from suggestion first line.
--- Some FIM models include text-after-cursor in their completion.
--- If the first line of the suggestion ends with text-after-cursor, strip it.
---@param first_line string First line of the suggestion
---@param text_after_cursor string Text in the buffer after the cursor
---@return string stripped_line
function M.strip_suffix_dup(first_line, text_after_cursor)
  if text_after_cursor == "" or first_line == "" or #first_line < #text_after_cursor then
    return first_line
  end
  if first_line:sub(#first_line - #text_after_cursor + 1) == text_after_cursor then
    return first_line:sub(1, #first_line - #text_after_cursor)
  end
  return first_line
end

--- Accept the current suggestion
function M.accept_suggestion()
  if not M.state.suggestion or M.state.suggestion == "" then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1  -- 0-based
  local col = cursor[2]

  local lines = vim.split(M.state.suggestion, "\n", true)

  -- Strip suffix duplication: some FIM models include text after cursor
  -- in their completion. If first line ends with text-after-cursor, strip it.
  local text_after = vim.api.nvim_buf_get_text(bufnr, line, col, line, -1, {})[1] or ""
  lines[1] = M.strip_suffix_dup(lines[1], text_after)

  -- Use nvim_buf_set_text for reliable cursor positioning in insert mode
  -- nvim_put can insert at wrong position when in insert mode
  vim.api.nvim_buf_set_text(bufnr, line, col, line, col, lines)

  -- Move cursor to end of inserted text
  if #lines == 1 then
    vim.api.nvim_win_set_cursor(0, { line + 1, col + #lines[1] })
  else
    local last_line = lines[#lines]
    vim.api.nvim_win_set_cursor(0, { line + #lines, #last_line })
  end

  M.clear_suggestion()
end

--- Accept the current suggestion up to the next word boundary
function M.accept_word()
  if not M.state.suggestion or M.state.suggestion == "" then return end

  -- Find first word boundary
  local word_end = M.state.suggestion:find("[%s%p]")
  if not word_end then
    -- No word boundary found, accept entire suggestion
    M.accept_suggestion()
    return
  end

  -- Insert up to word boundary using nvim_buf_set_text
  local accepted = M.state.suggestion:sub(1, word_end)
  local remaining = M.state.suggestion:sub(word_end + 1)

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]

  local accepted_lines = vim.split(accepted, "\n", true)
  vim.api.nvim_buf_set_text(bufnr, line, col, line, col, accepted_lines)

  -- Move cursor to end of inserted text
  if #accepted_lines == 1 then
    vim.api.nvim_win_set_cursor(0, { line + 1, col + #accepted_lines[1] })
  else
    local last_line = accepted_lines[#accepted_lines]
    vim.api.nvim_win_set_cursor(0, { line + #accepted_lines, #last_line })
  end

  -- Update suggestion with remaining text
  M.state.suggestion = remaining
  if remaining == "" then
    M.clear_suggestion()
  else
    render.render_suggestion(remaining)
  end
end

--- Accept the current suggestion up to the end of the line
function M.accept_line()
  if not M.state.suggestion or M.state.suggestion == "" then return end

  -- Find first newline
  local line_end = M.state.suggestion:find("\n")
  if not line_end then
    -- No newline found, accept entire suggestion
    M.accept_suggestion()
    return
  end

  -- Insert up to newline using nvim_buf_set_text
  local accepted = M.state.suggestion:sub(1, line_end - 1)
  local remaining = M.state.suggestion:sub(line_end + 1)

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]

  vim.api.nvim_buf_set_text(bufnr, line, col, line, col, { accepted })
  vim.api.nvim_win_set_cursor(0, { line + 1, col + #accepted })

  -- Update suggestion with remaining text
  M.state.suggestion = remaining
  if remaining == "" then
    M.clear_suggestion()
  else
    render.render_suggestion(remaining)
  end
end

return M
