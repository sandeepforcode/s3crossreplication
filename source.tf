
resource "aws_kms_key" "srckey" {
    provider                = aws.source
    description             = "This key is used to encrypt source bucket objects"
    deletion_window_in_days = 10
}

resource "aws_kms_alias" "src"  {
    provider      = aws.source
    name          = "alias/src"
    target_key_id = aws_kms_key.srckey.key_id
}


resource "aws_iam_role" "s3replication" {
  provider    = aws.source
  name_prefix = "s3replication"
  description = "assume the role for the s3 replication"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
    {
      "Sid" = "s3ReplicationAssume",
      "Effect" = "Allow",
      "Principal" = {
        "Service" = "s3.amazonaws.com"
       },
      "Action" = "sts:AssumeRole"
    },
    ]
    })
}


resource "aws_iam_policy" "s3replication" {
  provider    = aws.source
  name_prefix = "s3replication"
  description = "Allows replications"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_kms_key.srckey.arn}"
      ]
    },
    {
      "Action": [
        "kms:Encrypt"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_kms_key.destkey.arn}"
      ]
    }
  ]
}
POLICY

}

resource "aws_iam_policy_attachment" "s3replication" {
  provider   = aws.source
  name       = "s3replication"
  roles      = [aws_iam_role.s3replication.name]
  policy_arn = aws_iam_policy.s3replication.arn
}

resource "aws_s3_bucket" "source" {
    provider         = aws.source
    acl             = "private"
    bucket_prefix   = var.bucket_prefix

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id = aws_kms_key.srckey.arn
                sse_algorithm     = "aws:kms"
            }
        }
    }

    replication_configuration {
        role = aws_iam_role.s3replication.arn
        rules {
            prefix = ""
            status = "Enabled"

             destination {
                bucket        = aws_s3_bucket.destination.arn
                replica_kms_key_id = aws_kms_key.destkey.arn
                storage_class = "STANDARD"
            }
            source_selection_criteria {
                sse_kms_encrypted_objects {
                    enabled = "true"
                }
            }
        }
        
    }

    tags = {
        Env = var.env
    }
}