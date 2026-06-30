-- Adds :MasonUpdateAll — upgrade every Mason-installed package to its
-- latest version.
--
-- Why this exists: :MasonUpdate only refreshes the package *registry*
-- (the catalog of what's available). It never reinstalls the tools you
-- already have. This command actually reinstalls installed packages whose
-- version is behind the registry's latest.
--
-- Safe to run headlessly, e.g.:
--   nvim --headless "+MasonUpdateAll" +qa
-- The headless path uses mason-core.async.run_blocking so the process does
-- not exit (via +qa) before the asynchronous installs finish.
local M = {}

-- Strip a leading "v" so "v1.2.3" compares equal to "1.2.3".
local function norm(v)
  return v and v:gsub('^v', '') or nil
end

local function run()
  local a = require('mason-core.async')
  local platform = require('mason-core.platform')
  local registry = require('mason-registry')

  local function report(msg, level)
    if platform.is_headless then
      vim.api.nvim_out_write(msg .. '\n')
    else
      vim.schedule(function()
        vim.notify(msg, level or vim.log.levels.INFO)
      end)
    end
  end

  return function()
    -- 1. Always fetch the newest registry metadata (like :MasonUpdate).
    a.wait(registry.update)
    -- Resume in a safe API context (the update callback runs in a fast event
    -- context where nvim API calls are not allowed).
    a.scheduler()

    -- 2. Collect installed packages whose installed version is behind the
    --    latest known version. Packages with an unknown version are treated
    --    as outdated so updates are never silently skipped.
    local to_update = {}
    for _, pkg in ipairs(registry.get_installed_packages()) do
      if not pkg:is_installing() then
        local ok, latest = pcall(pkg.get_latest_version, pkg)
        local installed = pkg:get_installed_version()
        if not ok or latest == nil or installed == nil or norm(installed) ~= norm(latest) then
          table.insert(to_update, pkg)
        end
      end
    end

    if #to_update == 0 then
      report('[mason] All installed packages are up to date.')
      return
    end

    -- 3. Reinstall each outdated package at its latest version. force=true
    --    bypasses stale lockfiles so a batch run is not blocked by one.
    local results = a.wait_all(vim.tbl_map(function(pkg)
      return function()
        return a.wait(function(resolve)
          local ok, handle = pcall(pkg.install, pkg, { force = true }, function(success, err)
            resolve({ success = success, name = pkg.name, err = err })
          end)
          if not ok then
            resolve({ success = false, name = pkg.name, err = handle })
          elseif handle then
            handle:on('stdout', vim.schedule_wrap(vim.api.nvim_out_write))
            handle:on('stderr', vim.schedule_wrap(vim.api.nvim_err_write))
          end
        end)
      end
    end, to_update))
    -- The install completion callbacks run in a fast event context; resume in
    -- a safe API context before reporting.
    a.scheduler()

    local ok_count, fail_count = 0, 0
    for _, r in ipairs(results) do
      if r and r.success then
        ok_count = ok_count + 1
      else
        fail_count = fail_count + 1
        local name = (r and r.name) or '?'
        report(('[mason] failed to update %s: %s'):format(name, tostring(r and r.err)))
      end
    end

    local msg = ('[mason] Updated %d package(s).'):format(ok_count)
    if fail_count > 0 then
      msg = msg .. (' %d failed.'):format(fail_count)
    end
    report(msg, fail_count > 0 and vim.log.levels.ERROR or vim.log.levels.INFO)
  end
end

function M.setup()
  vim.api.nvim_create_user_command('MasonUpdateAll', function()
    local platform = require('mason-core.platform')
    local a = require('mason-core.async')
    if platform.is_headless then
      -- Block until all installs finish so +qa does not cut them short.
      a.run_blocking(run())
    else
      -- Non-blocking in interactive Neovim: keep the UI responsive.
      a.run(run(), function() end)
    end
  end, {
    desc = 'Update all installed Mason packages to their latest versions.',
    force = true,
  })
end

return M