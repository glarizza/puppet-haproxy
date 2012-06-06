require 'spec_helper'

describe 'haproxy' do
    let(:title) { 'haproxy.testing' }

    for osfamily in ['Debian', 'Redhat'] do
        context "on %s family operating systems" % osfamily do
            let(:facts) { { :osfamily => osfamily } }

            it { should include_class('concat::setup') }

            it 'should install the haproxy package' do
                subject.should contain_package('haproxy').with(
                    'ensure' => 'present'
                )
            end

            it 'should install the haproxy service' do
                subject.should contain_service('haproxy').with(
                    'ensure'     => 'running',
                    'enable'     => 'true',
                    'hasrestart' => 'true',
                    'hasstatus'  => 'true'
                )
            end

            it 'should set up /etc/haproxy/haproxy.cfg as a concat resource' do
                subject.should contain_concat('/etc/haproxy/haproxy.cfg').with(
                    'owner' => '0',
                    'group' => '0',
                    'mode'  => '0644'
                )
            end

            it 'should contain a haproxy-base concat fragment' do
                subject.should contain_concat__fragment('haproxy-base').with(
                    'target'  => '/etc/haproxy/haproxy.cfg',
                    'order'   => '10',
                    'content' => "global\n  chroot  /var/lib/haproxy\n  daemon  \n  group  haproxy\n  log   local0\n  maxconn  4000\n  pidfile  /var/run/haproxy.pid\n  stats  socket /var/lib/haproxy/stats\n  user  haproxy\n\ndefaults\n  log  global\n  maxconn  8000\n  option  redispatch\n  retries  3\n  stats  enable\n  timeout  http-request 10s\n  timeout  queue 1m\n  timeout  connect 10s\n  timeout  client 1m\n  timeout  server 1m\n  timeout  check 10s\n"
                )
            end
        end
    end
end
