# nvim-fim

Provider-agnostic Fill-In-Middle (FIM) completion plugin for Neovim with inline ghost text.

> **Note:** This plugin was entirely vibe-coded as an experiment to explore Mistral's [Codestral FIM API](https://docs.mistral.ai/capabilities/code_generation/#fill-in-the-middle-endpoint). It's a playground for testing inline completion capabilities and the provider-agnostic architecture.

## Features

- Inline ghost text completions
- Fill-in-the-middle (FIM) support
- Provider-agnostic architecture (currently supports Mistral Codestral)
- Configurable context window
- Multiple acceptance modes (full, word, line)
- Debounced requests for better performance

## Installation

### Using lazy.nvim

```lua
{
  'aliou/nvim-fim',
  config = function()
    require('fim').setup({
      provider = 'codestral',
      codestral = {
        api_key_provider = function()
          return os.getenv("CODESTRAL_API_KEY")
        end,
      },
    })
  end
}
```

## Configuration

Full configuration with defaults:

```lua
require('fim').setup({
  -- Provider selection (required)
  provider = 'codestral',
  
  -- Provider-specific configuration
  codestral = {
    api_key_provider = function()
      return os.getenv("CODESTRAL_API_KEY")
    end,
    -- Free tier endpoint (requires phone-verified API key)
    endpoint = "https://codestral.mistral.ai/v1/fim/completions",
    -- Or use paid endpoint: "https://api.mistral.ai/v1/fim/completions"
    model = "codestral-latest",
    max_tokens = 256,
    stop = nil,
  },
  
  -- Universal settings (apply to all providers)
  context = {
    prefix_lines = 100,
    suffix_lines = 30,
    max_prefix_chars = 4000,
    max_suffix_chars = 1000,
  },
  debounce_ms = 50,
  highlight = "Comment",
  keymaps = {
    accept = "<Tab>",
    accept_word = "<C-Right>",
    accept_line = "<C-e>",
    dismiss = "<C-]>",
    trigger = "<C-Space>",
  },
  disabled_filetypes = {},
})
```

### Codestral API Key

**Free API Key:** Get a free Codestral API key at [console.mistral.ai](https://console.mistral.ai/). The free tier (`codestral.mistral.ai` endpoint) is designed for individual users and plugin developers. Phone verification is required.

For more details, see the [Codestral FIM documentation](https://docs.mistral.ai/capabilities/code_generation/#fill-in-the-middle-endpoint).

#### Option 1: Use `:FimLogin` command (easiest)

```vim
:FimLogin
```

This saves your key to `~/.local/share/nvim/fim/codestral/api_key` (the default location).

#### Option 2: Environment variable

```bash
export CODESTRAL_API_KEY="your-key-here"
```

```lua
codestral = {
  api_key_provider = function()
    return os.getenv("CODESTRAL_API_KEY")
  end,
}
```

#### Option 3: Custom file location

```lua
codestral = {
  api_key_provider = function()
    return vim.fn.readfile(vim.fn.expand("~/.secrets/codestral"))[1]
  end,
}
```

#### Option 4: Use default file location

By default, if you don't specify `api_key_provider`, it reads from:
```
~/.local/share/nvim/fim/codestral/api_key
```

Just create this file with your key, or use `:FimLogin` to set it up.

## Usage

- `<Tab>`: Accept full suggestion
- `<C-Right>`: Accept next word
- `<C-e>`: Accept to end of line  
- `<C-]>`: Dismiss suggestion
- `<C-Space>`: Trigger completion manually

## How It Works

```
Type in insert mode
  ↓
Debounced trigger (50ms)
  ↓
Extract context (prefix/suffix around cursor)
  ↓
Request completion from active provider
  ↓
Render ghost text via extmarks
  ↓
Accept (Tab), partial accept (C-Right/C-e), or dismiss (C-])
```

## Testing

Run tests with:
```bash
nix-shell --run "busted"
```

CI runs automatically on push/PR.

## Architecture

Provider-agnostic core engine with pluggable providers:

```
lua/fim/
├── init.lua           # Entry point, setup(), autocommands
├── config.lua         # Configuration management
├── context.lua        # Buffer context extraction
├── suggestion.lua     # State management
├── render.lua         # Ghost text rendering
├── keymaps.lua        # Keybindings
└── providers/         # Provider implementations
    ├── init.lua       # Provider interface/registry
    └── codestral.lua  # Mistral Codestral implementation
```

Future providers (OpenAI, Anthropic, DeepSeek, etc.) can be added by implementing the provider interface.

## References

Inspired by:
- [copilot.vim](https://github.com/github/copilot.vim) - Ghost text patterns
- [copilot.lua](https://github.com/zbirenbaum/copilot.lua) - Partial accept (word/line)
- [supermaven-nvim](https://github.com/supermaven-inc/supermaven-nvim) - Inline positioning

## License

MIT
