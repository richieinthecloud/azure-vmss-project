# azure-vmss-project
Architected a highly available Azure cloud environment that handles thousands of requests per hour using auto-scaling and load balancing. This helps to reduce operational costs during non-peak hours while also maintaining 99.99% uptime.

# Still a work in progress. Presently refactoring my project to better reflect Terraform best practice.

# Basic traffic flow
- Internet traffic hits the Application Gateway (+WAF) and it gets distributed amongst the Web tier Virtual Machine Scale Set. We have NSGs in place to make sure only traffic over port 80 and port 443 is allowed. 
- An internal load balancer handles traffic from our Web tier VMSS to our App tier VMSS. NSGs at this tier only allow traffic from our App tier to the SQL database instance. The SQL database in this case in connection to our Private Endpoint subnet. 
- We are utilizing a Bastion subnet to provide a channel for administrative access to our VMs. 
- We are utilizing a storage account as the remote backend for our Terraform state file

- Our VMSS always starts with 1 default instance. Dependent on the environment (Prod, Dev or DR) it can autoscale to 3 or 4 instances. 

- Working on adding monitoring, alerts and action groups. 
