provider "aws" {
    region = "us-east-1"
    access_key = var.access_key
    secret_key = var.secret_key
    token      = var.token
}

resource "random_pet" "lambda_bucket_name" {
    prefix = "log8415-project-function"
    length = 4
}

###########################################
############ Code Packaging ###############
###########################################

data "archive_file" "lambda_sentiment_analysis" {  
    type        = "zip"
    depends_on  = [null_resource.install_python_dependencies]
    source_dir  = "${path.module}/sentiment-analysis-pkg"  
    output_path = "${path.module}/sentiment-analysis-pkg.zip"
}

resource "null_resource" "install_python_dependencies" {
    provisioner "local-exec" {
        command = "bash ${path.module}/create_dependencies_pkg.sh"

        environment = {
            source_code_path = "sentiment-analysis"
            function_name = "analyze_sentiment"
            path_module = path.module
            runtime = var.runtime
            path_cwd = path.cwd
        }
    }
}

###########################################
############ AWS Lambda Func ##############
###########################################

resource "aws_lambda_function" "sentiment_analysis" {  
    function_name = "analyze_sentiment"
    
    runtime = var.runtime
    handler = "sentiment-analysis.handler"
    role    = aws_iam_role.lambda_exec.arn
    
    depends_on = [null_resource.install_python_dependencies]
    source_code_hash = data.archive_file.lambda_sentiment_analysis.output_base64sha256
    filename = data.archive_file.lambda_sentiment_analysis.output_path
}

resource "aws_cloudwatch_log_group" "sentiment_analysis" {  
    name = "/aws/lambda/${aws_lambda_function.sentiment_analysis.function_name}"
    retention_in_days = 14
}

resource "aws_iam_role" "lambda_exec" {  
    name = "serverless_lambda"
    assume_role_policy = jsonencode({    
        Version = "2012-10-17"    
        Statement = [{      
            Action = "sts:AssumeRole"      
            Effect = "Allow"      
            Sid    = ""      
            Principal = {        
                Service = "lambda.amazonaws.com"      
            }      
        }]  
    })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {  
    role       = aws_iam_role.lambda_exec.name  
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###########################################
############ AWS API GAteway ##############
###########################################

resource "aws_apigatewayv2_api" "lambda_api_gateway" {  
    name          = "serverless_lambda_gateway"  
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda_stage_gateway" {  
    api_id = aws_apigatewayv2_api.lambda_api_gateway.id
    
    name        = "serverless_lambda_stage"  
    auto_deploy = true
    
    access_log_settings {    
        destination_arn = aws_cloudwatch_log_group.api_gw.arn
        format = jsonencode({      
            integrationErrorMessage = "$context.integrationErrorMessage"      
            sourceIp                = "$context.identity.sourceIp"      
            requestId               = "$context.requestId"      
            requestTime             = "$context.requestTime"      
            protocol                = "$context.protocol"      
            responseLength          = "$context.responseLength"      
            httpMethod              = "$context.httpMethod"      
            resourcePath            = "$context.resourcePath"      
            status                  = "$context.status"      
            routeKey                = "$context.routeKey"      
        })  
    }
}

resource "aws_apigatewayv2_integration" "sentiment_analysis" {  
    api_id = aws_apigatewayv2_api.lambda_api_gateway.id
    
    integration_uri    = aws_lambda_function.sentiment_analysis.invoke_arn  
    integration_type   = "AWS_PROXY"
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "sentiment_analysis" {  
    api_id = aws_apigatewayv2_api.lambda_api_gateway.id
    
    route_key = "GET /analyze-sentiment"  
    target    = "integrations/${aws_apigatewayv2_integration.sentiment_analysis.id}"
}

###########################################
############ Cloud Watch Log ##############
###########################################

resource "aws_cloudwatch_log_group" "api_gw" {  
    name = "/aws/api_gw/${aws_apigatewayv2_api.lambda_api_gateway.name}"
    retention_in_days = 14
}

resource "aws_lambda_permission" "api_gw" {  
    statement_id  = "AllowExecutionFromAPIGateway"  
    action        = "lambda:InvokeFunction"  
    function_name = aws_lambda_function.sentiment_analysis.function_name  
    principal     = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.lambda_api_gateway.execution_arn}/*/*"
}
