Puppet::Type.newtype(:zabbix_host) do
  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:hostname, namevar: true) do
    desc 'FQDN of the machine.'
  end

  newproperty(:ipaddress) do
    desc 'The IP address of the machine running zabbix agent.'
  end

  newproperty(:use_ip) do
    desc 'Using ipadress instead of dns to connect. Is used by the zabbix-api command.'
  end

  newproperty(:port) do
    desc 'The port that the zabbix agent is listening on.'
    def insync?(is)
      is.to_i == should.to_i
    end
  end

  newproperty(:group) do
    desc 'Name of the hostgroup.'
  end

  newparam(:group_create) do
    desc 'Create hostgroup if missing.'
  end

  newproperty(:templates, :array_matching => :all) do
    desc 'List of templates which should be loaded for this host.'
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:proxy) do
    desc 'Whether it is monitored by an proxy or not.'
  end
end
