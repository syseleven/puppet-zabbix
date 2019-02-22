require 'spec_helper'
require 'fakefs/spec_helpers'

describe Puppet::Type.type(:zabbix_usergroup).provider(:ruby) do
  let(:resource) do
    Puppet::Type.type(:zabbix_usergroup).new(
      name: 'Test Usergroup'
    )
  end
  let(:provider) { resource.provider }

  it 'be an instance of the correct provider' do
    expect(provider).to be_an_instance_of Puppet::Type::Zabbix_usergroup::ProviderRuby
  end

  [:instances, :prefetch].each do |method|
    it "should respond to the class method #{method}" do
      expect(described_class).to respond_to(method)
    end
  end

  [:create, :exists?, :destroy, :debug_mode, :gui_access, :enable].each do |method|
    it "should respond to the instance method #{method}" do
      expect(described_class.new).to respond_to(method)
    end
  end
end
