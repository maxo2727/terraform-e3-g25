resource "aws_security_group" "TerraformSecurityGroup" {
    name = "TerraformSecurityGroup"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "TerraformInstance" {
    ami = var.ami
    instance_type = var.instance_type
    security_groups = [aws_security_group.TerraformSecurityGroup.name]
    tags = {
        Name = "TerraformInstance"
    }
}

resource "aws_eip" "TerraformEIP" {
    instance = aws_instance.TerraformInstance.id
}

resource "aws_eip_association" "TerraformEIPAssociation" {
    instance_id = aws_instance.TerraformInstance.id
    allocation_id = aws_eip.TerraformEIP.id
}

output "elastic_ip" {
    value = aws_eip.TerraformEIP.public_ip
}

resource "aws_s3_bucket" "TerraformBucket" {
    bucket = "my-unique-terraform-bucket-max"
    tags = {
        Name = "TerraformBucket"
    }
}

resource "aws_s3_bucket_versioning" "TerraformBucketVersioning" {
    bucket = aws_s3_bucket.TerraformBucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_lambda_function" "TerraformLambda" {
    function_name = "TerraformLambda"
    runtime = "python3.8"
    handler = "lambda_function.lambda_handler"
    filename = "lambda_function.zip"
    role = "arn:aws:iam::054037128048:role/TerraformLambdaRole"
}

resource "aws_api_gateway_rest_api" "TerraformAPI" {
    name = "TerraformAPI"
    description = "TerraformAPI example for e3 jeje"
}

resource "aws_api_gateway_resource" "TerraformAPI_WenasResource" {
    rest_api_id = aws_api_gateway_rest_api.TerraformAPI.id
    parent_id = aws_api_gateway_rest_api.TerraformAPI.root_resource_id
    path_part = "wenas"
}

resource "aws_api_gateway_method" "TerraformAPI_WenasMethod" {
    rest_api_id = aws_api_gateway_rest_api.TerraformAPI.id
    resource_id = aws_api_gateway_resource.TerraformAPI_WenasResource.id
    http_method = "GET"
    authorization = "NONE" 
}

resource "aws_api_gateway_integration" "TerraformAPI_WenasIntegration" {
    rest_api_id = aws_api_gateway_rest_api.TerraformAPI.id
    resource_id = aws_api_gateway_resource.TerraformAPI_WenasResource.id
    http_method = aws_api_gateway_method.TerraformAPI_WenasMethod.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.TerraformLambda.invoke_arn
}

resource "aws_lambda_permission" "TerraformLambdaPermission" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.TerraformLambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.TerraformAPI.execution_arn}/*/*"
}