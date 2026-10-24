local CRD = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/"
local function crd(path) return CRD .. path end

-- Schemas for Flux and other CRDs, matched by file naming convention.
local flux_schemas = {
  [crd("kustomize.toolkit.fluxcd.io/kustomization_v1.json")]      = { "**/ks.yaml", "**/kustomization-flux.yaml" },
  [crd("helm.toolkit.fluxcd.io/helmrelease_v2.json")]             = { "**/helmrelease.yaml", "**/hr.yaml" },
  [crd("source.toolkit.fluxcd.io/gitrepository_v1.json")]         = "**/gitrepository.yaml",
  [crd("source.toolkit.fluxcd.io/helmrepository_v1.json")]        = "**/helmrepository.yaml",
  [crd("source.toolkit.fluxcd.io/ocirepository_v1.json")]         = "**/ocirepository.yaml",
  [crd("notification.toolkit.fluxcd.io/alert_v1beta3.json")]      = "**/alert.yaml",
  [crd("notification.toolkit.fluxcd.io/provider_v1beta3.json")]   = "**/provider.yaml",
  [crd("cert-manager.io/clusterissuer_v1.json")]                  = "**/clusterissuer*.yaml",
  [crd("cert-manager.io/certificate_v1.json")]                    = "**/certificate*.yaml",
  [crd("monitoring.coreos.com/prometheusrule_v1.json")]           = "**/prometheusrule*.yaml",
  [crd("monitoring.coreos.com/servicemonitor_v1.json")]           = "**/servicemonitor*.yaml",
  [crd("volsync.backube/replicationsource_v1alpha1.json")]        = "**/replicationsource*.yaml",
  [crd("gateway.networking.k8s.io/httproute_v1.json")]            = { "**/httproute*.yaml", "**/route.yaml" },
  [crd("gateway.networking.k8s.io/gateway_v1.json")]              = "**/gateway.yaml",
}

return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
  },

  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  { "towolf/vim-helm", ft = "helm" },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason.nvim", "SchemaStore.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      if vim.fn.has("nvim-0.11") == 0 then
        vim.notify("needs nvim 0.11+ (have " .. tostring(vim.version()) .. ")",
          vim.log.levels.ERROR)
        return
      end

      local caps = vim.tbl_deep_extend("force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities())

      vim.lsp.config("yamlls", {
        capabilities = caps,
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = vim.tbl_extend("force",
              require("schemastore").yaml.schemas(),
              flux_schemas,
              {
                kubernetes = { "kubernetes/**/*.yaml" },
              }),
            validate = true,
            completion = true,
            hover = true,
            format = { enable = false },
            keyOrdering = false,
          },
          redhat = { telemetry = { enabled = false } },
        },
      })

      vim.lsp.config("bashls", { capabilities = caps })
      vim.lsp.config("lua_ls", {
        capabilities = caps,
        settings = { Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        } },
      })
      vim.lsp.config("jsonls", {
        capabilities = caps,
        settings = { json = {
          schemas = require("schemastore").json.schemas(),
          validate = { enable = true },
        } },
      })

      vim.lsp.enable({ "yamlls", "bashls", "lua_ls", "jsonls" })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("homelab-lsp", { clear = true }),
        callback = function(ev)
          local function m(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          m("gd", vim.lsp.buf.definition,  "Go to definition")
          m("gr", vim.lsp.buf.references,  "References")
          m("K",  vim.lsp.buf.hover,       "Hover")
          m("<leader>rn", vim.lsp.buf.rename, "Rename")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })

      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●" },
        severity_sort = true,
        float = { border = "rounded", source = true },
        signs = { text = {
          [vim.diagnostic.severity.ERROR] = "✘",
          [vim.diagnostic.severity.WARN]  = "▲",
          [vim.diagnostic.severity.HINT]  = "⚑",
          [vim.diagnostic.severity.INFO]  = "»",
        } },
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format" },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        json = { "jq" },
        -- No format-on-save for YAML; it reorders manifests and makes noisy diffs.
      },
      format_on_save = function(buf)
        if vim.bo[buf].filetype == "yaml" then return nil end
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end,
      formatters = { shfmt = { prepend_args = { "-i", "2", "-ci" } } },
    },
  },
}
