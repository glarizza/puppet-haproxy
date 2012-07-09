node default {
  haproxy::balancermember { 'tyler':
    order                  => '20',
    listening_service      => 'croy',
    server_name            => 'dero',
    balancer_ip            => '1.1.1.1',
    balancer_port          => '18140',
    balancermember_options => 'check'
  }
}

node 'manifesthost.example.com' inherits default {
    class { 'haproxy': }
    haproxy::config { 'croy':
      virtual_ip_port => '18140'
    }
}

node 'hierahost.example.com' inherits default {
  class { 'haproxy': }
}

