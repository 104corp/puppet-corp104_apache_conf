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
  $apache_version                                        = $corp104_apache_conf::apache_version,
  $service_name                                          = $corp104_apache_conf::service_name,
  $httpd_dir                                             = $corp104_apache_conf::httpd_dir,
  $conf_file                                             = $corp104_apache_conf::conf_file,
  $conf_dir                                              = $corp104_apache_conf::conf_dir,
  $confd_dir                                             = $corp104_apache_conf::confd_dir,
  $mod_dir                                               = $corp104_apache_conf::mod_dir,
  $vhost_dir                                             = $corp104_apache_conf::vhost_dir,
  $logroot                                               = $corp104_apache_conf::logroot,
  $ports_file                                            = $corp104_apache_conf::ports_file,
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
  $modules                                               = $corp104_apache_conf::modules,
  $ifmodules                                             = $corp104_apache_conf::ifmodules,
  $server_name                                           = undef,
  $document_root                                         = undef,
  Enum['absent', 'present'] $ensure                      = 'present',
  Boolean $use_optional_includes                         = false,
  $vhosts                                                = $corp104_apache_conf::vhosts,
  Boolean $mod_jk                                        = true,
  $mod_jk_conf                                           = $corp104_apache_conf::mod_jk_conf,
  $httpd_languages_file                                  = $corp104_apache_conf::httpd_languages_file,
  $mime_types_file                                       = $corp104_apache_conf::mime_types_file,
  $main_directories                                      = $corp104_apache_conf::main_directories,
  Boolean $mod_security                                  = true,
  $mod_security_conf                                     = $corp104_apache_conf::mod_security_conf,
  $mod_security_rules                                    = $corp104_apache_conf::mod_security_rules,
) {

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  exec { "mkdir $httpd_dir":
    creates => $httpd_dir,
    onlyif  => "test ! -d ${httpd_dir}"
  }

  #if ! defined(File[$httpd_dir]) {
  #  file { $httpd_dir:
  #    ensure  => directory,
  #    recurse => false,
  #    purge   => false,
  #  }
  #}
  
  [$conf_dir, $confd_dir, $mod_dir, $vhost_dir, $logroot].each |String $dir| {
    if ! defined(File[$dir]) {
      file { $dir:
        ensure  => directory,
        recurse => false,
        purge   => false,
        require => Exec["mkdir $httpd_dir"],
        #require => File[$httpd_dir],
      }
    }
  }

  if $httpd_languages_file {
    $httpd_languages_path = $httpd_languages_file ? {
      /^\//   => $httpd_languages_file,
      default => "${httpd_dir}/${httpd_languages_file}",
    }
    file {"${httpd_languages_path}":
      content => file('corp104_apache_conf/httpd-languages.conf'),
    }
  }
  if $mime_types_file {
    $mime_types_path = $mime_types_file ? {
      /^\//   => $mime_types_file,
      default => "${httpd_dir}/${mime_types_file}",
    }
    file {"${mime_types_path}":
      content => file('corp104_apache_conf/mime.types'),
    }
  }

  concat { $ports_file:
    ensure  => present,
    owner   => 'root',
    group   => $root_group,
    mode    => $file_mode,
  }
  concat::fragment { 'Apache ports header':
    target  => $ports_file,
    content => template('corp104_apache_conf/ports_header.erb'),
  }

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

  include corp104_apache_conf::mod::worker
  include corp104_apache_conf::mod::prefork

  # Template uses:
  # - $modules
  # - $ifmodules
  concat::fragment { "${name}-load_module":
    target  => "$conf_dir/$conf_file",
    order   => 20,
    content => template('corp104_apache_conf/load_module.erb'),
  }

  if $mod_jk {
    include corp104_apache_conf::mod::jk
  }

  if $mod_security {
    include corp104_apache_conf::mod::security
  }

  # Template uses:
  concat::fragment { "${name}-not_mpm":
    target  => "$conf_dir/$conf_file",
    order   => 30,
    content => template('corp104_apache_conf/not_mpm.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-main_server":
    target  => "$conf_dir/$conf_file",
    order   => 40,
    content => template('corp104_apache_conf/main_server.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-log_conf":
    target  => "$conf_dir/$conf_file",
    order   => 50,
    content => template('corp104_apache_conf/log_conf.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-alias":
    target  => "$conf_dir/$conf_file",
    order   => 60,
    content => template('corp104_apache_conf/alias.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-cgi":
    target  => "$conf_dir/$conf_file",
    order   => 70,
    content => template('corp104_apache_conf/cgi.erb'),
  }

  # Template uses:
  # - $mime_types_file
  concat::fragment { "${name}-mime":
    target  => "$conf_dir/$conf_file",
    order   => 80,
    content => template('corp104_apache_conf/mime.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-custom_error":
    target  => "$conf_dir/$conf_file",
    order   => 90,
    content => template('corp104_apache_conf/custom_error.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-mmap_sendfile":
    target  => "$conf_dir/$conf_file",
    order   => 100,
    content => template('corp104_apache_conf/mmap_sendfile.erb'),
  }

  # Template uses:
  # - $httpd_languages_file
  concat::fragment { "${name}-include_conf":
    target  => "$conf_dir/$conf_file",
    order   => 110,
    content => template('corp104_apache_conf/include_conf.erb'),
  }

  # Template uses:
  concat::fragment { "${name}-httpd_footer":
    target  => "$conf_dir/$conf_file",
    order   => 120,
    content => template('corp104_apache_conf/httpd_footer.erb'),
  }

  if $vhosts {
    create_resources('corp104_apache_conf::vhost', $vhosts)
  }
}
