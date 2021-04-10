resource "aws_kms_key" "destkey" {
    provider                = aws.destination
    description             = "This key is used to encrypt dest bucket objects"
    deletion_window_in_days = 10
}

resource "aws_kms_alias" "dest"  {
    provider      = aws.destination
    name          = "alias/destkey"
    target_key_id = aws_kms_key.destkey.key_id
}

resource "aws_s3_bucket" "destination" {
    provider         = aws.destination
    acl              = "private"
    bucket_prefix    = var.bucket_prefix


    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id = aws_kms_key.destkey.arn
                sse_algorithm     = "aws:kms"
            }
        }
    }

    tags = {
        Env = var.env
    }
}