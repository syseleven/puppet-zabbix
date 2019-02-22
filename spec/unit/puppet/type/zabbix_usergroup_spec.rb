require 'spec_helper'
require 'unit/puppet/x/spec_zabbix_types'

describe Puppet::Type.type(:zabbix_usergroup) do
  describe 'when validating params' do
    [
      :name
    ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
  end

  describe 'when validating properties' do
    [
      :ensure,
      :id,
      :debug_mode,
      :gui_access,
      :enable
    ].each do |param|
      it "should have a #{param} property" do
        expect(described_class.attrtype(param)).to eq(:property)
      end
    end
  end

  describe 'munge_boolean' do
    {
      true    => true,
      false   => false,
      'true'  => true,
      'false' => false,
      :true   => true,
      :false  => false
    }.each do |key, value|
      it "munges #{key.inspect} to #{value}" do
        expect(described_class.new(name: 'nobody').munge_boolean(key)).to eq value
      end
    end

    it 'fails on non boolean-ish values' do
      expect { described_class.new(name: 'nobody').munge_boolean('foo') }.to raise_error(Puppet::Error, 'munge_boolean only takes booleans')
    end
  end

  describe 'parameters' do
    describe 'name' do
      it_behaves_like 'generic namevar', :name
    end
  end

  describe 'properties' do
    describe 'ensure' do
      it_behaves_like 'generic ensurable', :present
    end

    describe 'id' do
      it_behaves_like 'readonly property', :id
    end

    describe 'debug_mode' do
      it_behaves_like 'boolean property', :debug_mode, false
    end

    describe 'gui_access' do
      it_behaves_like 'validated property', :gui_access, :default, [:default, :internal, :disabled], ['foo', :bar, 1, true, false]
    end

    describe 'enable' do
      it_behaves_like 'boolean property', :enable, true
    end
  end
end
