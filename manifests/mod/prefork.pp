class corp104_apache_conf::mod::prefork (
  $startservers           = '10',
  $minspareservers        = '10',
  $maxspareservers        = '50',
  $serverlimit            = '256',
  $maxclients             = '256',
  $maxrequestworkers      = undef,
  $maxrequestsperchild    = '1000',
  $maxconnectionsperchild = undef,
  $apache_version         = undef,
  $root_group             = 'root',
  $file_mode              = '0644',
) {
  # Template uses:
  # - $startservers
  # - $minspareservers
  # - $maxspareservers
  # - $serverlimit
  # - $maxclients
  # - $maxrequestworkers
  # - $maxrequestsperchild
  # - $maxconnectionsperchild
  concat::fragment { "${name}-mod-prefork":
    target  => "$conf_dir/$conf_file",
    order   => 2,
    content => template('corp104_apache_conf/mod/prefork.erb'),
  }
}
