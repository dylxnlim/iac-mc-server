resource "aws_s3_bucket" "mc-s3-terraformstate-dylxnlim" {
    bucket = "mc-s3-bucket-dylxnlim"

    lifecycle {
        prevent_destroy = true  #Stops accidental deletion of state file during terraform destroy
    }
}

resource "aws_s3_bucket_versioning" "mc-s3-terraformstate-dylxnlim-versioning" {
    bucket = aws_s3_bucket.mc-s3-terraformstate-dylxnlim.id
    versioning_configuration {
        status = "Enabled"         #Keeps history of every state file - reciverable
    }
}

resource "aws_s3_bucket_public_access_block" "mc-s3-terraformstate-dylxnlim-publicaccessblock" {
    bucket                      = aws_s3_bucket.mc-s3-terraformstate-dylxnlim.id
    block_public_acls           = true
    block_public_policy         = true
    ignore_public_acls          = true
    restrict_public_buckets     = true
}