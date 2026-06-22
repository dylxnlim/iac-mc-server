terraform {
    backend "s3"{                                         #Remote Backend, use S3 as state storage
        bucket          = "mc-s3-bucket-dylxnlim"
        key             = "minecraft/terraform.tfstate"
        region          = "ap-southeast-1"
        use_lockfile     = true
        encrypt         = true
    }
}