require 'spec_helper'

describe "manifesthost.example.com" do
    let(:facts) do
        {
            :osfamily  => 'Debian',
            :hostname  => 'manifesthost',
            :ipaddress => '1.1.1.1',
        }
    end

    it { should include_class('haproxy') }

    it do
        should contain_concat__fragment('croy_config_block')
        #.with(
        #    'order'   => '20',
        #    'target'  => '/etc/haproxy/haproxy.cfg',
        #    'content' => "\nlisten croy 1.1.1.1:18140\n  balance  roundrobin\n  option  tcplog\n  option  ssl-hello-chk\n"
        #)
    end

    it do
        should contain_concat__fragment('croy_balancermember_tyler').with(
            'order'   => '20',
            'target'  => '/etc/haproxy/haproxy.cfg',
            'content' => "  server  dero 1.1.1.1:18140  check \n"
        )
    end
end

