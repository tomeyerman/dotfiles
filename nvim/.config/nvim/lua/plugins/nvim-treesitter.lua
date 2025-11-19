return 
{
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  branch = 'main',
  build = ':TSUpdate',
  config = function()
    local langs = { 'lua', 'c_sharp', 'markdown', 'markdown-inline', 'bash', 'powershell' }

    require'nvim-treesitter'.install(langs)

    vim.api.nvim_create_autocmd('FileType', 
    {
      pattern = langs,
      callback = 
      function() 
        vim.treesitter.start() 
      end,
    })
  end
}