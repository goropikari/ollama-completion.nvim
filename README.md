# ollama-completion.nvim

Inline code completion plugin for Neovim. Provides real-time code completion using local LLMs (like Qwen2.5-Coder) via Ollama.

## Features

- **Local execution**: Uses Ollama, no external API keys required
- **Inline completion**: Displays suggested code in light blue at cursor position
- **Context-aware**: Sends code before and after cursor to generate contextually relevant completions
- **Customizable**: Configure completion trigger, context lines, model, and more

## Requirements

- Neovim 0.11+
- [Ollama](https://ollama.ai/) installed
- Code generation model like Qwen2.5-Coder
  - ref: <https://docs.continue.dev/ide-extensions/autocomplete/model-setup>

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'goropikari/ollama-completion.nvim',
  opts = {
    model = 'qwen2.5-coder:3b',
    debounce_ms = 500,
  },
}
```

## Configuration

Configure via lazy.nvim's `opts`. The `setup()` function is called automatically.

```lua
{
  'goropikari/ollama-completion.nvim',
  opts = {
    model = 'qwen2.5-coder:3b',     -- Model to use
    url = 'http://localhost:11434', -- Ollama URL
    accept_key = '<Tab>',           -- Key to accept completion
    debounce_ms = 500,              -- Delay before triggering completion (ms)
    context_lines_before = 50,      -- Lines before cursor to send as context
    context_lines_after = 50,       -- Lines after cursor to send as context
    highlight_color = '#808080',    -- Completion text color
    options = {
      temperature = 0.2,            -- Generation randomness
      top_p = 0.9,                  -- Top sampling
    },
  },
}
```

## Usage

1. While editing in insert mode, completion triggers automatically
2. Completion suggestions appear in light gray
3. Press the configured key (default: `<Tab>`) to accept completion
