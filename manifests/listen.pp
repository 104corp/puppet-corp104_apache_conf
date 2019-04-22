define corp104_apache_conf::listen (
  $listen_addr_port = $name,
  $ports_file = $corp104_apache_conf::ports_file,
) {
  # Template uses: $listen_addr_port
  concat::fragment { "Listen ${listen_addr_port}":
    target  => $ports_file,
    content => template('corp104_apache_conf/listen.erb'),
  }
}
