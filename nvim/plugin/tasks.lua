-- The executable and this plugin are linked by tasks/install.sh.
local executable = vim.fn.expand('~/.local/bin/task')
local data_home = vim.env.XDG_DATA_HOME or (vim.env.HOME .. '/.local/share')
local root = vim.fs.normalize(vim.env.TASKS_DIR or (data_home .. '/tasks'))
local status_buf
local refresh_status

local function is_task_buffer(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  return vim.fs.dirname(path) == root and vim.fs.basename(path):match('^%d%d%d%d%-%d%d%-%d%d%.md$')
end

local function disk_hash(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if vim.fn.filereadable(path) == 0 then return nil end
  return vim.fn.sha256(table.concat(vim.fn.readfile(path, 'b'), '\n'))
end

local function remember(buf)
  if is_task_buffer(buf) then
    vim.bo[buf].autoread = true
    vim.b[buf].tasks_disk_hash = disk_hash(buf)
  end
end

local function run(args)
  if vim.fn.executable(executable) == 0 then
    vim.notify('Install the task tool with dotfiles/tasks/install.sh first.', vim.log.levels.ERROR)
    return nil
  end
  local result = vim.system(vim.list_extend({ executable }, args), { text = true }):wait(10000)
  if result.code ~= 0 then
    vim.notify(vim.trim(result.stderr or result.stdout or 'Task command failed.'), vim.log.levels.ERROR)
    return nil
  end
  return vim.trim(result.stdout or '')
end

local function change_task(args)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_task_buffer(buf) and vim.bo[buf].modified then
      vim.notify('Save your task checklist edits before changing tasks from the agenda.', vim.log.levels.WARN)
      return nil
    end
  end
  local message = run(args)
  if message then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and is_task_buffer(buf) then
        vim.api.nvim_buf_call(buf, function() vim.cmd('checktime') end)
      end
    end
  end
  return message
end

vim.api.nvim_create_user_command('Task', function(opts)
  if opts.args ~= '' then
    local message
    if vim.trim(opts.args):sub(1, 1) == '@' then
      message = change_task({ opts.args })
    else
      message = run({ opts.args })
    end
    if message then
      vim.notify(message)
      if vim.api.nvim_get_current_buf() == status_buf then refresh_status() end
    end
  else
    local path = run({ '--path' })
    if path and path ~= '' then
      root = vim.fs.dirname(path)
      vim.cmd.edit(vim.fn.fnameescape(path))
      remember(vim.api.nvim_get_current_buf())
    end
  end
end, { nargs = '*', desc = 'Add a task, reschedule with @ID @time, or open today’s checklist' })

local group = vim.api.nvim_create_augroup('DotfilesTasks', { clear = true })
vim.api.nvim_create_autocmd({ 'BufReadPost', 'FileChangedShellPost' }, {
  group = group,
  callback = function(event)
    if event.event ~= 'FileChangedShellPost' or not vim.bo[event.buf].modified then
      remember(event.buf)
    end
  end,
})
vim.api.nvim_create_autocmd('BufWritePre', {
  group = group,
  callback = function(event)
    if is_task_buffer(event.buf) and disk_hash(event.buf) ~= vim.b[event.buf].tasks_disk_hash then
      error('Tasks changed on disk (possibly from a notification). Save your edits elsewhere, reload with :edit!, then reapply them.')
    end
  end,
})
vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  callback = function(event)
    if not is_task_buffer(event.buf) then return end
    remember(event.buf)
    if run({ '--sync' }) then
      if disk_hash(event.buf) ~= vim.b[event.buf].tasks_disk_hash then
        -- :checktime defers reloads inside autocommands; reload this just-saved buffer now.
        vim.api.nvim_buf_call(event.buf, function()
          local view = vim.fn.winsaveview()
          vim.cmd('silent keepalt edit!')
          vim.fn.winrestview(view)
        end)
      end
      remember(event.buf)
    end
  end,
})
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  group = group,
  callback = function(event)
    if is_task_buffer(event.buf) and not vim.bo[event.buf].modified then
      vim.api.nvim_buf_call(event.buf, function() vim.cmd('checktime') end)
    end
  end,
})

local status_rows = {}
local status_namespace = vim.api.nvim_create_namespace('DotfilesTaskStatus')
local status_window_options = {}

refresh_status = function()
  local output = run({ '--upcoming' })
  if not output then return false end
  local ok, agenda = pcall(vim.json.decode, output)
  if not ok then
    vim.notify('Could not read the task agenda.', vim.log.levels.ERROR)
    return false
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local selected = status_rows[cursor[1]]
  local lines, highlights, rows = {}, {}, {}
  local function append(text, highlight)
    lines[#lines + 1] = text
    if highlight then highlights[#highlights + 1] = { #lines - 1, highlight } end
  end
  append('Upcoming · next 7 days', 'Title')
  append('')
  for _, section in ipairs(agenda.groups) do
    append(section.label, section.key == 'overdue' and 'DiagnosticError' or 'Title')
    for _, task in ipairs(section.tasks) do
      local left = string.format('  %d  %s', task.id, task.title)
      local column = math.max(32, math.min(64, vim.api.nvim_win_get_width(0) - 22))
      append(left .. string.rep(' ', math.max(2, column - vim.fn.strdisplaywidth(left))) .. task.time)
      rows[#lines] = task
      if section.key == 'overdue' then
        highlights[#highlights + 1] = { #lines - 1, 'DiagnosticWarn' }
      end
    end
    append('')
  end
  if #agenda.groups == 0 then
    append('No unfinished tasks in the next seven days.', 'Comment')
    append('')
  end
  append('Enter: open   x: done   dd: delete   r: refresh   q: close', 'Comment')
  append(':Task @ID @10m  reschedule (also @1d 10:00, @2h)', 'Comment')
  vim.bo[status_buf].readonly = false
  vim.bo[status_buf].modifiable = true
  vim.api.nvim_buf_set_lines(status_buf, 0, -1, false, lines)
  vim.bo[status_buf].modified = false
  vim.bo[status_buf].modifiable = false
  vim.bo[status_buf].readonly = true
  vim.api.nvim_buf_clear_namespace(status_buf, status_namespace, 0, -1)
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(status_buf, status_namespace, highlight[2], highlight[1], 0, -1)
  end
  status_rows = rows
  local target = math.min(cursor[1], #lines)
  if selected then
    for line, task in pairs(rows) do
      if task.id == selected.id then target = line; break end
    end
  end
  vim.api.nvim_win_set_cursor(0, { target, 0 })
  return true
end

local function open_status_task()
  local selected = status_rows[vim.api.nvim_win_get_cursor(0)[1]]
  if not selected or not refresh_status() then return end
  local current
  for _, task in pairs(status_rows) do
    if task.id == selected.id then current = task; break end
  end
  if not current then
    vim.notify('That task is no longer in the upcoming view.')
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(current.path))
  if not vim.bo.modified then vim.cmd('checktime') end
  for line, text in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if text:match('^%s*' .. current.id .. '%.%s*%[[ xX]%]') then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      vim.cmd('normal! zz')
      return
    end
  end
  vim.notify('The task moved while opening it; refresh the agenda.', vim.log.levels.WARN)
end

local function status_action(action)
  local selected = status_rows[vim.api.nvim_win_get_cursor(0)[1]]
  if not selected then return end
  if action == 'delete' then
    local choice = vim.fn.confirm(string.format('Delete task #%d: %s?', selected.id, selected.title), '&Delete\n&Cancel', 2)
    if choice ~= 1 then return end
  end
  local message = change_task({ '--' .. action, tostring(selected.id) })
  if message then
    vim.notify(message)
    refresh_status()
  end
end

vim.api.nvim_create_user_command('TaskStatus', function()
  if not status_buf or not vim.api.nvim_buf_is_valid(status_buf) then
    status_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(status_buf, 'task://status')
    vim.bo[status_buf].buftype = 'nofile'
    vim.bo[status_buf].bufhidden = 'hide'
    vim.bo[status_buf].swapfile = false
    vim.bo[status_buf].readonly = true
    vim.bo[status_buf].modifiable = false
    status_rows = {}
    vim.keymap.set('n', '<CR>', open_status_task, { buffer = status_buf, desc = 'Open original task' })
    vim.keymap.set('n', 'x', function() status_action('done') end, { buffer = status_buf, desc = 'Mark task done' })
    vim.keymap.set('n', 'dd', function() status_action('delete') end, { buffer = status_buf, desc = 'Delete task' })
    vim.keymap.set('n', 'r', refresh_status, { buffer = status_buf, desc = 'Refresh agenda' })
    vim.keymap.set('n', 'q', function() vim.api.nvim_buf_delete(status_buf, {}) end, { buffer = status_buf, desc = 'Close agenda' })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group, buffer = status_buf,
      callback = function()
        local win = vim.api.nvim_get_current_win()
        local options = { number = false, relativenumber = false, cursorline = true, signcolumn = 'no', wrap = false }
        if not status_window_options[win] then
          status_window_options[win] = {}
          for option, value in pairs(options) do
            status_window_options[win][option] = vim.wo[win][option]
            vim.wo[win][option] = value
          end
        end
        refresh_status()
      end,
    })
    vim.api.nvim_create_autocmd('BufLeave', {
      group = group, buffer = status_buf,
      callback = function()
        local win = vim.api.nvim_get_current_win()
        for option, value in pairs(status_window_options[win] or {}) do
          vim.wo[win][option] = value
        end
        status_window_options[win] = nil
      end,
    })
    vim.api.nvim_create_autocmd('FocusGained', {
      group = group, buffer = status_buf, callback = function() refresh_status() end,
    })
  end
  if vim.api.nvim_get_current_buf() == status_buf then
    refresh_status()
  else
    vim.api.nvim_set_current_buf(status_buf)
  end
end, { desc = 'Browse overdue and upcoming tasks' })
