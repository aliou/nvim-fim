# nvim-fim Agent Guide

## Build/Test Commands
- Run all tests: `nix-shell --run "busted"`
- Verbose tests: `nix-shell --run "busted --verbose"`
- Run specific spec: `nix-shell --run "busted test/spec/config_spec.lua"`
- Manual test: open nvim with `.nvim.lua` in project root
- CI: GitHub Actions runs on push/PR (see `.github/workflows/ci.yml`)

## Test Infrastructure
- **Framework**: Busted (Lua testing framework)
- **Runner**: `test/nvim-shim` (runs tests in headless Neovim)
- **Mocking**: Provider mocked via `package.loaded["fim.providers.codestral"]`
- **Coverage**: 44 tests across config, context, suggestion, and provider
- **No credentials needed**: All tests run with mocked providers

## Architecture
Neovim plugin (Lua) for provider-agnostic inline FIM completions.

### Module Structure (`lua/fim/`)
- `init.lua` - Entry point, `setup()`, autocommands, public API
- `config.lua` - Configuration defaults, validation, type definitions
- `context.lua` - Extract prefix/suffix from buffer
- `suggestion.lua` - State management (current suggestion, cursor pos, request ID)
- `render.lua` - Ghost text via extmarks
- `keymaps.lua` - Keymap setup and handlers
- `providers/` - Provider implementations
  - `init.lua` - Provider interface and registry
  - `codestral.lua` - Mistral Codestral API client

### Provider Interface
Providers must implement:
```lua
---@class FimProvider
---@field name string Provider identifier
---@field request_completion fun(prefix: string, suffix: string, callback: function)
---@field validate_config fun(config: table): boolean, string|nil
```

## Code Style
- LuaCATS annotations for types (`---@class`, `---@field`, `---@param`, `---@return`)
- Module pattern: `local M = {} ... return M`
- Imports at top, one per line: `local config = require('fim.config')`
- Use `vim.fn`, `vim.api`, `vim.schedule`, `vim.system` for Neovim APIs
- Error handling: `pcall()` for recoverable errors, `error()` for config validation
- Ghost text highlight group: `Comment`

## Configuration Structure

```lua
require('fim').setup({
  provider = 'codestral',  -- Which provider to use
  
  -- Provider-specific config
  codestral = {
    api_key_provider = function() return os.getenv("CODESTRAL_API_KEY") end,
    endpoint = "https://codestral.mistral.ai/v1/fim/completions",
    model = "codestral-latest",
    max_tokens = 256,
    stop = nil,
  },
  
  -- Universal config (applies to all providers)
  context = { ... },
  debounce_ms = 50,
  highlight = "Comment",
  keymaps = { ... },
  disabled_filetypes = {},
})
```

## Adding New Providers

To add a new provider (e.g., OpenAI, Anthropic):

1. Create `lua/fim/providers/newprovider.lua`
2. Implement the provider interface:
   ```lua
   local M = {}
   M.name = "newprovider"
   
   function M.validate_config(provider_config)
     -- Validate provider-specific config
     return true, nil
   end
   
   function M.request_completion(prefix, suffix, callback)
     -- Make API request
     -- Call callback(response, nil) on success
     -- Call callback(nil, error) on failure
   end
   
   return M
   ```
3. Add provider defaults to `fim/config.lua`
4. Add provider tests to `test/spec/providers/newprovider_spec.lua`
5. Update README with usage example

## Module Responsibilities

### Core Engine (`lua/fim/`)
Provider-agnostic functionality:
- Configuration validation
- Context extraction from buffers
- Suggestion state tracking (request IDs, cursor positions)
- Ghost text rendering via extmarks
- Keybinding handling
- Autocmd triggers and debouncing
- Filetype filtering

### Providers (`lua/fim/providers/`)
Provider-specific functionality:
- HTTP requests to provider APIs
- Request/response formatting
- API key management
- Error handling specific to provider
- Provider-specific configuration

## Testing Strategy
- Mock providers at the module level via `package.loaded`
- Test core engine logic independently of providers
- Test provider validation logic separately
- Avoid async tests (unreliable in Busted)
- Clear `package.loaded` in `before_each` for isolation
