require 'beaker-pe'
require 'beaker-puppet'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper
configure_type_defaults_on(hosts)

def idempotent_apply(hosts, manifest, opts = {}, &block)
  block_on hosts, opts do |host|
    file_path = host.tmpfile('apply_manifest.pp')
    create_remote_file(host, file_path, manifest + "\n")

    puppet_apply_opts = { :verbose => nil, 'detailed-exitcodes' => nil }
    on_options = { acceptable_exit_codes: [0, 2] }
    on host, puppet('apply', file_path, puppet_apply_opts), on_options, &block
    puppet_apply_opts2 = { :verbose => nil, 'detailed-exitcodes' => nil }
    on_options2 = { acceptable_exit_codes: [0] }
    on host, puppet('apply', file_path, puppet_apply_opts2), on_options2, &block
  end
end

UNSUPPORTED_PLATFORMS = ['RedHat', 'Suse', 'windows', 'AIX', 'Solaris'].freeze
MAX_RETRY_COUNT       = 12
RETRY_WAIT            = 10
ERROR_MATCHER         = %r{(no valid OpenPGP data found|keyserver timed out|keyserver receive failed)}

# This method allows a block to be passed in and if an exception is raised
# that matches the 'error_matcher' matcher, the block will wait a set number
# of seconds before retrying.
# Params:
# - max_retry_count - Max number of retries
# - retry_wait_interval_secs - Number of seconds to wait before retry
# - error_matcher - Matcher which the exception raised must match to allow retry
# Example Usage:
# retry_on_error_matching(3, 5, /OpenGPG Error/) do
#   apply_manifest(pp, :catch_failures => true)
# end
def retry_on_error_matching(max_retry_count = MAX_RETRY_COUNT, retry_wait_interval_secs = RETRY_WAIT, error_matcher = ERROR_MATCHER)
  try = 0
  begin
    puts "retry_on_error_matching: try #{try}" unless try.zero?
    try += 1
    yield
  rescue StandardError => e
    raise unless try < max_retry_count && (error_matcher.nil? || e.message =~ error_matcher)
    sleep retry_wait_interval_secs
    retry
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(source: proj_root, module_name: 'haproxy')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-concat'), acceptable_exit_codes: [0, 1]
      if fact('osfamily') == 'RedHat'
        on host, puppet('module', 'install', 'stahnma/epel'), acceptable_exit_codes: [0, 1]
      end
      if fact('operatingsystem') == 'Debian'
        on host, puppet('module', 'install', 'puppetlabs-apt'), acceptable_exit_codes: [0, 1]
        apply_manifest(%(
          include apt
          include apt::backports
        ))
      end
      pp = <<-PUPPETCODE
        package { 'socat': ensure => present, }
        package { 'screen': ensure => present, }
        if $::osfamily == 'RedHat' {
          if $::operatingsystemmajrelease == '5' or ($::operatingsystem == 'OracleLinux' and $::operatingsystemmajrelease == '6'){
            class { 'epel':
              epel_baseurl => "http://osmirror.delivery.puppetlabs.net/epel${::operatingsystemmajrelease}-\\$basearch/RPMS.all",
              epel_mirrorlist => "http://osmirror.delivery.puppetlabs.net/epel${::operatingsystemmajrelease}-\\$basearch/RPMS.all",
              before => Package['socat'],
            }
          } else {
            class { 'epel':
              before => Package['socat'],
            }
          }
          service { 'iptables': ensure => stopped, }
          exec { 'setenforce 0':
            path   => ['/bin','/usr/bin','/sbin','/usr/sbin'],
            onlyif => 'which getenforce && getenforce | grep Enforcing',
          }
        }
        if ($::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7') or ($::osfamily == 'Debian' and ($::operatingsystemmajrelease == '9' or $::operatingsystemmajrelease == '18.04')) {
          # For `netstat` for serverspec
          package { 'net-tools': ensure => present, }
        }
      PUPPETCODE
      apply_manifest(pp, catch_failures: true)

      ['5556', '5557'].each do |port|
        content = "socat -v tcp-l:#{port},reuseaddr,fork system:\"printf \\'HTTP/1.1 200 OK\r\n\r\nResponse on #{port}\\'\",nofork"
        create_remote_file(host, "/root/script-#{port}.sh", content)
        shell(%(/usr/bin/screen -dmS script-#{port} sh /root/script-#{port}.sh))
        sleep 1
        shell(%(netstat -tnl|grep ':#{port}'))
      end
    end
  end

  # FM-5470, this was added to reset failed count and work around puppet 3.x
  if (fact('operatingsystem') == 'SLES' && fact('operatingsystemmajrelease') == '12') || (fact('osfamily') == 'RedHat' && fact('operatingsystemmajrelease') == '7')
    c.after :each do
      # not all tests have a haproxy service, so the systemctl call can fail,
      # but we don't care as we only need to reset when it does.
      shell('systemctl reset-failed haproxy.service || true')
    end
  end
end
