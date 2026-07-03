-- Fake Dojo plugin commands for the VHS recording
vim.api.nvim_create_user_command('DojoStart', function(opts)
  if opts.args == 'sliding_window' then
    -- Open a split with the instructions
    vim.cmd('vsplit')
    vim.cmd('vertical resize 40')
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      '# Stage 3: The Complexity Trap',
      '',
      'Constraint: Find the longest substring of unique characters.',
      'Must run in exactly one pass. O(N) time strictly on massive adversarial inputs.',
    })
    vim.bo[buf].filetype = 'markdown'
    vim.cmd('wincmd p') -- switch back to the code window
    vim.cmd('edit Solution.kt')
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command('DojoValidate', function()
  -- Fake validation logic based on buffer contents
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  if content:find('while') then
    -- It has an inner while loop (the naive approach)
    -- Add virtual text for the error
    local ns_id = vim.api.nvim_create_namespace('dojo_demo')
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    
    -- Find the line with the while loop
    for i, line in ipairs(lines) do
      if line:find('while') then
        vim.api.nvim_buf_set_extmark(0, ns_id, i - 1, 0, {
          virt_text = {{' Senior Engineer: Your instruction count scaled quadratically. This will TLE on massive inputs. Jump the left pointer in O(1) instead.', 'ErrorMsg'}},
          virt_text_pos = 'eol',
        })
        break
      end
    end
  else
    -- Assuming they fixed it
    local ns_id = vim.api.nvim_create_namespace('dojo_demo')
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    
    -- Show success float or virtual text
    vim.api.nvim_buf_set_extmark(0, ns_id, #lines - 2, 0, {
      virt_text = {{' ✓ Stage 3 Cleared! Staff-level O(N) performance achieved.', 'String'}},
      virt_text_pos = 'eol',
    })
  end
end, {})

-- Remove intro message
vim.opt.shortmess:append('I')
-- Basic settings
vim.opt.number = true
vim.opt.termguicolors = true
