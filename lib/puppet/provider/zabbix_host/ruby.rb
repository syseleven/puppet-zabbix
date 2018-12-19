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
        group: h['groups'][0]['name'],
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
    # Set some vars
    host = @resource[:hostname]
    ipaddress = @resource[:ipaddress]
    use_ip = @resource[:use_ip]
    port = @resource[:port]
    hostgroup = @resource[:group]
    hostgroup_create = @resource[:group_create]
    templates = @resource[:templates]
    proxy = @resource[:proxy]

    # Get the template ids.
    template_array = []
    if templates.is_a?(Array)
      templates.each do |template|
        template_id = get_template_id(zbx, template)
        template_array.push template_id
      end
    else
      template_array.push get_template_id(zbx, templates)
    end

    # Check if we need to connect via ip or fqdn
    use_ip = use_ip ? 1 : 0

    # When using DNS you still have to send a value for ip
    ipaddress = '' if ipaddress.nil? && use_ip.zero?

    hostgroup_create = hostgroup_create ? 1 : 0

    # First check if we have an correct hostgroup and if not, we raise an error.
    search_hostgroup = zbx.hostgroups.get_id(name: hostgroup)
    if search_hostgroup.nil? && hostgroup_create == 1
      zbx.hostgroups.create(name: hostgroup)
      search_hostgroup = zbx.hostgroups.get_id(name: hostgroup)
    elsif search_hostgroup.nil? && hostgroup_create.zero?
      raise Puppet::Error, 'The hostgroup (' + hostgroup + ') does not exist in zabbix. Please use the correct one.'
    end

    # Now we create the host
    hostid = zbx.hosts.create_or_update(
      host: host,
      interfaces: [
        {
          type: 1,
          main: 1,
          ip: ipaddress,
          dns: host,
          port: port,
          useip: use_ip
        }
      ],
      templates: template_array,
      groups: [groupid: search_hostgroup]
    )

    zbx.templates.mass_add(hosts_id: [hostid], templates_id: template_array)

    return if proxy.nil? || proxy.empty?
    zbx.hosts.update(
      hostid: zbx.hosts.get_id(host: host),
      proxy_hostid: zbx.proxies.get_id(host: proxy)
    )
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    host = @resource[:hostname]
    zbx.hosts.delete(zbx.hosts.get_id(host: host))
  end

  #
  # Helper methods
  #

  #
  # zabbix_host properties
  #
  def ipaddress=(string)
    zbx.query(
      :method => 'hostinterface.update',
      :params => {
        interfaceid: @resource[:interfaceid],
        ip: @resource[:ipaddress],
      }
    )
  end

  def use_ip=(boolean)
    zbx.query(
      :method => 'hostinterface.update',
      :params => {
        interfaceid: @resource[:interfaceid],
        ip: @resource[:ipaddress],
      }
    )
  end

  def port=(int)
  end

  def group=(string)
  end

  def templates=(array)
  end

  def proxy=(string)
  end
end
