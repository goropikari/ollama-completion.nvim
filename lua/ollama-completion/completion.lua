local llm = require('ollama-completion.llm')
local config = require('ollama-completion.config')

local uv = vim.uv

---@class OllamaCompletion
local M = {}

--- Namespace for virtual text
---@type integer
local ns_id = vim.api.nvim_create_namespace('ollama_completion')
--- Store current completion content
---@type string
local current_completion = ''
--- Debounce timer
---@type uv.uv_timer_t|nil
local timer = nil
--- Spinner animation timer
---@type uv.uv_timer_t|nil
local spinner_timer = nil
--- Spinner frames
---@type string[]
local spinner_frames = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }
--- Current spinner frame index
---@type integer
local spinner_index = 1
--- Whether spinner is currently showing
---@type boolean
local is_spinning = false
--- Current spinner extmark ID
---@type integer?
local spinner_extmark_id = nil

--- Clear current completion and virtual text
function M.clear()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  if spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
  end
  is_spinning = false
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  current_completion = ''
end

--- Start spinner animation
function M.start_spinner()
  if not config.options.show_spinner then
    return
  end
  M.stop_spinner()
  is_spinning = true
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1] - 1
  local col = cursor_pos[2]

  spinner_timer = uv.new_timer()
  spinner_timer:start(
    0,
    80,
    vim.schedule_wrap(function()
      if not is_spinning then
        return
      end
      local spinner = spinner_frames[spinner_index]
      spinner_extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, row, col, {
        virt_text = { { spinner, 'OllamaCompletion' } },
        virt_text_pos = 'inline',
        id = spinner_extmark_id,
      })
      spinner_index = (spinner_index % #spinner_frames) + 1
    end)
  )
end

--- Stop spinner animation
function M.stop_spinner()
  if spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
  end
  is_spinning = false
  spinner_extmark_id = nil
end

--- Get prefix and suffix around the cursor for LLM context
---@return string prefix, string suffix
function M.get_context()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  local col = cursor_pos[2]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local context_before = config.options.context_lines_before
  local context_after = config.options.context_lines_after

  -- Get prefix (before cursor)
  local prefix_lines = {}
  for i = math.max(1, row - context_before), row - 1 do
    table.insert(prefix_lines, lines[i] or '')
  end
  table.insert(prefix_lines, string.sub(lines[row] or '', 1, col))
  local prefix = table.concat(prefix_lines, '\n')

  -- Get suffix (after cursor)
  local suffix_lines = { string.sub(lines[row] or '', col + 1) }
  for i = row + 1, math.min(#lines, row + context_after) do
    table.insert(suffix_lines, lines[i] or '')
  end
  local suffix = table.concat(suffix_lines, '\n')

  return prefix, suffix
end

--- Trigger LLM generation for completion
function M.trigger()
  -- Only trigger completion if next character is whitespace
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  local col = cursor_pos[2]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local current_line = lines[row] or ''
  local next_char = string.sub(current_line, col + 1, col + 1)

  if next_char ~= '' and not string.match(next_char, '^%s$') then
    return
  end

  M.clear()
  local prefix, suffix = M.get_context()

  -- Start spinner immediately
  M.start_spinner()

  -- Pass prefix and suffix directly to llm.generate
  -- Prompt formatting is handled internally by llm.generate
  llm.generate(prefix, suffix, function(response)
    M.stop_spinner()
    M.display(response)
  end)
end

--- Display the completion response as virtual text
---@param completion string The text to display as virtual text
function M.display(completion)
  local mode = vim.api.nvim_get_mode().mode
  -- Only display in insert mode
  if mode ~= 'i' then
    return
  end

  M.clear()
  current_completion = completion
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1] - 1
  local col = cursor_pos[2]

  local lines = vim.split(completion, '\n')
  local first_line = lines[1]
  local virt_lines = {}
  -- Multi-line completion handling
  for i = 2, #lines do
    table.insert(virt_lines, { { lines[i], 'OllamaCompletion' } })
  end

  -- Set virtual text inline and as lines
  vim.api.nvim_buf_set_extmark(0, ns_id, row, col, {
    virt_text = { { first_line, 'OllamaCompletion' } },
    virt_text_pos = 'inline',
    virt_lines = virt_lines,
  })
end

--- Accept the current completion and insert it into the buffer
---@return boolean success True if completion was accepted, false otherwise
function M.accept()
  if current_completion == '' then
    return false
  end

  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  local col = cursor_pos[2]

  local lines = vim.split(current_completion, '\n')

  -- Use pcall for nvim_buf_set_text just in case
  local ok = pcall(vim.api.nvim_buf_set_text, 0, row - 1, col, row - 1, col, lines)
  if not ok then
    return false
  end

  -- Move cursor to the end of inserted text
  local new_row = row + #lines - 1
  local last_line_len = #lines[#lines]
  local new_col = #lines == 1 and col + last_line_len or last_line_len
  vim.api.nvim_win_set_cursor(0, { new_row, new_col })

  M.clear()
  return true
end

--- Setup autocommands for automatic completion triggering
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup('OllamaCompletion', { clear = true })

  -- Clear completion when leaving relevant modes or the buffer
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave', 'CmdlineEnter' }, {
    group = group,
    callback = function()
      M.clear()
    end,
  })

  -- Debounce completion triggering on cursor movement in insert mode
  vim.api.nvim_create_autocmd({ 'CursorMovedI' }, {
    group = group,
    callback = function()
      M.clear()

      timer = uv.new_timer()
      timer:start(
        config.options.debounce_ms,
        0,
        vim.schedule_wrap(function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == 'i' then
            M.trigger()
          end
        end)
      )
    end,
  })
end

return M
