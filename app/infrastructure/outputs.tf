##########################
#### Trraform Outputs ####
##########################

output "base_url" {  
    description = "Base URL for API Gateway stage."
    value = aws_apigatewayv2_stage.lambda_stage_gateway.invoke_url
}
