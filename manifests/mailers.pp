# @summary
#  This type will set up a mailers entry in haproxy.cfg on the load balancer.
# @note
#  This setting makes it possible to send emails during state changes.
#
#
# @param instance
#   Optional. Defaults to 'haproxy'.
#
# @param collect_exported
#   Boolean. Defaults to true.
#
define haproxy::mailers (
  $collect_exported = true,
  $instance = 'haproxy',
) {

  # We derive these settings so that the caller only has to specify $instance.
  include ::haproxy::params
  if $instance == 'haproxy' {
    $instance_name = 'haproxy'
    $config_file = $::haproxy::config_file
  } else {
    $instance_name = "haproxy-${instance}"
    $config_file = inline_template($haproxy::params::config_file_tmpl)
  }

  # Template uses: $name
  concat::fragment { "${instance_name}-${name}_mailers_block":
    order   => "40-mailers-00-${name}",
    target  => $config_file,
    content => template('haproxy/haproxy_mailers_block.erb'),
  }

  if $collect_exported {
    haproxy::mailer::collect_exported { $name: }
  }
  # else: the resources have been created and they introduced their
  # concat fragments. We don't have to do anything about them.
}
