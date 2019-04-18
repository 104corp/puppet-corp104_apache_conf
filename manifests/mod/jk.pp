# Class apache::mod::jk
#
# Manages mod_jk connector
#
# All parameters are optional. When undefined, some receive default values,
# while others cause an optional directive to be absent
#
# For help on parameters, pls see official reference at:
# https://tomcat.apache.org/connectors-doc/reference/apache.html
#
class corp104_apache_conf::mod::jk (
  $httpd_dir                   = $corp104_apache_conf::httpd_dir,
  $conf_dir                    = $corp104_apache_conf::conf_dir,
  $file_mode                   = $corp104_apache_conf::file_mode,
  $logroot                     = $corp104_apache_conf::logroot,
  # Conf file content
  $workers_file                = undef,
  $shm_file                    = 'jk-runtime-status',
  $shm_size                    = undef,
  $mount_file                  = undef,
  $mount_file_reload           = undef,
  $log_file                    = 'mod_jk.log',
  $log_level                   = undef,
  $request_log_format          = undef,
  # Workers file content
  # See comments in template mod/jk/workers.properties.erb
  $workers_file_content        = {},
  # Mount file content
  # See comments in template mod/jk/uriworkermap.properties.erb
  $mount_file_content          = {},
){
  # Ensure that we are not using variables with the typo fixed by MODULES-6225
  # anymore:
  if !empty($workers_file_content) and has_key($workers_file_content, 'worker_mantain') {
    fail('Please replace $workers_file_content[\'worker_mantain\'] by $workers_file_content[\'worker_maintain\']. See MODULES-6225 for details.')
  }

  # File resource common parameters
  File {
    ensure  => file,
    mode    => $file_mode,
  }

  # Shared memory and log paths
  $log_dir = $httpd_dir

  # If absolute path or pipe, use as-is
  # If relative path, prepend with log directory
  # If unspecified, use default
  $shm_path = $shm_file ? {
    undef       => "${log_dir}/jk-runtime-status",
    /^\"?[|\/]/ => $shm_file,
    default     => "${log_dir}/${shm_file}",
  }
  $log_path = $log_file ? {
    undef       => "${log_dir}/mod_jk.log",
    /^\"?[|\/]/ => $log_file,
    default     => "${log_dir}/${log_file}",
  }

  # Main config file
  # Template uses:
  # - $workers_file
  # - $shm_path
  # - $shm_size
  # - $log_path
  # - $log_level
  # - $request_log_format
  # - $mount_file
  # - $mount_file_reload
  file {'jk.conf':
    path    => "${httpd_dir}/jk.conf",
    content => template('corp104_apache_conf/mod/jk.conf.erb'),
    require => [
      File[$conf_dir],
    ],
  }

  # Workers file
  # Template uses:
  # - $workers_file_content
  if $workers_file != undef {
    $workers_path = $workers_file ? {
      /^\//   => $workers_file,
      default => "${httpd_dir}/${workers_file}",
    }
    file { $workers_path:
      content => template('corp104_apache_conf/mod/jk/workers.properties.erb'),
    }
  }

  # Mount file
  # Template uses:
  # - $mount_file_content
  if $mount_file != undef {
    $mount_path = $mount_file ? {
      /^\//   => $mount_file,
      default => "${httpd_dir}/${mount_file}",
    }
    file { $mount_path:
      content => template('apache/mod/jk/uriworkermap.properties.erb'),
    }
  }

}
