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
  $mod_dir                = $corp104_apache_conf::mod_dir,
) {

  if versioncmp($_apache_version, '2.3.13') < 0 {
    if $maxrequestworkers == undef {
      warning("For newer versions of Apache, \$maxclients is deprecated, please use \$maxrequestworkers.")
    } elsif $maxconnectionsperchild == undef {
      warning("For newer versions of Apache, \$maxrequestsperchild is deprecated, please use \$maxconnectionsperchild.")
    }
  }

  File {
    owner => 'root',
    group => $root_group,
    mode  => $file_mode,
  }

  # Template uses:
  # - $startservers
  # - $minspareservers
  # - $maxspareservers
  # - $serverlimit
  # - $maxclients
  # - $maxrequestworkers
  # - $maxrequestsperchild
  # - $maxconnectionsperchild
  file { "$mod_dir/prefork.conf":
    ensure  => file,
    content => template('corp104_apache_conf/mod/prefork.conf.erb'),
    require => Exec["mkdir $mod_dir"],
    before  => File[$mod_dir],
  }

}
