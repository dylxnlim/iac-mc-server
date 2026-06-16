<h1>IaC MC Server Side Project</h1> by Dylan Lim
<br>
<h2>Technologies Used</h2>
| Ubuntu | Terraform | Ansible | AWS | AWS CLI | Git |
<h2>Phase 1 - Provisioning Infrastructure in AWS (Terraform)</h2>
Wrote main.tf, outputs.tf and variables.tf to:
<ul>
    <li>Provision eip, security group, ec2 instance</li>
    <li>Associate eip to ec2 instance, created route53 record for DNS routing (human url to machine IP)</li>
</ul>
<br>
Wrote inventory.ini, playbook.yml (Install Java & Create Server Directory tasks)(Ansible)
<ul>
    <li>When creating files or folder, change owner to 'ec2-user' otherwise it will be root by default, so we can change files</li>
    <li>damemon_reload whenever files are added or modified to force Linux to refresh memory to scan.</li>
</ul>

inventory.ini will contain sensitive details, so I did not push it to the repository.
<code>
[mcserver]
aws-public-ip ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/ssh-file.pem
</code>
Replace 'aws-public-ip' and 'ssh-file' with the relevant files before proceeding.

Run these commands:
aws configure (Account > Security Credentials > Create access key)
<code>terraform init</code>
terraform plan -out=myplan.tfplan</code>
terraform apply "myplan.tfplan"</code>

<code>ansible [inventory] -m ping -i inventory.ini</code>
<code>ansible-playbook -i inventory.ini playbook.yml</code>

Once done testing, <code>terraform destroy</code> to remove any charges. Now, we will proceed to Phase 2.
