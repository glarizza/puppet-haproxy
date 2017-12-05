require 'spec_helper_acceptance'

describe 'listen define' do
  pp_one = <<-PUPPETCODE
      class { 'haproxy': }
      haproxy::listen { 'app00':
        ipaddress => $::ipaddress_lo,
        ports     => '5555',
        mode      => 'http',
      }
      haproxy::balancermember { 'port 5556':
        listening_service => 'app00',
        ports             => '5556',
      }
      haproxy::balancermember { 'port 5557':
        listening_service => 'app00',
        ports             => '5557',
      }
  PUPPETCODE
  it 'is able to configure the listen with puppet' do
    apply_manifest(pp_one, catch_failures: true)
  end

  # This is not great since it depends on the ordering served by the load
  # balancer. Something with retries would be better.
  # C9876 C9877 C9941 C9954
  it 'does a curl against the LB to make sure it gets a response from each port' do
    shell('curl localhost:5555').stdout.chomp.should match(%r{Response on 555(6|7)})
    shell('curl localhost:5555').stdout.chomp.should match(%r{Response on 555(6|7)})
  end

  # C9955
  pp_two = <<-PUPPETCODE
      class { 'haproxy': }
      haproxy::listen { 'app00':
        ipaddress => $::ipaddress_lo,
        ports     => '5555',
        mode      => 'http',
        options   => { 'option' => 'httpchk', },
      }
      haproxy::balancermember { 'port 5556':
        listening_service => 'app00',
        ports             => '5556',
        options           => 'check',
      }
      haproxy::balancermember { 'port 5557':
        listening_service => 'app00',
        ports             => '5557',
        options           => ['check','backup'],
      }
  PUPPETCODE
  it 'is able to configure the listen active/passive' do
    apply_manifest(pp_two, catch_failures: true)
    apply_manifest(pp_two, catch_changes: true)
  end

  it 'does a curl against the LB to make sure it only gets a response from the active port' do
    sleep(10)
    shell('curl localhost:5555').stdout.chomp.should match(%r{Response on 5556})
    shell('curl localhost:5555').stdout.chomp.should match(%r{Response on 5556})
  end

  # C9942 C9944 WONTFIX

  # C9943
  pp_three = <<-PUPPETCODE
      class { 'haproxy': }
      haproxy::listen { 'app00':
        ipaddress => $::ipaddress_lo,
        ports     => '5555',
        mode      => 'http',
      }
      haproxy::balancermember { 'port 5556':
        listening_service => 'app00',
        ports             => '5556',
      }
      haproxy::balancermember { 'port 5557':
        listening_service => 'app00',
        ports             => '5558',
      }
  PUPPETCODE
  it 'is able to configure the listen with only one node up' do
    apply_manifest(pp_three, catch_failures: true)
  end

  it 'does a curl against the LB to make sure it gets a response from each port #onenodeup' do
    shell('curl localhost:5555').stdout.chomp.should match(%r{Response on 5556})
    shell('curl localhost:5555').stdout.chomp.should match(%r{Response on 5556})
  end

  pp_four = <<-PUPPETCODE
      class { 'haproxy': }
        haproxy::listen { 'app0':
        bind =>
          { '127.0.0.1:5555' => [] }
          ,
        }
  PUPPETCODE
  it 'having no address set but setting bind' do
    apply_manifest(pp_four, catch_failures: true)
  end
end
