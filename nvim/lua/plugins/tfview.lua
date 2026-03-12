return {
  {
    dir = "~/ghq/github.com/o8n/tfview",
    cmd = { "TerraformPlanTUI", "TerraformPlanSummary", "TerraformPlanRun" },
    opts = {
      binary = vim.fn.expand("~/.local/bin/tfview"),
    },
  },
}
