require_relative '../zabbix'
Puppet::Type.type(:zabbix_usergroup).provide(:ruby, parent: Puppet::Provider::Zabbix) do
  confine feature: :zabbixapi

  GUI_ACCESS_STATES = {
    default: 0,
    internal: 1,
    disabled: 2
  }.freeze

  def self.instances
    api_usergroups = zbx.query(
      method: 'usergroup.get',
      params: {
        output: 'extend'
      }
    )

    api_usergroups.map do |usergroup|
      new(
        ensure: :present,
        name: usergroup['name'],
        id: usergroup['usrgrpid'].to_i,
        debug_mode: usergroup['debug_mode'].to_i == 1 ? true : false,
        gui_access: GUI_ACCESS_STATES.key(usergroup['gui_access'].to_i),
        enable: usergroup['users_status'].to_i.zero?
      )
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def create
    zbx.usergroups.create(
      name: @resource[:name],
      debug_mode: @resource[:debug_mode] ? 1 : 0,
      gui_access: GUI_ACCESS_STATES[@resource[:gui_access]],
      enable: @resource[:enable] ? 0 : 1
    )
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    zbx.usergroups.delete(zbx.usergroups.get_id(name: @resource[:name]))
  end

  #
  # zabbix_usergroup properties
  #
  mk_resource_methods

  def debug_mode=(boolean)
    zbx.query(
      method: 'usergroup.update',
      params: {
        usrgrpid: @resource[:id],
        debug_mode: boolean ? 1 : 0
      }
    )
  end

  def gui_access=(state)
    zbx.query(
      method: 'usergroup.update',
      params: {
        usrgrpid: @resource[:id],
        gui_access: GUI_ACCESS_STATES[state]
      }
    )
  end

  def enable=(boolean)
    zbx.query(
      method: 'usergroup.update',
      params: {
        usrgrpid: @resource[:id],
        users_status: boolean ? 0 : 1
      }
    )
  end
end
