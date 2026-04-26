# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-04-26

### Fixed

- Insert suggestion at cursor position instead of end of line
- Strip suffix duplication when FIM models include text-after-cursor

## [0.1.0] - 2026-02-26

### Added

- Initial release of nvim-fim
- Provider-agnostic Fill-In-Middle (FIM) completion plugin
- Support for Mistral Codestral API
- Inline ghost text completions via extmarks
- Configurable context window (prefix/suffix lines and character limits)
- Multiple acceptance modes: full, word, and line
- Debounced requests for better performance
- Keymaps for accepting/dismissing suggestions
- Manual trigger with `<C-Space>`
- `:FimLogin` command to save API key
- Error notifications via `vim.notify_once`

[0.1.1]: https://github.com/aliou/nvim-fim/releases/tag/v0.1.1
[0.1.0]: https://github.com/aliou/nvim-fim/releases/tag/v0.1.0
