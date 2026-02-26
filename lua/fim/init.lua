-- Main module for nvim-fim
-- Provider-agnostic FIM completion plugin

local config = require('fim.config')
local context = require('fim.context')
local suggestion = require('fim.suggestion')
local render = require('fim.render')
local keymaps = require('fim.keymaps')

local M = {}

M.version = "0.1.0"

--- Setup the plugin with user configuration
---@param user_config table User configuration
function M.setup(user_config)
  -- Merge and validate configuration
  config.setup(user_config)
  
  -- Initialize suggestion state
  suggestion.setup()
  
  -- Setup autocommands for triggering completions
  M.setup_autocommands()
  
  -- Setup keymaps
  keymaps.setup()
  
  -- Setup login command if provider supports it
  M.setup_login_command()
  
  -- Validate provider is properly configured
  local providers = require('fim.providers')
  local provider = providers.get(config.options.provider)
  
  if provider and provider.validate_config then
    local ok, err = provider.validate_config(config.options[config.options.provider])
    if not ok then
      vim.notify("nvim-fim: " .. err, vim.log.levels.WARN)
    end
  end
end

--- Setup login command if provider supports it
function M.setup_login_command()
  local providers = require('fim.providers')
  local provider = providers.get(config.options.provider)
  
  if provider and provider.login then
    pcall(vim.api.nvim_create_user_command, "FimLogin", function()
      provider.login()
    end, { desc = "Save " .. config.options.provider .. " API key" })
  end
end

--- Setup autocommands for triggering completions
-- Handles edge cases:
--   - Only trigger in insert mode
--   - Don't interfere with nvim-cmp/blink.cmp popup menus
--   - Clear suggestions when leaving insert mode
--   - Debounce to avoid excessive API calls
function M.setup_autocommands()
  local debounced_trigger = vim.schedule_wrap(function()
    if vim.fn.mode() ~= 'i' then return end
    
    -- Don't trigger if completion menu is visible (nvim-cmp, etc.)
    -- Avoids ghost text appearing over the popup menu
    if vim.fn.pumvisible() == 1 then return end
    
    -- Get current context
    local ctx = context.get_current_context()
    if not ctx then return end
    
    -- Request completion
    suggestion.request_completion(ctx)
  end)
  
  -- Debounce function
  local debounce_timer = nil
  local function debounced_trigger_completion()
    if debounce_timer then
      vim.fn.timer_stop(debounce_timer)
    end
    debounce_timer = vim.fn.timer_start(config.options.debounce_ms, debounced_trigger)
  end
  
  -- Setup autocommands
  vim.api.nvim_create_autocmd({"TextChangedI", "CursorMovedI"}, {
    group = vim.api.nvim_create_augroup("Fim", { clear = true }),
    callback = debounced_trigger_completion
  })
  
  vim.api.nvim_create_autocmd({"InsertLeave"}, {
    group = vim.api.nvim_create_augroup("Fim", { clear = false }),
    callback = function()
      suggestion.clear_suggestion()
    end
  })
end

--- Manually trigger a completion request
function M.trigger_completion()
  if vim.fn.mode() ~= 'i' then return end
  local ctx = context.get_current_context()
  if ctx then
    suggestion.request_completion(ctx)
  end
end

--- Accept the current suggestion
function M.accept_suggestion()
  suggestion.accept_suggestion()
end

--- Accept the current suggestion up to the next word boundary
function M.accept_word()
  suggestion.accept_word()
end

--- Accept the current suggestion up to the end of the line
function M.accept_line()
  suggestion.accept_line()
end

--- Dismiss the current suggestion
function M.dismiss_suggestion()
  suggestion.clear_suggestion()
end

return M
