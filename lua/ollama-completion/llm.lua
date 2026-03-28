local config = require('ollama-completion.config')

local M = {}

-- Store current active process to cancel it if a new one starts
local current_process = nil

--- Call Ollama API to generate completion
---@param prompt string
---@param callback fun(response: string)
function M.generate(prompt, callback)
  -- Cancel previous process if it exists
  if current_process then
    current_process:kill()
    current_process = nil
  end

  local url = config.options.url .. '/api/generate'
  local data = {
    model = config.options.model,
    prompt = prompt,
    stream = false,
    raw = true,
    options = config.options.options,
  }

  local cmd = {
    'curl',
    '-s',
    '-X',
    'POST',
    url,
    '-d',
    vim.fn.json_encode(data),
    '-H',
    'Content-Type: application/json',
  }

  -- Start asynchronous process using vim.system
  current_process = vim.system(cmd, { text = true }, function(obj)
    current_process = nil
    if obj.code ~= 0 then
      vim.notify('Ollama error: ' .. (obj.stderr or 'unknown error'), vim.log.levels.ERROR)
      return
    end
    if not obj.stdout or obj.stdout == '' then
      return
    end

    local decoded = vim.json.decode(obj.stdout)
    if not decoded.response then
      vim.notify('Ollama response missing: ' .. obj.stdout, vim.log.levels.ERROR)
      return
    end

    local resp = decoded.response
    -- Basic code block extraction from the LLM response
    local code = resp:match('```[%w]*\n?(.-)```') or resp
    callback(code)
  end)
end

return M
