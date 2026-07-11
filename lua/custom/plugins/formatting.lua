-- Formatting (LaTeX). Auto-imported by `{ import = 'custom.plugins' }` in init.lua.
-- latexindent ships with TeX Live. format-on-save is scoped to LaTeX only
-- (this intentionally does NOT enable global formatting, to keep behaviour
-- unchanged for other filetypes; extend `formatters_by_ft` as desired).
return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = { 'ConformInfo' },
    opts = {
      notify_on_error = false,
      formatters_by_ft = {
        tex = { 'latexindent' },
        latex = { 'latexindent' },
      },
      format_on_save = function(bufnr)
        local ft = vim.bo[bufnr].filetype
        if ft ~= 'tex' and ft ~= 'latex' then
          return nil
        end
        return { timeout_ms = 500, lsp_fallback = false }
      end,
    },
  },
}