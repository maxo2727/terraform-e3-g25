terraform {
    backend "s3" {
        bucket = "my-terraform-state-bucket-max"
        key = "terraform.tfstate"
        region = "us-east-1"
        encrypt = true
        dynamodb_table = "terraform-lock"
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

module "backend" {
    source = "./modules/backend"
    ami = "ami-0e2c8caa4b6378d8c"
    instance_type = "t2.micro"
}

module "frontend" {
    source = "./modules/frontend"
}