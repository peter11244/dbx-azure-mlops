# Workspace Config

Now we have the networks in place, we can add our Databricks Infrastructure. This stage deploys our 2 databricks workspaces, and the endpoints used to provide access to them. Our main workspace is our "app-workspace" and that is the one our users will connect to. We also have an "auth-workspace" which is a redundant workspace that provides authorization of users and sits in our Transit VNet.


## Connecting to the Workspace
Once you have run this Terraform project you can start to connect to your workspace. You should use the Azure VPN client for simplicity, and whilst testing deactivate any other VPN client you have on your machine.

To get your VPN profile information, go to your Virtual Network Gateway in your Gateway resource group. You should see a download link on the P2S Configuration screen.

When you download the VPN Profile, you will need to update the profile before importing it to your VPN client.
To do so, unzip it, and change the line `<clientconfig/>` to the following:

```
<clientconfig>
	<dnssuffixes>
		<dnssuffix>.azuredatabricks.net</dnssuffix>
	</dnssuffixes>
	<dnsservers>
		<dnsserver>10.12.1.4</dnsserver>
	</dnsservers>
</clientconfig>
```

Here, the value for `dnsserver` can be found by looking at the IP address under your Private Resolver's Inbound endpoint.