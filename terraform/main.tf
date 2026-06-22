#Resource Provisioning
provider "aws" {
    region = var.aws-region
}

resource "aws_eip" "mc-eip" {
    domain = "vpc"
}

resource "aws_security_group" "mc-securitygroup" {
    name        = "mc-sg"
    description = "Minecraft Server Security Group"
    vpc_id      = aws_vpc.mc-vpc.id

    ingress {
        description = "Minecraft Game Port"
        from_port   = 25565         #Minecraft's Port
        to_port     = 25565
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] #All Internet so anyone can join
    }

    ingress {
        description = "SSH from my IP only"
        from_port   = 22                   #SSH Port
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]  #Only Developers can SSH to server
    }

    egress {
        from_port = 0                #All Ports can send data out to the Internet
        to_port   = 0
        protocol  = "-1"             #All Protocols can send data out to the Internet
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "mc-instance" {
    ami                    = "ami-0dfb1c86c34509daf" #Amazon Linux 2023 AMI, Hardcoded for free-tier. Best practice to use Terraform Data Source
    instance_type          = "t3.micro"
    key_name               = var.key_pair_name
    subnet_id              = aws_subnet.mc-vpc-subnet-public.id
    vpc_security_group_ids = [aws_security_group.mc-securitygroup.id]
    iam_instance_profile   = aws_iam_instance_profile.mc-iam-instanceprofile.name

    root_block_device {
        volume_size = 20    #GB, enough for world saves
    }

    tags = {
        Name = "mc-server"
    }
}

#Associate/Attach Elastic IP to Instance
resource "aws_eip_association" "mc-eip-association" {
    instance_id   = aws_instance.mc-instance.id
    allocation_id = aws_eip.mc-eip.id
}

#Route53 record pointing to EIP. Use if have domain registered
# resource "aws_route53_record" "mc-route53-record" {
#     zone_id = "HOSTED_ZONE_ID"              #Replace after creating hosted zone in Route53
#     name    = "mc"                          #Subdomain
#     type    = "A"                           #Address DNS Record
#     ttl     = 300
#     records = [aws_eip.mc-eip.public_ip]    
# }

resource "aws_vpc" "mc-vpc" {
    cidr_block              = "10.0.0.0/16"
    enable_dns_hostnames    = true
    enable_dns_support      = true

    tags = { Name = "mc-vpc" }
}

resource "aws_subnet" "mc-vpc-subnet-public" {
    vpc_id                          = aws_vpc.mc-vpc.id
    cidr_block                      = "10.0.1.0/24"
    availability_zone               = "ap-southeast-1a"
    map_public_ip_on_launch         = true

    tags = { Name = "mc-vpc-subnet-public" }
}

#Reserved for RDS instances, Internal services or any resource that should not be directly reachable from the internet.
resource "aws_subnet" "mc-vpc-subnet-private" {
    vpc_id                          = aws_vpc.mc-vpc.id
    cidr_block                      = "10.0.2.0/24"
    availability_zone               = "ap-southeast-1a"

    tags = { Name = "mc-vpc-subnet-private" }
}

resource "aws_internet_gateway" "mc-vpc-igw" {
    vpc_id = aws_vpc.mc-vpc.id

    tags = { Name = "mc-vpc-igw" }
}

resource "aws_route_table" "mc-vpc-routetable-public" {
    vpc_id = aws_vpc.mc-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.mc-vpc-igw.id
    }

    tags = { Name = "mc-vpc-routetable-public" }
}

resource "aws_route_table_association" "mc-vpc-routetable-association" {
    subnet_id       = aws_subnet.mc-vpc-subnet-public.id
    route_table_id  = aws_route_table.mc-vpc-routetable-public.id
}

resource "aws_s3_bucket" "mc-s3-worldbackup-dylxnlim" {
    bucket = "mc-s3-bucket-dylxnlim-worldbackup"
}

resource "aws_s3_bucket_versioning" "mc-s3-worldbackup-dylxnlim-versioning" {
    bucket = aws_s3_bucket.mc-s3-worldbackup-dylxnlim.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "mc-s3-worldbackup-dylxnlim-publicaccessblock" {
    bucket                      = aws_s3_bucket.mc-s3-worldbackup-dylxnlim.id
    block_public_acls           = true
    block_public_policy         = true
    ignore_public_acls          = true
    restrict_public_buckets     = true
}

#IAM Role for EC2 to write to S3
resource "aws_iam_role" "mc-iam-role-s3worldbackup" {
    name = "mc-iam-role-s3"

    assume_role_policy = jsonencode({                       #Trust Policy
        Version = "2012-10-17"                              #Version of the IAM policy language syntax
        Statement = [{
            Action      = "sts:AssumeRole"                  #Allow an entity to temporarily assume role
            Effect      = "Allow"                           #Explicitly giving permission
            Principal   = { Service = "ec2.amazonaws.com" } #Targetting only EC2 allowed
        }]
    })
}

resource "aws_iam_role_policy" "mc-iam-role-policy-s3worldbackup" {
    name = "mc-iam-role-policy-s3worldbackup"
    role = aws_iam_role.mc-iam-role-s3worldbackup.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action      = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
            Effect      = "Allow"
            Resource    = [
                aws_s3_bucket.mc-s3-worldbackup-dylxnlim.arn,
                "${aws_s3_bucket.mc-s3-worldbackup-dylxnlim.arn}/*"
            ]
        }]
    })
}

resource "aws_iam_instance_profile" "mc-iam-instanceprofile" {
    name = "mc-iam-instanceprofile"
    role = aws_iam_role.mc-iam-role-s3worldbackup.name
}