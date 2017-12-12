require 'spec_helper'

describe 'haproxy::resolver' do
  let(:pre_condition) { 'include haproxy' }
  let(:facts) do
    {
      ipaddress: '1.1.1.1',
      concat_basedir: '/dne',
      osfamily: 'RedHat',
    }
  end

  context 'with two resolvers' do
    let(:title) { 'bar' }
    let(:params) do
      {
        nameservers: { 'dns1' => '1.1.1.1:53', 'dns2' => '1.1.1.2:53' },
        hold: { 'other' => '30s', 'refused' => '30s', 'nx' => '30s', 'timeout' => '30s', 'valid' => '10s' },
        resolve_retries: 3,
        timeout: { 'retry' => '1s' },
      }
    end

    it {
      is_expected.to contain_concat__fragment('haproxy-bar_resolver_block').with(
        'order'   => '20-bar-01',
        'target'  => '/etc/haproxy/haproxy.cfg',
        'content' => "\nresolvers bar\n  nameserver dns1 1.1.1.1:53\n  nameserver dns2 1.1.1.2:53\n  resolve_retries 3\n  timeout retry 1s\n  hold other 30s\n  hold refused 30s\n  hold nx 30s\n  hold timeout 30s\n  hold valid 10s\n", # rubocop:disable Metrics/LineLength
      )
    }
  end
end
