local ok, err = pcall(function()
  dofile(vim.env.TASKS_REPO .. '/nvim/plugin/tasks.lua')
  assert(vim.fn.exists(':Task') == 2, ':Task is missing')
  vim.cmd('Task integration check')
  vim.cmd('Task seconds check @300s')
  vim.cmd('Task')
  local path = vim.api.nvim_buf_get_name(0)
  assert(vim.fs.dirname(path) == vim.env.TASKS_DIR, ':Task did not open today’s file')
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'):find('integration check', 1, true))

  vim.api.nvim_buf_set_lines(0, -1, -1, false, { '[ ] manually added @1d 10:00' })
  vim.cmd('write')
  local all = ''
  for _, file in ipairs(vim.fn.glob(vim.env.TASKS_DIR .. '/*.md', false, true)) do
    all = all .. table.concat(vim.fn.readfile(file), '\n')
  end
  assert(all:find('manually added', 1, true), 'Saved task was not ingested')
  assert(all:find('seconds check — ', 1, true), '@300s did not create a reminder')
  assert(not table.concat(vim.fn.readfile(path), '\n'):find('manually added', 1, true), 'Tomorrow’s task stayed in today’s file')

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:find('integration check', 1, true) then
      lines[i] = line:gsub('%[ %]', '[x]')
    end
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd('write')
  assert(table.concat(vim.fn.readfile(path), '\n'):find('[x] integration check', 1, true), 'Checkbox edit was lost')

  -- Simulate a notification updating disk while this buffer has an unsaved edit.
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { '[ ] unsaved local edit' })
  local disk = vim.fn.readfile(path)
  table.insert(disk, '999. [ ] changed by a notification')
  vim.fn.writefile(disk, path)
  local baseline = vim.b.tasks_disk_hash
  vim.api.nvim_exec_autocmds('FileChangedShellPost', { buffer = 0 })
  assert(vim.b.tasks_disk_hash == baseline, 'External change hid the unsaved-buffer conflict')
  local wrote = pcall(vim.cmd, 'write!')
  assert(not wrote, 'Stale task buffer overwrote a newer disk version')
  assert(table.concat(vim.fn.readfile(path), '\n'):find('changed by a notification', 1, true), 'Disk update was lost')
  print('PASS: Neovim capture, open, manual additions, checkbox completion, and stale-write protection')
end)
if not ok then
  print(err)
  vim.cmd('cquit 1')
else
  vim.cmd('qa!')
end
