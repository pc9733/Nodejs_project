# =================================================================
# PARAMETER STORE MODULE OUTPUTS
# =================================================================

output "dev_parameter_arns" {
  description = "ARNs of dev environment parameters"
  value = var.environment == "dev" ? {
    db_password = try(aws_ssm_parameter.dev_db_password[0].arn, "")
    api_key     = try(aws_ssm_parameter.dev_api_key[0].arn, "")
    jwt_secret  = try(aws_ssm_parameter.dev_jwt_secret[0].arn, "")
  } : {}
}

output "prod_parameter_arns" {
  description = "ARNs of prod environment parameters"
  value = var.environment == "prod" ? {
    db_password = try(aws_ssm_parameter.prod_db_password[0].arn, "")
    api_key     = try(aws_ssm_parameter.prod_api_key[0].arn, "")
    jwt_secret  = try(aws_ssm_parameter.prod_jwt_secret[0].arn, "")
  } : {}
}

output "datadog_parameter_arns" {
  description = "ARNs of Datadog parameters"
  value = {
    api_key = try(aws_ssm_parameter.datadog_api_key[0].arn, "")
    app_key = try(aws_ssm_parameter.datadog_app_key[0].arn, "")
  }
}

output "parameter_prefix" {
  description = "Parameter Store path prefix"
  value       = "/${var.cluster_name}/${var.environment}"
}
