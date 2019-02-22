Puppet::Type.newtype(:zabbix_usergroup) do
  ensurable do
    defaultvalues
    defaultto :present
  end

  def munge_boolean(value)
    case value
    when true, 'true', :true
      true
    when false, 'false', :false
      false
    else
      raise(Puppet::Error, 'munge_boolean only takes booleans')
    end
  end

  newparam(:name, namevar: true) do
    desc 'Name of the user group.'
  end

  newproperty(:id) do
    desc 'Internally used identifier for the user group'

    validate do |_value|
      raise(Puppet::Error, 'id is read-only and is only available via puppet resource.')
    end
  end

  newproperty(:debug_mode, boolean: true) do
    desc 'Whether debug mode is enabled or disabled.'

    defaultto :false
    newvalues(true, false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:gui_access) do
    desc 'Frontend authentication method of the users in the group.'

    defaultto :default
    newvalues(:default, :internal, :disabled)
  end

  newproperty(:enable, boolean: true) do
    desc 'Whether the user group is enabled or disabled.'

    defaultto true
    newvalues(true, false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end
end
