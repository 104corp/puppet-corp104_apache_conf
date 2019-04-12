# Class: corp104_apache_conf
#
# Full description of class corp104_nginx_stub_exporter here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# Examples
# --------
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2017 Your name here, unless otherwise noted.
#
class corp104_apache_conf (
  $apache_name                                           = $corp104_apache_conf::apache_name,
  $service_name                                          = $corp104_apache_conf::service_name,
  $httpd_dir                                             = $corp104_apache_conf::httpd_dir,
  $conf_file                                             = $corp104_apache_conf::conf_file,
  $conf_dir                                              = $corp104_apache_conf::conf_dir,
  $confd_dir                                             = $corp104_apache_conf::confd_dir,
  $root_group                                            = $corp104_apache_conf::root_group,
  $file_mode                                             = $corp104_apache_conf::file_mode,
  $server_root                                           = $corp104_apache_conf::server_root,
  $pid_file                                              = $corp104_apache_conf::pid_file,
  $timeout                                               = $corp104_apache_conf::timeout,
  $keepalive                                             = $corp104_apache_conf::keepalive,
  $max_keepalive_requests                                = $corp104_apache_conf::max_keepalive_requests,
  $keepalive_timeout                                     = $corp104_apache_conf::keepalive_timeout,
  $hostname_lookups                                      = $corp104_apache_conf::hostname_lookups,
  $use_canonical_name                                    = $corp104_apache_conf::use_canonical_name,
  $access_file_name                                      = $corp104_apache_conf::access_file_name,
  $server_tokens                                         = $corp104_apache_conf::server_tokens,
  $server_signature                                      = $corp104_apache_conf::server_signature,
  $index_options                                         = $corp104_apache_conf::index_options,
  $server_admin                                          = $corp104_apache_conf::server_admin,
  $server_name                                           = undef,
  $document_root                                         = undef,
  Enum['absent', 'present'] $ensure                      = 'present',
) {

  concat { "$conf_dir/$conf_file":
    ensure  => $ensure,
    path    => "$conf_dir/$conf_file",
    owner   => 'root',
    group   => $root_group,
    mode    => $file_mode,
    order   => 'numeric',
  }

  # Template uses:
  # - $server_root
  # - pid_file
  # - timeout
  # - keepalive
  # - max_keepalive_requests
  # - keepalive_timeout
  # - hostname_lookups
  # - use_canonical_name
  # - access_file_name
  # - server_tokens
  # - server_signature
  concat::fragment { "${name}-httpd_header":
    target  => "$conf_dir/$conf_file",
    order   => 0,
    content => template('corp104_apache_conf/httpd_header.erb'),
  }

  # Template uses:
  # - $listen_addr_ports
  concat::fragment { "${name}-listen":
    target  => "$conf_dir/$conf_file",
    order   => 3,
    content => template('corp104_apache_conf/listen.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-load_module":
    target  => "$conf_dir/$conf_file",
    order   => 4,
    content => template('corp104_apache_conf/load_module.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-not_mpm":
    target  => "$conf_dir/$conf_file",
    order   => 5,
    content => template('corp104_apache_conf/not_mpm.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-main_server":
    target  => "$conf_dir/$conf_file",
    order   => 6,
    content => template('corp104_apache_conf/main_server.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-log_conf":
    target  => "$conf_dir/$conf_file",
    order   => 7,
    content => template('corp104_apache_conf/log_conf.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-alias":
    target  => "$conf_dir/$conf_file",
    order   => 10,
    content => template('corp104_apache_conf/alias.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-cgi":
    target  => "$conf_dir/$conf_file",
    order   => 11,
    content => template('corp104_apache_conf/cgi.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-mime":
    target  => "$conf_dir/$conf_file",
    order   => 12,
    content => template('corp104_apache_conf/mime.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-custom_error":
    target  => "$conf_dir/$conf_file",
    order   => 13,
    content => template('corp104_apache_conf/custom_error.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-mmap_sendfile":
    target  => "$conf_dir/$conf_file",
    order   => 14,
    content => template('corp104_apache_conf/mmap_sendfile.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-include_conf":
    target  => "$conf_dir/$conf_file",
    order   => 14,
    content => template('corp104_apache_conf/include_conf.erb'),
  }

}
