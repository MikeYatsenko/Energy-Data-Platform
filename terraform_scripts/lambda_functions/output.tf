output "LambdaSolar" {
  value       = aws_lambda_function.LambdaSolar.function_name
  description = "Lambda Solar function name"
}

output "LambdaNuclear" {
  value       = aws_lambda_function.LambdaNuclear.function_name
  description = "Lambda Solar function name"
}