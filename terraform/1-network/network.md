# Network

This stage uses the resource groups in the previous stage and uses them to setup the infrastructure for the network, the network itself is split into 3 parts:
- Gateway - The gateway network allows users to log on to the platform
- Transit - The transit network is the way users can access Databricks.
- Data Plane - The data plane network contains the Databricks instance that users will be accessing. Users will not explicitly be able to access the network containing your clusters, and Databricks instance.

By using this approach we can more easily represent what we might see on a client project.
- You will almost never need to set-up the gateway. Knowing how users access the network, and getting them access to databricks is important however.
- You will likely need to set up the other 2 parts of the network. Having an understanding of each will allow you to effectively communicate with a client what is required from each.


## Gateway Network

Our Gateway network contains only 4 resources, but in a way it is the most complex piece of networking included in this project.

**Virtual Network Gateway**
A virtual network gateway is an entrypoint to your network. In this case we are using it's P2S (Point-to-Site) features. Point to Site is used when lots of people in disparate locations want to share the same network, for example when you have a team that works from home, such as ours.

Users will activate their VPN client, and be assigned an IP on the network by this resource, and they can then access other resources within the connected network.

**Private Resolver**
The private resolver is used for DNS (Domain Name System), which translates URLS (abc.azuredatabricks.net) to IPs (10.10.1.7). We have a Private DNS zone on our network, which is located within the Transit resource group, however this doesn't get used by our connection over VPN.

When go to databricks via our browser, our VPN client will first do a DNS lookup with the private resolver. This will return the DNS record from the Private DNS zone. This finally will redirect our browser to the correct private IP address on our network where the Databricks frontend endpoint is located.

**Public IP Address**
This is the only public facing part of our network. We need to have a way for a user to connect to our private network via VPN. This initial connection is done via the public IP.


## Transit Network
Our transit network permits access to Databricks, by containing the endpoints for access, DNS zones to resolve web addresses and a Databricks Workspace for authentication.

**AAD Auth Endpoint**
This private endpoint is connected to our transit workspace. It's also routed to from the DNS Zone under the auth URL. When a user is completing the AD authentication flow as they log in to Databricks this PE and Workspace will complete the authentication check.

**Network Security Group**
This network security group is used for the Private/Public subnets within the transit VNET. These subnets are only used for the Transit workspace. Users should not be provided access to this workspace, as it is only for use in authentication. Therefor it is expected that these subnets remain unused, and therefore so should this NSG.

**Front End Private Endpoint**
This private endpoint is connected to our App/Data plane workspace. It's also routed via the DNS for the workspaces URL. When a user is accessing a workspace, this PE is accessed.

**Private DNS Zone**
The Private DNS zone is a table that links between URLS and IP addresses. In our setup we have a two URL resolutions
- Our Workspace URL -> This is routed to our Front End private endpoint IP
- <region>.pl-auth -> This is routed to our AAD auth private endpoint IP