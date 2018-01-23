require 'spec_helper_acceptance'

# C9708 C9709 WONTFIX
describe 'configuring haproxy' do
  # C9961
  describe 'not managing the service' do
    pp_one = <<-PUPPETCODE
      class { 'haproxy':
        service_manage => false,
      }
      haproxy::listen { 'stats':
        ipaddress => '127.0.0.1',
        ports     => ['9090','9091'],
        options   => {
          'mode'  => 'http',
          'stats' => ['uri /','auth puppet:puppet'],
        },
      }
      haproxy::listen { 'test00':
        ipaddress => '127.0.0.1',
        ports     => '80',
      }
    PUPPETCODE
    it 'does not listen on any ports' do
      apply_manifest(pp_one, catch_failures: true)
    end

    describe port('9090') do
      it { is_expected.not_to be_listening }
    end
    describe port('9091') do
      it { is_expected.not_to be_listening }
    end
  end

  describe 'configuring haproxy load balancing' do
    describe 'multiple ports' do
      pp_two = <<-PUPPETCODE
        class { 'haproxy': }
        haproxy::listen { 'stats':
          ipaddress => '127.0.0.1',
          ports     => ['9090','9091'],
          mode      => 'http',
          options   => { 'stats' => ['uri /','auth puppet:puppet'], },
        }
      PUPPETCODE
      it 'is able to listen on an array of ports' do
        apply_manifest(pp_two, catch_failures: true)
      end

      it 'has stats listening on each port' do
        %w[9090 9091].each do |port|
          shell("/usr/bin/curl -u puppet:puppet localhost:#{port}") do |r|
            r.stdout.should =~ %r{HAProxy}
            r.exit_code.should == 0
          end
        end
      end
    end

    describe 'with sort_options_alphabetic false' do
      pp_three = <<-PUPPETCODE
        class { 'haproxy::globals':
          sort_options_alphabetic => false,
        }
        class { 'haproxy': }
        haproxy::listen { 'stats':
          ipaddress => '127.0.0.1',
          ports     => ['9090','9091'],
          mode      => 'http',
          options   => { 'stats' => ['uri /','auth puppet:puppet'], },
        }
      PUPPETCODE
      it 'starts' do
        apply_manifest(pp_three, catch_failures: true)
      end

      it 'has stats listening on each port' do
        %w[9090 9091].each do |port|
          shell("/usr/bin/curl -u puppet:puppet localhost:#{port}") do |r|
            r.stdout.should =~ %r{HAProxy}
            r.exit_code.should == 0
          end
        end
      end
    end
  end

  # C9934
  describe 'uninstalling haproxy' do
    pp_four = <<-PUPPETCODE
        class { 'haproxy':
          package_ensure => 'absent',
          service_ensure => 'stopped',
        }
    PUPPETCODE
    it 'removes it' do
      apply_manifest(pp_four, catch_failures: true)
    end
    describe package('haproxy') do
      it { is_expected.not_to be_installed }
    end
  end

  # C9935 C9939
  describe 'disabling haproxy' do
    pp_five = <<-PUPPETCODE
        class { 'haproxy':
          service_ensure => 'stopped',
        }
        haproxy::listen { 'stats':
          ipaddress => '127.0.0.1',
          ports     => '9090',
        }
    PUPPETCODE
    it 'stops the service' do
      apply_manifest(pp_five, catch_failures: true)
    end
    describe service('haproxy') do
      it { is_expected.not_to be_running }
      it { is_expected.not_to be_enabled }
    end
  end
end
