## Description
This project is aimed to demonstrate how to launch fully automated setup of Grafana and Prometheus in Docker using Vagrant on a virtual machine in [Selectel cloud](https://selectel.ru/en/).

***
## Preparations
1. Create a working directory for this demonstration:  `mkdir tf-demo ; cd tf-demo`

2. Create/Obtain credentials and tokens from Web Console as described in 
https://kb.selectel.com/docs/cloud/servers/tools/how_to_use_openstack_api_through_console_clients/

3. Download and review contents of the small shell script `rc.sh` generated with your credentials. It has all information required to authenticate to the cloud.

5. Install **Terraform**. The demonstration was tested on Terraform version 1.1.x+. See the official instructions from HashiCorp: https://learn.hashicorp.com/tutorials/terraform/install-cli.

6. Set shell auto-completion feature for Terraform to simplify further command line tasks. Run: `terraform -install-autocomplete`. It will append a line to your `.bashrc` file in your home directory. In order to activate this auto-completion functionality you should either re-open your shell or run the added line in the existing shell.

7. (Optionally) Install command line tool `openstack`. This tool will be helpful for checking cloud objects, review their parameters, etc. Consult the documentation at https://docs.openstack.org/newton/user-guide/common/cli-install-openstack-command-line-clients.html.

8. (Optionally) For running tool `openstack` from the previous step, import contents of shell script `rc.sh` downloaded above. Open UNIX shell and run `source rc.sh`.

9. Clone this git repository to the current directory created above:
      ```bash
      git clone https://github.com/SiberianComrade3/terraform-vagrant-docker-demo.git .
      ```

***
## Initialize and run Terraform
1. Define the following sensitive variables either in file `terraform.tfvars` (not included in Git repository) or through related environment variables (`TF_VAR_sel_account`, `TF_VAR_sel_token`, etc.). The example below shows setting variables in file `terraform.tfvars`:
      ```ini
      user_name      = ""   # account name created on the Web Console, also mentioned in rc.sh.
      user_password  = ""
      sel_account    =      # account number, several digits without quotes
      project_id     = ""   # long alphanumeric ID found on the Web Console and in the script rc.sh.
      sel_token      = ""   # Access token created and available through Web Console. Copy full string.
      proctor_ip     = ""   # Additional IP address or a subnet that has access to SSH and Grafana Web
      ``` 
2. Run `terraform init` to initialize Providers used in Terraform configuration. Expect to see the following successful message in green:
   > Terraform has been successfully initialized!

   :warning: Be prepared that not all Providers can be downloaded from HashiCorp; they intentionally block access with HTTP code 405. If this is your case you should either use available mirrors or mirror the needed providers as described in [README Extra](README_extra.md).


3. Run `terraform validate` to ensure all files still have correct syntax.
   > Success! The configuration is valid.

4. Run `terraform apply`. It should report successful creation of defined objects.
   > Apply complete! Resources: 43 added, 0 changed, 0 destroyed.

5. Note output section of the previous command. It contains IP addresses and Grafana URL needed to establish connections to demo infrastructure. This output can be viewed again any time by running `terraform output` from root of working directory. 

:information_source: In case of problems occurred during Terraform execution, start it in debug mode like the following command:

```bash
TF_LOG=DEBUG OS_DEBUG=1 terraform apply
```

***
## Testing the Environment

### Grafana

Open a web browser. Enter address `https://`<**grafana_url**>:`3000`. For your convenience copy pre-generated URL from `terraform output` `grafana_url`.

:information_source: Access to Grafana Web interface is limited to IP addresses defined as `proctor_ip` and to public IP address of the host from which you ran Terraform (check `curl ifconfig.ru`). 

:no_entry: Access to Grafana Web interface from other hosts won't be possible by design.

Watch the "Warning: Potential Security Risk" notice and click "Advanced..." to "Accept the Risk". 

Pay attention that IP address used to access the server is registered in "Subject Alt Names" of SSL/TLS certificate provided by the Grafana server.

### Vagrant and Docker
Login with SSH to Linux host machine as advised in output **ssh_to_host**, copy-paste full command that like below

`ssh -q -o StrictHostKeyChecking=no -i ./id_rsa root@xx.xx.xx.xx`

You should be able to get there as 'root' superuser without additional questions and see standard Shell command prompt.

Please allow several minutes to fully initialize the environment (Vagrant + Docker) in the cloud. You can control how it is being started in real-time by running on the Linux host machine:
```bash
tail -f /var/log/cloud-init-output.log
```
Once Vagrant has started a virtual machine, run `vagrant ssh` to get inside it.

Check running Docker containers: `sudo docker ps` inside the virtual machine.

***
## Terminate all cloud instances 
Run `terraform destroy` to save cloud resources and your budget.
