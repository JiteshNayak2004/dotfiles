local ok, err = pcall(function()
  dofile(vim.env.TASKS_REPO .. '/nvim/plugin/tasks.lua')
  assert(vim.fn.exists(':TaskStatus') == 2, ':TaskStatus is missing')
  vim.cmd('Task navigation target')
  vim.cmd('Task future target @1d')
  local result = vim.system({ vim.fn.expand('~/.local/bin/task'), '--path' }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  local path = vim.trim(result.stdout)
  local disk = vim.fn.readfile(path)
  table.insert(disk, '9000. [ ] overdue target — 2020-01-01 09:00:00')
  vim.fn.writefile(disk, path)
  vim.wo.number = true
  vim.wo.cursorline = false
  vim.cmd('TaskStatus')
  local agenda = vim.api.nvim_get_current_buf()
  assert(vim.bo.buftype == 'nofile' and not vim.bo.modifiable and vim.bo.readonly, 'Agenda must be read-only and unsaved')
  assert(not vim.wo.number and vim.wo.cursorline, 'Agenda styling not applied')

  local function text()
    return table.concat(vim.api.nvim_buf_get_lines(agenda, 0, -1, false), '\n')
  end
  local function select(title)
    for i, line in ipairs(vim.api.nvim_buf_get_lines(agenda, 0, -1, false)) do
      if line:find(title, 1, true) then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        return
      end
    end
    error('Task missing from agenda: ' .. title)
  end
  local function key(lhs)
    local mapping = vim.fn.maparg(lhs, 'n', false, true)
    assert(type(mapping.callback) == 'function', 'Missing agenda mapping: ' .. lhs)
    mapping.callback()
  end

  assert(text():find('Overdue', 1, true) and text():find('Tomorrow', 1, true), 'Day grouping missing')
  select('navigation target')
  key('<CR>')
  assert(vim.api.nvim_get_current_buf() ~= agenda, 'Enter did not open source file')
  assert(vim.api.nvim_get_current_line():find('navigation target', 1, true), 'Enter opened wrong line')
  assert(vim.wo.number and not vim.wo.cursorline, 'Agenda changed source window options')
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { (vim.api.nvim_get_current_line():gsub('%[ %]', '[x]')) })
  vim.cmd('write')
  vim.cmd('normal! ' .. string.char(15))
  assert(vim.api.nvim_get_current_buf() == agenda, 'Ctrl-o did not return to agenda')
  assert(not text():find('navigation target', 1, true), 'Returning did not remove completed task')
  assert(table.concat(vim.fn.readfile(path), '\n'):find('[x] navigation target', 1, true), 'Completion was not saved in source')

  result = vim.system({ vim.fn.expand('~/.local/bin/task'), 'fresh task' }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  key('r')
  assert(text():find('fresh task', 1, true), 'Refresh did not pick up new tasks')
  vim.api.nvim_exec_autocmds('FocusGained', { buffer = agenda })
  result = vim.system({ vim.fn.expand('~/.local/bin/task'), 'focus refresh task' }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  vim.api.nvim_exec_autocmds('FocusGained', { buffer = agenda })
  assert(text():find('focus refresh task', 1, true), 'Focus refresh stopped after the first event')
  vim.cmd('TaskStatus')
  assert(vim.api.nvim_get_current_buf() == agenda, 'Repeated command created another agenda buffer')
  assert(vim.fn.glob(vim.env.TASKS_DIR .. '/*status*') == '', 'Agenda was saved as another task file')

  for _, file in ipairs(vim.fn.glob(vim.env.TASKS_DIR .. '/*.md', false, true)) do
    vim.fn.delete(file)
  end
  key('r')
  assert(text():find('No unfinished tasks', 1, true), 'Empty agenda message missing')
  key('q')
  assert(not vim.api.nvim_buf_is_valid(agenda), 'q did not close agenda')
  assert(vim.wo.number and not vim.wo.cursorline, 'Closing did not restore window options')
  print('PASS: read-only agenda, grouping, source navigation, Ctrl-o refresh, r, q, empty state, and window options')
end)
if not ok then print(err); vim.cmd('cquit 1') else vim.cmd('qa!') end
