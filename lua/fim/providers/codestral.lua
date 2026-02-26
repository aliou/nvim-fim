-- Mistral Codestral FIM provider
-- Handles requests to the Mistral Codestral API
--
-- Mistral FIM API endpoints:
--   - https://codestral.mistral.ai/v1/fim/completions (free tier, phone-verified key)
--   - https://api.mistral.ai/v1/fim/completions (paid tier, standard key)
--
-- Request format:
--   POST /v1/fim/completions
--   {
--     "model": "codestral-latest",
--     "prompt": "<code before cursor>",
--     "suffix": "<code after cursor>",
--     "max_tokens": 256,
--     "stop": ["optional", "stop", "tokens"]
--   }
--
-- Response format:
--   {
--     "choices": [
--       {
--         "message": {
--           "content": "<completion text>"
--         }
--       }
--     ]
--   }

local M = {}

M.name = "codestral"

--- Default path for storing Codestral API key
--- Structure: ~/.local/share/nvim/fim/PROVIDER/FILE
--- This allows each provider to have its own directory for credentials and config
---@return string
function M.default_api_key_path()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "fim", "codestral", "api_key")
end

--- Read API key from file
---@param path string File path
---@return string|nil
local function read_api_key_from_file(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local lines = vim.fn.readfile(path)
  if not lines or #lines == 0 then
    return nil
  end

  local key = vim.trim(table.concat(lines, "\n"))
  if key == "" then
    return nil
  end

  return key
end

--- Default API key provider (reads from default path)
---@return string|nil
function M.default_api_key_provider()
  return read_api_key_from_file(M.default_api_key_path())
end

--- Prompt for API key and save to file
---@param path string|nil Optional path (defaults to default_api_key_path)
function M.login(path)
  path = path or M.default_api_key_path()

  local input = vim.fn.inputsecret("Codestral API key: ")
  if not input or vim.trim(input) == "" then
    return
  end

  local dir = vim.fs.dirname(path)
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile({ vim.trim(input) }, path)

  vim.notify("Codestral API key saved to " .. path, vim.log.levels.INFO)
end

--- Validate Codestral-specific configuration
---@param provider_config table Provider configuration
---@return boolean, string|nil
function M.validate_config(provider_config)
  if not provider_config then
    return false, "codestral provider config is required"
  end

  if type(provider_config.api_key_provider) ~= "function" then
    return false, "codestral.api_key_provider must be a function"
  end

  if not provider_config.endpoint or provider_config.endpoint == "" then
    return false, "codestral.endpoint must be configured"
  end

  return true, nil
end

--- Make a request to the Mistral FIM API
---@param prefix string Code before cursor
---@param suffix string Code after cursor
---@param callback fun(response: table|nil, err: string|nil) Callback with response or error
function M.request_completion(prefix, suffix, callback)
  local config = require('fim.config')
  local provider_config = config.options.codestral

  -- Get API key
  local ok_key, api_key = pcall(provider_config.api_key_provider)
  if not ok_key then
    callback(nil, "api_key_provider error: " .. api_key)
    return
  end

  if not api_key or api_key == "" then
    callback(nil, "API key not configured")
    return
  end

  -- Prepare request body
  local body = {
    model = provider_config.model or "codestral-latest",
    prompt = prefix,
    suffix = suffix,
    max_tokens = provider_config.max_tokens or 256,
    stop = provider_config.stop,
  }

  -- Make HTTP request
  local ok, err = pcall(function()
    vim.system({
      "curl",
      "-s",
      "-X", "POST",
      provider_config.endpoint,
      "-H", "Content-Type: application/json",
      "-H", "Authorization: Bearer " .. api_key,
      "-d", vim.json.encode(body),
    }, { text = true }, function(obj)
      vim.schedule(function()
        if obj.code ~= 0 then
          callback(nil, "HTTP request failed: " .. (obj.stderr or "unknown error"))
          return
        end

        local ok, response = pcall(vim.json.decode, obj.stdout)
        if not ok then
          callback(nil, "Failed to parse JSON response")
          return
        end

        -- Check for API errors
        if response.error then
          callback(nil, "API error: " .. (response.error.message or "unknown error"))
          return
        end

        -- Validate response structure
        if not response.choices or #response.choices == 0 then
          callback(nil, "No completions in response")
          return
        end

        callback(response, nil)
      end)
    end)
  end)

  if not ok then
    callback(nil, "Failed to make request: " .. err)
  end
end

return M
