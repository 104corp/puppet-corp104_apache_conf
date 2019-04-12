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
  $conf_file           = $corp104_apache_conf::conf_file,
  $conf_dir            = $corp104_apache_conf::conf_dir,
) {
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
  concat::fragment { "${name}-mod-worker":
    target  => "$conf_dir/$conf_file",
    order   => 1,
    content => template('corp104_apache_conf/mod/worker.erb'),
    require => Concat["$conf_dir/$conf_file"],
  }
}
