
locals {
  sftp_bucket_name = "governance-sftp-bucket"
  sftp_user_name   = "governance_sftp_user"

}

resource "aws_iam_role" "sftp_role" {
  name = "tf-test-transfer-server-iam-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "transfer.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sftp_policy" {
  name = "tf-test-transfer-server-iam-policy"
  role = aws_iam_role.sftp_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "arn:aws:s3:::${local.sftp_bucket_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:GetObjectVersion",
          "s3:GetObjectACL",
          "s3:PutObjectACL",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.sftp_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp_role.arn

  tags = {
    Name = "governance_sftp_server"
  }
}

resource "aws_s3_bucket" "sftp_bucket" {
  bucket = local.sftp_bucket_name
}

resource "aws_transfer_user" "sftp_user" {
  depends_on     = [aws_s3_bucket.sftp_bucket]
  server_id      = aws_transfer_server.sftp_server.id
  user_name      = local.sftp_user_name
  role           = aws_iam_role.sftp_role.arn
  home_directory = "/${local.sftp_bucket_name}"
}

resource "aws_transfer_ssh_key" "ssh_key" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user.user_name
  body      = file("${path.module}/files/sftp_key.pub")
}


