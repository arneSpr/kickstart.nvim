-- LaTeX / scientific-writing plugins.
-- Auto-imported by `{ import = 'custom.plugins' }` in init.lua.
-- Toolchain: TeX Live full (latexmk/pdflatex/biber/latexindent) + zathura viewer.
return {
  -- VimTeX: LaTeX language integration — compile (latexmk), view (zathura),
  -- SyncTeX forward/backward search, table of contents, motion, text objects,
  -- conceal (math), and its own syntax (:h vimtex-faq-treesitter, so the
  -- `latex` treesitter parser is intentionally NOT started for .tex).
  {
    'lervag/vimtex',
    branch = 'master',
    lazy = false, -- needs early filetype/conceal setup; config is cheap
    init = function()
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_compiler_method = 'latexmk'
      -- Don't auto-open quickfix on compile; use <leader>le to inspect errors.
      vim.g.vimtex_quickfix_mode = 0
      -- VimTeX owns syntax (treesitter start() is skipped for tex/plaintex/latex).
      vim.g.vimtex_syntax_enabled = 1
      vim.g.tex_flavor = 'latex'
    end,
    ft = { 'tex', 'plaintex', 'bib' },
  },

  -- Castel-style math snippets with auto-expansion (e.g. `//` -> fraction),
  -- math-mode aware via vimtex. Also usable in markdown (allow_on_markdown).
  {
    'iurimateus/luasnip-latex-snippets.nvim',
    lazy = true,
    ft = { 'tex', 'plaintex', 'markdown' },
    dependencies = { 'lervag/vimtex', 'L3MON4D3/LuaSnip' },
    opts = { use_treesitter = false, allow_on_markdown = true },
    config = function(_, opts)
      require('luasnip-latex-snippets').setup(opts)
    end,
  },
}