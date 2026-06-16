#Prints helpful information onto the terminal
output "server_ip" {
    value = aws_eip.mc-eip.public_ip
}

output "key_pair_name" {
    value = var.key_pair_name
}

# If Domain is purchased
# output "server_address" {
#     value = aws_route53_record.mc-route53-record.fqdn   #Fully Qualified Domain Name, final string
# }