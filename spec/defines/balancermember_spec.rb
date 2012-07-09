require 'spec_helper'

describe 'haproxy::balancermember' do
  let(:title) { 'tyler_s' }
  let(:facts) do
    { :ipaddress => '1.1.1.1',
      :hostname  => 'dero'
    }
  end
  let(:params) do
    { :name                   => 'tyler_s',
      :listening_service      => 'croy',
      :balancer_port          => '18140',
      :balancermember_options => 'check'
    }
  end

  it { should contain_concat__fragment('croy_balancermember_tyler_s').with(
    'order'   => '20',
    'target'  => '/etc/haproxy/haproxy.cfg',
    'content' => "  server  dero 1.1.1.1:18140  check \n"
    ) }
end

