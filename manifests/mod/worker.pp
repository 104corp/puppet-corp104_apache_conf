class corp104_apache_conf::mod::worker (
  $startservers        = '1',
  $maxclients          = '200',
  $minsparethreads     = '10',
  $maxsparethreads     = '10',
  $threadsperchild     = '10',
  $maxrequestsperchild = '1000',
  $serverlimit         = '20',
  $threadlimit         = '1000',
  $apache_version      = undef,
  $root_group          = 'root',
  $file_mode           = '0644',
  $mod_dir             = $corp104_apache_conf::mod_dir,
) {
  File {
    owner => 'root',
    group => $root_group,
    mode  => $file_mode,
  }

  # Template uses:
  # - $startservers
  # - $maxclients
  # - $minsparethreads
  # - $maxsparethreads
  # - $threadsperchild
  # - $maxrequestsperchild
  # - $serverlimit
  # - $threadLimit
  # - $listenbacklog
  file { "$mod_dir/worker.conf":
    ensure  => file,
    content => template('corp104_apache_conf/mod/worker.conf.erb'),
    require => Exec["mkdir $mod_dir"],
    before  => File[$mod_dir],
  }

}
