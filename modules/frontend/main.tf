resource "aws_cloudfront_origin_access_identity" "oai" {
    comment = "OAI for Terraform Frontend"
}

resource "aws_s3_bucket" "terraform_front_bucket" {
    bucket = "terraform-frontend-bucket-max"
}

resource "aws_s3_bucket_policy" "terraform_front_bucket_policy" {
    bucket = aws_s3_bucket.terraform_front_bucket.bucket
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
                },
                Action = "s3:GetObject",
                Resource = "${aws_s3_bucket.terraform_front_bucket.arn}/*"
            }
        ]
    })
}

resource "aws_cloudfront_distribution" "terraform_front_distribution" {
    origin {
        domain_name = aws_s3_bucket.terraform_front_bucket.bucket_regional_domain_name
        origin_id = "S3-Frontend-Origin"

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
        }
    }

    enabled = true

    default_cache_behavior {
        target_origin_id = "S3-Frontend-Origin"
        viewer_protocol_policy = "redirect-to-https"
        
        allowed_methods = ["GET", "HEAD"]
        cached_methods = ["GET", "HEAD"]
        
        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    price_class = "PriceClass_100"

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }
}