require 'spec_helper_acceptance'
require 'serverspec_type_zabbixapi'

describe 'zabbix_usergroup type' do
  context 'create zabbix_usergroup resources' do
    it 'runs successfully' do
      # This will deploy a running Zabbix setup (server, web, db) which we can
      # use for custom type tests
      pp = <<-EOS
        class { 'apache':
            mpm_module => 'prefork',
        }
        include apache::mod::php
        include postgresql::server

        class { 'zabbix':
          zabbix_version   => '3.0', # zabbixapi gem doesn't currently support higher versions
          zabbix_url       => 'localhost',
          zabbix_api_user  => 'Admin',
          zabbix_api_pass  => 'zabbix',
          apache_use_ssl   => false,
          manage_resources => true,
          require          => [ Class['postgresql::server'], Class['apache'], ],
        }

        Zabbix_usergroup {
          require => [ Service['zabbix-server'], Package['zabbixapi'], ],
        }

        zabbix_usergroup { 'Testusergroup': }
        zabbix_usergroup { 'Testusergroup1':
          debug_mode => true,
          gui_access => internal,
          enable     => false,
        }
        zabbix_hostgroup { 'No access to the frontend':
          ensure => absent,
        }
      EOS

      shell('yum clean metadata') if fact('os.family') == 'RedHat'

      # Cleanup old database
      shell('/opt/puppetlabs/bin/puppet resource service zabbix-server ensure=stopped; /opt/puppetlabs/bin/puppet resource package zabbix-server-pgsql ensure=purged; rm -f /etc/zabbix/.*done; su - postgres -c "psql -c \'drop database if exists zabbix_server;\'"')

      apply_manifest(pp, catch_failures: true)
    end

    let(:result_usergroups) do
      zabbixapi('localhost', 'Admin', 'zabbix', 'usergroup.get', output: 'extend').result
    end

    context 'Testusergroup' do
      it 'is created' do
        expect(result_usergroups.map { |t| t['name'] }).to include('Testusergroup')
      end
    end

    context 'Testusergroup1' do
      let(:host) { result_usergroups.select { |u| u['name'] == 'Testusergroup1' }[0] }

      it 'is created' do
        expect(result_usergroups.map { |t| t['name'] }).to include('Testusergroup1')
      end
      it 'has debug_mode enabled' do
        expect(host['debug_mode']).to eq '1'
      end
      it 'has gui_access set to internal' do
        expect(host['gui_access']).to eq '1'
      end
      it 'is disabled' do
        expect(host['users_status']).to eq '1'
      end
    end

    context 'No access to the frontend' do
      it 'is absent' do
        expect(result_usergroups.map { |t| t['name'] }).not_to include('No access to the frontend')
      end
    end
  end
end
