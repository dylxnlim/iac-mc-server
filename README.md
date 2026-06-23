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

I will hardcode sensitive details into inventory.ini, so I did not push it to the repository for now.
<code>
```
[mcserver]
aws-public-ip ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/ssh-file.pem
```
</code>
Replace 'aws-public-ip' and 'ssh-file' with the relevant files before proceeding.

Run these commands:
<br>
<code>aws configure</code> (Account > Security Credentials > Create access key, You will need it for AWS CLI.)
<br>
<code>terraform init</code><br>
<code>terraform plan -out=myplan.tfplan</code><br>
<code>terraform apply "myplan.tfplan"</code><br>
<code>ansible [inventory] -m ping -i inventory.ini</code><br>
<code>ansible-playbook -i inventory.ini playbook.yml</code><br>
<code>ssh -i /path/toyour/key.pem username(ec2-user)@instance-public-ip</code> to verify its up.<br>

Once done testing, <code>terraform destroy</code> to remove any charges. Now, we will proceed to Phase 2.

In Phase 2, I will replace the default VPC with a custom one, and S3 world backups with Terraform remote state to make my architecture more robust.

<h2>Phase 2 - Initialising S3 Backend for Terraform state</h2>
<ul>
    <li>Added bootstrap subdirectory to setup for the remote storage of tfstate in s3</li>
    <li>When provisioning the bucket for the tfstate, it is important to add the policy lifecycle {prevent_destroy: true}</li>
    <li>This prevents the source of truth, the tfstate file from being removed.</li>
    <li>Created the backend.tf to terraform to the s3 bucket where the tfstate file will now live.</li>
    <li>Do <code>terraform init -migrate-state</code> to migrate state storage.</li>
</ul>

<h2>Phase 2 - Provisioning custom VPC</h2>
<ul>
    <li>Created a custom VPC, added a public and private subnet.</li>
    <li>The minecraft ec2 instance will live on the public subnet, the private subnet will be utilised in Phase 3.</li>
</ul>

<h2>Phase 2 - Scheduling Daily Backups with CronJob and Ansible</h2>
<ul>
    <li>Installed mcrcon, a minecraft Rcon client to execute server commands as well as gracefully handle server shutdowns and saving the world state.</li>
    <li>Practiced user with least privileges and managing sudo privileges with sudoers.d and only allowing to execute start and stop for the minecraft service.</li>
    <li>Employed the atomic deployment mindset, where all configurations are done first before initiating services. The service(s) will never be launched in an incomplete state where setup fails if it is done after a service is started.</li>
</ul>

<h3>NOTE: Before Running Ansible Playbook </h3>
Now that we have added <code>rcon_password: "{{ lookup('env', 'MCRCON_PASS') }}"</code> to the variables in the playbook, we need to define the environment variable first before running the playbook, or it will throw an error. This was done to avoid hardcoding sensitive data and pushing it to remote repositories.
<br>
In the playbook, I added a guardrail to confirm if the environment variable is set properly before the rest of the playbook runs, or it will throw an error.
<br>

```yml
- name: Verify MCRCON_PASS environment variable is set
  fail:
    msg: "MCRCON_PASS environment variable is not set. Run: export MCRCON_PASS=thepassword"
  when: rcon_password == ""
```

Now before running the playbook, just need to export the corresponding environment variable.

```bash
export MCRCON_PASS="YourPasswordOfChoice"
ansible-playbook -i inventory.ini playbook.yml -e "ansible_host=YourServerPublicIP"
```
