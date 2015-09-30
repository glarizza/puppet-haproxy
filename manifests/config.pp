# Private class
class haproxy::config inherits haproxy {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $haproxy::merge_options {
    $_global_options   = merge($haproxy::params::global_options, $haproxy::global_options)
    $_defaults_options = merge($haproxy::params::defaults_options, $haproxy::defaults_options)
  } else {
    $_global_options   = $haproxy::global_options
    $_defaults_options = $haproxy::defaults_options
    warning("${module_name}: The \$merge_options parameter will default to true in the next major release. Please review the documentation regarding the implications.")
  }

  concat { $haproxy::config_file:
    owner => '0',
    group => '0',
    mode  => '0644',
  }

  # Simple Header
  concat::fragment { '00-header':
    target  => $haproxy::config_file,
    order   => '01',
    content => "# This file managed by Puppet\n",
  }

  # Template uses $global_options, $defaults_options
  concat::fragment { 'haproxy-base':
    target  => $haproxy::config_file,
    order   => '10',
    content => template('haproxy/haproxy-base.cfg.erb'),
  }

  if $_global_options['chroot'] {
    file { $_global_options['chroot']:
      ensure => directory,
      owner  => $_global_options['user'],
      group  => $_global_options['group'],
    }
  }
}
