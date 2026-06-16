#Variable Declaration
variable "aws-region" {
    default = "ap-southeast-1"  #Singapore
}

variable "my_ip" {
    description = "The public IP for SSH access"
    type        = string
}

variable "key_pair_name" {
    description = "The name of the AWS key-pair"
    type        = string
}

# variable "hosted_zone_id" {
#     description = "Route53 Hosted Zone ID for domain"
#     type        = string
# }