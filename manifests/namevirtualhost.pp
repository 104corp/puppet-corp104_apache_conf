define corp104_apache_conf::namevirtualhost (
  $addr_port = $name
  $ports_file = $corp104_apache_conf::ports_file,
) {
  # Template uses: $addr_port
  concat::fragment { "NameVirtualHost ${addr_port}":
    target  => $ports_file,
    content => template('corp104_apache_conf/namevirtualhost.erb'),
  }
}
