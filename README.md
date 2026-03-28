# ollama-completion.nvim

A lightweight, local-first inline code completion plugin for Neovim. It provides real-time, context-aware suggestions using local LLMs (like Qwen2.5-Coder) via [Ollama](https://ollama.ai/).

## Features

- **Local & Private**: Powered by Ollama—no external APIs, keys, or data leaving your machine.
- **Context-Aware**: Utilizes code both before and after the cursor for smarter, Fill-In-the-Middle (FIM) completions.
- **Async & Fast**: Non-blocking requests using `vim.system` for a smooth typing experience.
- **Debounced Triggering**: Configurable delays to avoid excessive LLM calls while typing.
- **Fully Typed**: LuaLS (Lua Language Server) annotations for full configuration autocompletion and type safety.

## Requirements

- Neovim 0.11+
- [Ollama](https://ollama.ai/)
- A code-generation model (e.g., `qwen2.5-coder:3b`)
  - _Recommendation_: Use models optimized for Fill-In-the-Middle (FIM).

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'goropikari/ollama-completion.nvim',
  event = 'InsertEnter', -- Load only when entering Insert mode
  opts = {
    model = 'qwen2.5-coder:3b',
  },
}
```

## Configuration

The plugin uses sensible defaults, but you can override any setting via `opts`. The `setup()` function is automatically called by lazy.nvim.

```lua
{
  'goropikari/ollama-completion.nvim',
  opts = {
    model = 'qwen2.5-coder:3b',     -- Ollama model name
    url = 'http://localhost:11434', -- Ollama API endpoint
    accept_key = '<Tab>',           -- Key to accept the current suggestion
    debounce_ms = 500,              -- Wait time before calling LLM (ms)
    context_lines_before = 50,      -- Number of lines before cursor for context
    context_lines_after = 50,       -- Number of lines after cursor for context
    highlight_color = '#808080',    -- HEX color for virtual text (e.g., '#808080')

    -- Advanced Ollama/LLM options
    options = {
      temperature = 0.0,            -- Control randomness (0.0 = deterministic)
      top_p = 0.9,                  -- Nucleus sampling threshold
      stop = {                      -- Stop tokens to prevent excessive generation
        '<|fim_prefix|>',
        '<|fim_suffix|>',
        '<|fim_middle|>',
        '<|file_sep|>',
        '<|endoftext|>',
        '```',
      },
      num_predict = 64,             -- Max tokens to predict per request
    },

    -- Prompt template: Can be a string with %s placeholders or a function(prefix, suffix)
    prompt_template = function(prefix, suffix)
      return string.format('<|fim_prefix|>%s<|fim_suffix|>%s<|fim_middle|>', prefix, suffix)
    end,
  },
}
```

## Usage

1. **Trigger**: Suggestions appear automatically as you type in **Insert Mode** after the debounce period.
2. **Visual**: The suggestion is displayed as "virtual text" (ghost text) after the cursor.
3. **Accept**: Press your configured `accept_key` (default: `<Tab>`) to insert the suggestion into your buffer.
4. **Reject**: Continue typing or leave Insert Mode to clear the current suggestion.
