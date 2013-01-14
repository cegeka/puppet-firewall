#!/usr/bin/env rspec

require 'spec_helper'
require 'puppet/provider/confine/exists'

describe 'iptables chain provider detection' do
  let(:exists) {
    Puppet::Provider::Confine::Exists
  }

  before :each do
    # Reset the default provider
    Puppet::Type.type(:firewallchain).defaultprovider = nil
  end

  it "should default to iptables provider if /sbin/(eb|ip|ip6)tables[-save] exists" do
    # Stub lookup for /sbin/iptables & /sbin/iptables-save
    exists.any_instance.stubs(:which).with("/sbin/ebtables").
      returns "/sbin/ebtables"
    exists.any_instance.stubs(:which).with("/sbin/ebtables-save").
      returns "/sbin/ebtables-save"

    exists.any_instance.stubs(:which).with("/sbin/iptables").
      returns "/sbin/iptables"
    exists.any_instance.stubs(:which).with("/sbin/iptables-save").
      returns "/sbin/iptables-save"

    exists.any_instance.stubs(:which).with("/sbin/ip6tables").
      returns "/sbin/ip6tables"
    exists.any_instance.stubs(:which).with("/sbin/ip6tables-save").
      returns "/sbin/ip6tables-save"

    # Every other command should return false so we don't pick up any
    # other providers
    exists.any_instance.stubs(:which).with() { |value|
      value !~ /\/sbin\/(eb|ip|ip6)tables(-save)?$/
    }.returns false

    # Create a resource instance and make sure the provider is iptables
    resource = Puppet::Type.type(:firewallchain).new({
      :name => 'test:filter:IPv4',
    })
    resource.provider.class.to_s.should == "Puppet::Type::Firewallchain::ProviderIptables_chain"
  end
end

describe 'iptables chain provider' do
  let(:provider) { Puppet::Type.type(:firewallchain).provider(:iptables_chain) }
  let(:resource) {
    Puppet::Type.type(:firewallchain).new({
      :name  => ':test:',
    })
  }

  before :each do
    Puppet::Type::Firewallchain.stubs(:defaultprovider).returns provider
    provider.stubs(:command).with(:ebtables_save).returns "/sbin/ebtables-save"
    provider.stubs(:command).with(:iptables_save).returns "/sbin/iptables-save"
    provider.stubs(:command).with(:ip6tables_save).returns "/sbin/ip6tables-save"
  end

  it 'should be able to get a list of existing rules' do
    # Pretend to return nil from iptables
    provider.stubs(:execute).with(['/sbin/ip6tables-save']).returns("")
    provider.stubs(:execute).with(['/sbin/ebtables-save']).returns("")
    provider.stubs(:execute).with(['/sbin/iptables-save']).returns("")

    provider.instances.each do |chain|
      chain.should be_instance_of(provider)
      chain.properties[:provider].to_s.should == provider.name.to_s
    end
  end

end

describe 'iptables chain resource parsing' do
  let(:provider) { Puppet::Type.type(:firewallchain).provider(:iptables_chain) }

  before :each do
    ebtables = ['BROUTE:BROUTING:ethernet',
                'BROUTE:broute:ethernet',
                ':INPUT:ethernet',
                ':FORWARD:ethernet',
                ':OUTPUT:ethernet',
                ':filter:ethernet',
                ':filterdrop:ethernet',
                ':filterreturn:ethernet',
                'NAT:PREROUTING:ethernet',
                'NAT:OUTPUT:ethernet',
                'NAT:POSTROUTING:ethernet',
               ]
    provider.stubs(:execute).with(['/sbin/ebtables-save']).returns('
*broute
:BROUTING ACCEPT
:broute ACCEPT

*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
:filter ACCEPT
:filterdrop DROP
:filterreturn RETURN

*nat
:PREROUTING ACCEPT
:OUTPUT ACCEPT
:POSTROUTING ACCEPT
')

    iptables = [
     'raw:PREROUTING:IPv4',
     'raw:OUTPUT:IPv4',
     'raw:raw:IPv4',
     'mangle:PREROUTING:IPv4',
     'mangle:INPUT:IPv4',
     'mangle:FORWARD:IPv4',
     'mangle:OUTPUT:IPv4',
     'mangle:POSTROUTING:IPv4',
     'mangle:mangle:IPv4',
     'NAT:PREROUTING:IPv4',
     'NAT:OUTPUT:IPv4',
     'NAT:POSTROUTING:IPv4',
     'NAT:mangle:IPv4',
     'NAT:mangle:IPv4',
     'NAT:mangle:IPv4',
     ':$5()*&%\'"^$): :IPv4',
    ]
    provider.stubs(:execute).with(['/sbin/iptables-save']).returns('
# Generated by iptables-save v1.4.9 on Mon Jan  2 01:20:06 2012
*raw
:PREROUTING ACCEPT [12:1780]
:OUTPUT ACCEPT [19:1159]
:raw - [0:0]
COMMIT
# Completed on Mon Jan  2 01:20:06 2012
# Generated by iptables-save v1.4.9 on Mon Jan  2 01:20:06 2012
*mangle
:PREROUTING ACCEPT [12:1780]
:INPUT ACCEPT [12:1780]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [19:1159]
:POSTROUTING ACCEPT [19:1159]
:mangle - [0:0]
COMMIT
# Completed on Mon Jan  2 01:20:06 2012
# Generated by iptables-save v1.4.9 on Mon Jan  2 01:20:06 2012
*nat
:PREROUTING ACCEPT [2242:639750]
:OUTPUT ACCEPT [5176:326206]
:POSTROUTING ACCEPT [5162:325382]
COMMIT
# Completed on Mon Jan  2 01:20:06 2012
# Generated by iptables-save v1.4.9 on Mon Jan  2 01:20:06 2012
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [5673:420879]
:$5()*&%\'"^$):  - [0:0]
COMMIT
# Completed on Mon Jan  2 01:20:06 2012
')
    ip6tables = [
      'raw:PREROUTING:IPv6',
      'raw:OUTPUT:IPv6',
      'raw:ff:IPv6',
      'mangle:PREROUTING:IPv6',
      'mangle:INPUT:IPv6',
      'mangle:FORWARD:IPv6',
      'mangle:OUTPUT:IPv6',
      'mangle:POSTROUTING:IPv6',
      'mangle:ff:IPv6',
      ':INPUT:IPv6',
      ':FORWARD:IPv6',
      ':OUTPUT:IPv6',
      ':test:IPv6',
    ]
    provider.stubs(:execute).with(['/sbin/ip6tables-save']).returns('
# Generated by ip6tables-save v1.4.9 on Mon Jan  2 01:31:39 2012
*raw
:PREROUTING ACCEPT [2173:489241]
:OUTPUT ACCEPT [0:0]
:ff - [0:0]
COMMIT
# Completed on Mon Jan  2 01:31:39 2012
# Generated by ip6tables-save v1.4.9 on Mon Jan  2 01:31:39 2012
*mangle
:PREROUTING ACCEPT [2301:518373]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:ff - [0:0]
COMMIT
# Completed on Mon Jan  2 01:31:39 2012
# Generated by ip6tables-save v1.4.9 on Mon Jan  2 01:31:39 2012
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [20:1292]
:test - [0:0]
COMMIT
# Completed on Mon Jan  2 01:31:39 2012
')
    @all = ebtables + iptables + ip6tables
    # IPv4 and IPv6 names also exist as resources {table}:{chain}:IP and {table}:{chain}:
    iptables.each { |name| @all += [ name[0..-3], name[0..-5] ] }
    ip6tables.each { |name| @all += [ name[0..-3], name[0..-5] ] }
  end

  it 'should have all in parsed resources' do
    provider.instances.each do |resource|
      @all.include?(resource.name)
    end
  end

end
