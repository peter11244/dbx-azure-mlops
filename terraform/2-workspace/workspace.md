You need to download the VPN profile and add the following 

<clientconfig>
	<dnssuffixes>
		<dnssuffix>.azuredatabricks.net</dnssuffix>
	</dnssuffixes>
	<dnsservers>
		<dnsserver>10.12.1.4</dnsserver>
	</dnsservers>
</clientconfig>