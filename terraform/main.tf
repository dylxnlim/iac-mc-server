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
    vpc_security_group_ids = [aws_security_group.mc-securitygroup.id]

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
