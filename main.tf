terraform {
  required_providers {
    wiz-v2 = {
      source  = "tf.app.wiz.io/wizsec/wiz-v2"
      version = ">= 1.0"
    }
  }
}

provider "wiz-v2" {}

data "wiz_integrations" "email" {
  first = 1
  name  = "email-integration"
}

locals {
  automation_rules = {
    "IssueAlert1" = {
      name        = "Critical Issue Alerts"
      description = "Alert security team when critical issues are created, reopened, or approaching due date"
      enabled     = true
      trigger_source = "ISSUES"
      trigger_type   = ["CREATED", "DUE", "REOPENED"]
      trigger_parameters = {
        due = {
          within_days = 3
        }
      }
      filters = jsonencode({
        project  = ["Consumer_folder"]
        severity = ["CRITICAL"]
        status   = ["OPEN", "IN_PROGRESS"]
      })
      action_template_type = "EMAIL"
      email_params = {
        attach_evidence_csv   = true
        subject               = "[Wiz critical issue update] - Issue: {{issue.control.name}}"
        note                  = <<-EOT
          The status of this security issue has been updated:
           Current Status: {{issue.status}}
           -------------
           Please verify that the new status accurately reflects the remediation progress and ensure proper follow-up where required.
        EOT
        cc                    = ["user@email.tld"]
        fallback_to           = ["user@email.tld"]
        template_variables_to = ["{{#issue.projects}}{{#projectOwners}}{{email}},{{/projectOwners}}{{/issue.projects}}"]
      }
    }
  }
}

resource "wiz-v2_automation_rule" "rules" {
  for_each = local.automation_rules

  name               = each.value.name
  description        = each.value.description
  enabled            = each.value.enabled
  trigger_source     = each.value.trigger_source
  trigger_type       = each.value.trigger_type
  trigger_parameters = each.value.trigger_parameters
  filters            = each.value.filters

  actions = [
    {
      integration          = data.wiz_integrations.email.integrations[0].id
      action_template_type = each.value.action_template_type
      action_template_params = {
        email_action_template_params = {
          attach_evidence_csv   = each.value.email_params.attach_evidence_csv
          subject               = each.value.email_params.subject
          note                  = each.value.email_params.note
          cc                    = each.value.email_params.cc
          fallback_to           = each.value.email_params.fallback_to
          template_variables_to = each.value.email_params.template_variables_to
        }
      }
    }
  ]
}

output "Integration_ID" {
  value = data.wiz_integrations.email.integrations[0].id
}
