Puppet::Type.newtype(:zabbix_host) do
  ensurable do
    defaultvalues
    defaultto :present
  end

  def initialize(*args)
    super

    # Migrate the group to groups
    unless self[:group].nil?
      self[:groups] = self[:group]
      self.delete(:group)
    end
  end

  newparam(:hostname, namevar: true) do
    desc 'FQDN of the machine.'
  end

  newproperty(:id, :readonly => true) do
    desc 'Internally used hostid'
  end

  newproperty(:interfaceid, :readonly => true) do
    desc 'Internally used identifier for the host interface'
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
    desc 'Deprecated! Name of the hostgroup.'

    validate do |_value|
      Puppet.warning('Passing group to zabbix_host is deprecated and will be removed. Use groups instead.')
    end
  end

  newproperty(:groups, :array_matching => :all) do
    desc 'An array of groups the host belongs to.'
    def insync?(is)
      is.sort == should.sort
    end
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

  validate do
    raise(_('The properties group and groups are mutually exclusive.')) if self[:group] and self[:groups]
  end
end
