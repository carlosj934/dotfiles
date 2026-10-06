-- Format on save
return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  ---@module 'conform'
  ---@type conform.setupOpts
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_fix', 'ruff_format' },
      go = { 'goimports', 'gofumpt' },
      html = { 'prettier' },
      json = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
      terraform = { 'terraform_fmt' },
      hcl = { 'terraform_fmt' },
    },
    default_format_opts = {
      lsp_format = 'fallback',
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = 'fallback',
    },
    formatters = {
      shfmt = {
        append_args = { '-i', '4' },
      },
      -- Extend the rule selection with import sorting, since `ruff_organize_imports` would replace it and stop removing unused imports.
      ruff_fix = {
        append_args = { '--extend-select', 'I' },
      },
    },
  },
}
