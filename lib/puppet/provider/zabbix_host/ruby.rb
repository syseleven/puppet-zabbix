require_relative '../zabbix'
Puppet::Type.type(:zabbix_host).provide(:ruby, parent: Puppet::Provider::Zabbix) do
  confine feature: :zabbixapi

  mk_resource_methods

  def self.instances
    proxies = zbx.proxies.all
    api_hosts = self.zbx.query(
      method: 'host.get',
      params: {
        selectParentTemplates: ['host'],
        selectInterfaces: ['interfaceid', 'type', 'main', 'ip', 'port', 'useip'],
        selectGroups: ['name'],
        output: ['host', 'proxy_hostid']
      }
    )

    api_hosts.map do |h|
      interface = h['interfaces'].select { |i| i['type'].to_i == 1 and i['main'].to_i == 1 }.first
      new(
        ensure: :present,
        id: h['hostid'].to_i,
        name: h['host'],
        interfaceid: interface['interfaceid'].to_i,
        ipaddress: interface['ip'],
        use_ip: (! interface['useip'].to_i.zero?),
        port: interface['port'].to_i,
        groups: h['groups'].map { |g| g['name'] },
        group_create: nil,
        templates: h['parentTemplates'].map { |x| x['host']},
        proxy: proxies.select { |name,id| id == h['proxy_hostid'] }.keys.first,
      )
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def create
    template_ids = get_templateids(@resource[:templates])
    templates = transform_to_array_hash('templateid', template_ids)

    gids = get_groupids(@resource[:groups], @resource[:group_create])
    groups = transform_to_array_hash('groupid', gids)

    proxy_hostid = proxy.nil? || proxy.empty? ? nil : zbx.proxies.get_id(host: @resource[:proxy])

    # Now we create the host
    zbx.hosts.create(
      host: @resource[:hostname],
      proxy_hostid: proxy_hostid,
      interfaces: [
        {
          type: 1,
          main: 1,
          ip: @resource[:ipaddress],
          dns: @resource[:hostname],
          port: @resource[:port],
          useip: @resource[:use_ip] ? 1 : 0
        }
      ],
      templates: templates,
      groups: groups,
    )
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    zbx.hosts.delete(zbx.hosts.get_id(host: @resource[:hostname]))
  end

  #
  # Helper methods
  #
  def get_groupids(group_array, create)
    groupids = []
    group_array.each do |g|
      id = zbx.hostgroups.get_id(name: g)
      if id.nil?
        if create
          groupids << zbx.hostgroups.create(name: g)
        else
          raise Puppet::Error, 'The hostgroup (' + g + ') does not exist in zabbix. Please use the correct one or set group_create => true.'
        end
      else
        groupids << id
      end
    end
    groupids
  end

  def get_templateids(template_array)
    templateids = []
    template_array.each do |t|
      template_id = zbx.templates.get_id(host: t)
      raise Puppet::Error, "The template #{t} does not exist in Zabbix. Please use a correct one." if template_id.nil?
      templateids << template_id
    end
    templateids
  end

  #
  # zabbix_host properties
  #
  def ipaddress=(string)
    zbx.query(
      :method => 'hostinterface.update',
      :params => {
        interfaceid: @resource[:interfaceid],
        ip: string,
      }
    )
  end

  def use_ip=(boolean)
    zbx.query(
      :method => 'hostinterface.update',
      :params => {
        interfaceid: @resource[:interfaceid],
        useip: boolean ? 1 : 0,
      }
    )
  end

  def port=(int)
    zbx.query(
      :method => 'hostinterface.update',
      :params => {
        interfaceid: @resource[:interfaceid],
        port: int,
      }
    )
  end

  def groups=(hostgroups)
    gids = get_groupids(hostgroups, @resource[:group_create])
    groups = transform_to_array_hash('groupid', gids)

    zbx.hosts.create_or_update(
      host: @resource[:hostname],
      groups: [groupid: groups]
    )
  end

  def templates=(array)
    should_template_ids = get_templateids(array)

    # Get templates we have to clear. Unlinking only isn't really helpful.
    is_template_ids = zbx.query(
      method: 'host.get',
      params: {
        hostids: @resource[:id],
        selectParentTemplates: ['templateid'],
        output: ['host']
      }
    ).first['parentTemplates'].map { |t| t['templateid'].to_i }
    templates_clear = is_template_ids - should_template_ids

    zbx.query(
      :method => 'host.update',
      :params => {
        hostids: @resource[:id],
        templates: transform_to_array_hash( 'templateid', should_template_ids),
        templates_clear: transform_to_array_hash( 'templateid', templates_clear),
      }
    )
  end

  def proxy=(string)
    zbx.hosts.create_or_update(
      host: @resource[:hostname],
      proxy_hostid: zbx.proxies.get_id(host: string)
    )
  end
end
