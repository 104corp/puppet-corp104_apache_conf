# Class: corp104_apache_conf::vhost
define corp104_apache_conf::vhost(
  Variant[Boolean,String] $docroot,
  $port                                                  = undef,
  $ip                                                    = undef,
  Boolean $ip_based                                      = false,
  Boolean $add_listen                                    = true,
  $docroot_owner                                         = 'root',
  $serveradmin                                           = undef,
  $directoryindex                                        = '',
  Boolean $ssl                                           = false,
  $ssl_cert                                              = undef,
  $ssl_key                                               = undef,
  $ssl_chain                                             = undef,
  $ssl_protocol                                          = undef,
  $ssl_cipher                                            = undef,
  Boolean $default_vhost                                 = false,
  $servername                                            = $name,
  $serveraliases                                         = [],
  $options                                               = ['Indexes','FollowSymLinks','MultiViews'],
  $override                                              = ['None'],
  $vhost_name                                            = '*',
  Enum['absent', 'present'] $ensure                      = 'present',
  $vhost_dir                                             = $corp104_apache_conf::vhost_dir,
  $additional_includes                                   = [],
  $use_optional_includes                                 = $corp104_apache_conf::use_optional_includes,
  $apache_version                                        = $corp104_apache_conf::apache_version,
  $root_group                                            = $corp104_apache_conf::root_group,
  $file_mode                                             = $corp104_apache_conf::file_mode,
  # $access_logs = [{'file' => '', 'format' => '', 'env' => ''}]
  Optional[Array] $access_logs                           = undef,
  $aliases                                               = undef,
  $logroot                                               = $corp104_apache_conf::logroot,
  $log_level                                             = undef,
  Boolean $error_log                                     = true,
  $error_log_file                                        = undef,
  # $error_documents[{'error_code' => '', 'document' => ''}]
  $error_documents                                       = [],
  $headers                                               = undef,
  $request_headers                                       = undef,
  $proxy_pass                                            = undef,
  Optional[Array] $rewrites                              = undef,
  $scriptalias                                           = undef,
  $scriptaliases                                         = [],
  $setenv                                                = [],
  $setenvif                                              = [],
  $setenvifnocase                                        = [],
  Boolean $ssl_proxyengine                               = false,
  Optional[Enum['none', 'optional', 'require', 'optional_no_ca']] $ssl_proxy_verify = undef,
  $php_flags                                             = {},
  $php_values                                            = {},
  $php_admin_flags                                       = {},
  $php_admin_values                                      = {},
  $deflates                                              = undef,
  $securities                                            = undef,
  $add_default_charset                                   = undef,
  $locations                                             = undef,
  Optional[Variant[Hash, Array[Variant[Array,Hash]]]] $directories = undef,
  $jk_mounts                                             = undef,
  Optional[Enum['on', 'off']] $keepalive                 = undef,
  $keepalive_timeout                                     = undef,
  $max_keepalive_requests                                = undef,
  Optional[Enum['On', 'on', 'Off', 'off', 'DNS', 'dns']] $use_canonical_name = undef,
) {
  # The base class must be included first because it is used by parameter defaults
  if ! defined(Class['corp104_apache_conf']) {
    fail('You must include the corp104_apache_conf base class before using any corp104_apache_conf defined resources')
  }

  ## Apache include does not always work with spaces in the filename
  $filename = regsubst($name, ' ', '_', 'G')

  if $access_logs {
    $_access_logs = $access_logs
  }

  if $error_log_file {
    if $error_log_file =~ /^\// {
      # Absolute path provided - don't prepend $logroot
      $error_log_destination = $error_log_file
    } else {
      $error_log_destination = "${logroot}/${error_log_file}"
    }
  } else {
    if $ssl {
      $error_log_destination = "${logroot}/${name}_error_ssl.log"
    } else {
      $error_log_destination = "${logroot}/${name}_error.log"
    }
  }

  if $ip {
    $_ip = any2array(enclose_ipv6($ip))
    if $port {
      $_port = any2array($port)
      $listen_addr_port = split(inline_template("<%= @_ip.product(@_port).map {|x| x.join(':')  }.join(',')%>"), ',')
      $nvh_addr_port = split(inline_template("<%= @_ip.product(@_port).map {|x| x.join(':')  }.join(',')%>"), ',')
    } else {
      $listen_addr_port = undef
      $nvh_addr_port = $_ip
      if ! $servername and ! $ip_based {
        fail("corp104_apache_conf::Vhost[${name}]: must pass 'ip' and/or 'port' parameters for name-based vhosts")
      }
    }
  } else {
    if $port {
      $listen_addr_port = $port
      $nvh_addr_port = prefix(any2array($port),"${vhost_name}:")
    } else {
      $listen_addr_port = undef
      $nvh_addr_port = $name
      if ! $servername and $servername != '' {
        fail("corp104_apache_conf::Vhost[${name}]: must pass 'ip' and/or 'port' parameters, and/or 'servername' parameter")
      }
    }
  }

  if $add_listen {
    if $ip and defined(Corp104_apache_conf::Listen[String($port)]) {
      fail("Corp104_Apache_conf::Vhost[${name}]: Mixing IP and non-IP Listen directives is not possible; check the add_listen parameter define to disable this")
    }
    if $listen_addr_port and $ensure == 'present' {
      ensure_resource('corp104_apache_conf::listen', $listen_addr_port)
    }
  }

  if ! $ip_based {
    if $ensure == 'present' and (versioncmp($apache_version, '2.4') < 0) {
      ensure_resource('corp104_apache_conf::namevirtualhost', $nvh_addr_port)
    }
  }

  concat { "${vhost_dir}/${filename}.conf":
    ensure  => $ensure,
    path    => "${vhost_dir}/${filename}.conf",
    owner   => 'root',
    group   => $root_group,
    mode    => $file_mode,
    order   => 'numeric',
  }

  # Template uses:
  # - $nvh_addr_port
  # - $servername
  # - $serveradmin
  # - $directoryindex
  concat::fragment { "${name}-apache-header":
    target  => "${vhost_dir}/${filename}.conf",
    order   => 1,
    content => template('corp104_apache_conf/vhost/_file_header.erb'),
  }

  # Template uses:
  # - $docroot
  if $docroot {
    concat::fragment { "${name}-docroot":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 10,
      content => template('corp104_apache_conf/vhost/_docroot.erb'),
    }
  }

  # Template uses:
  # - $aliases
  if $aliases and ! empty($aliases) {
    concat::fragment { "${name}-aliases":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 20,
      content => template('corp104_apache_conf/vhost/_aliases.erb'),
    }
  }

  # Template uses:
  # - $additional_includes
  # - $use_optional_includes
  # - $apache_version
  if $additional_includes and ! empty($additional_includes) {
    concat::fragment { "${name}-additional_includes":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 70,
      content => template('corp104_apache_conf/vhost/_additional_includes.erb'),
    }
  }

  # Template uses:
  # - $error_log
  # - $log_level
  # - $error_log_destination
  if $error_log or $log_level {
    concat::fragment { "${name}-logging":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 80,
      content => template('corp104_apache_conf/vhost/_logging.erb'),
    }
  }

  # Template uses no variables
  concat::fragment { "${name}-serversignature":
    target  => "${vhost_dir}/${filename}.conf",
    order   => 90,
    content => template('corp104_apache_conf/vhost/_serversignature.erb'),
  }

  # Template uses:
  # - $_access_logs
  # - $_access_logs[]['env']
  # - $_access_logs[]['format']
  # - $_access_logs[]['file']
  # - $logroot
  # - $ssl
  if $access_logs {
    concat::fragment { "${name}-access_log":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 100,
      content => template('corp104_apache_conf/vhost/_access_log.erb'),
    }
  }

  # Template uses:
  # - $error_documents
  # - $error_documents[]['error_code']
  # - $error_documents[]['document']
  if $error_documents and ! empty($error_documents) {
    concat::fragment { "${name}-error_document":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 130,
      content => template('corp104_apache_conf/vhost/_error_document.erb'),
    }
  }

  # Template uses:
  # - $headers
  if $headers and ! empty($headers) {
    concat::fragment { "${name}-header":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 140,
      content => template('corp104_apache_conf/vhost/_header.erb'),
    }
  }

  # Template uses:
  # - $request_headers
  if $request_headers and ! empty($request_headers) {
    concat::fragment { "${name}-requestheader":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 150,
      content => template('corp104_apache_conf/vhost/_requestheader.erb'),
    }
  }

  # Template uses:
  # - $proxy_pass
  # - $proxy_pass[]['no_proxy_uris']
  # - $proxy_pass[]['no_proxy_uris_match']
  # - $proxy_pass[]['path']
  # - $proxy_pass[]['url']
  # - $proxy_pass[]['params']
  # - $proxy_pass[]['keywords']
  # - $proxy_pass[]['reverse_urls']
  # - $proxy_pass[]['setenv']
  if $proxy_pass {
    concat::fragment { "${name}-proxy":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 160,
      content => template('corp104_apache_conf/vhost/_proxy.erb'),
    }
  }

  # Template uses:
  # - $rewrites
  # - $rewrites[]['rewrite_base']
  # - $rewrites[]['rewrite_cond']
  # - $rewrites[]['rewrite_rule']
  if $rewrites {
    concat::fragment { "${name}-rewrite":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 190,
      content => template('corp104_apache_conf/vhost/_rewrite.erb'),
    }
  }

  # Template uses:
  # - $scriptaliases
  # - $scriptalias
  if ( $scriptalias or $scriptaliases != [] ) {
    concat::fragment { "${name}-scriptalias":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 200,
      content => template('corp104_apache_conf/vhost/_scriptalias.erb'),
    }
  }

  # Template uses:
  # - $serveraliases
  if $serveraliases and ! empty($serveraliases) {
    concat::fragment { "${name}-serveralias":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 210,
      content => template('corp104_apache_conf/vhost/_serveralias.erb'),
    }
  }

  # Template uses:
  # - $setenv
  # - $setenvif
  # - $setenvifnocase
  if ($setenv and ! empty($setenv)) or ($setenvif and ! empty($setenvif)) or ($setenvifnocase and ! empty($setenvifnocase)) {
    concat::fragment { "${name}-setenv":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 220,
      content => template('corp104_apache_conf/vhost/_setenv.erb'),
    }
  }

  # Template uses:
  # - $ssl
  # - $ssl_cert
  # - $ssl_key
  # - $ssl_chain
  # - $ssl_protocol
  # - $ssl_cipher
  if $ssl {
    concat::fragment { "${name}-ssl":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 230,
      content => template('corp104_apache_conf/vhost/_ssl.erb'),
    }
  }

  # Template uses:
  # - $ssl_proxyengine
  # - $ssl_proxy_verify
  if $ssl_proxyengine {
    concat::fragment { "${name}-sslproxy":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 230,
      content => template('corp104_apache_conf/vhost/_sslproxy.erb'),
    }
  }

  # Template uses:
  # - $php_values
  # - $php_flags
  if ($php_values and ! empty($php_values)) or ($php_flags and ! empty($php_flags)) {
    concat::fragment { "${name}-php":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 240,
      content => template('corp104_apache_conf/vhost/_php.erb'),
    }
  }

  # Template uses:
  # - $php_admin_values
  # - $php_admin_flags
  if ($php_admin_values and ! empty($php_admin_values)) or ($php_admin_flags and ! empty($php_admin_flags)) {
    concat::fragment { "${name}-php_admin":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 250,
      content => template('corp104_apache_conf/vhost/_php_admin.erb'),
    }
  }

  # Template uses:
  # - $securities
  if ($securities and ! empty($securities)) {
    concat::fragment { "${name}-security":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 270,
      content => template('corp104_apache_conf/vhost/_security.erb'),
    }
  }

  # Template uses:
  # - $deflates
  if ($deflates and ! empty($deflates)) {
    concat::fragment { "${name}-deflates":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 280,
      content => template('corp104_apache_conf/vhost/_deflate.erb'),
    }
  }

  # Template uses:
  # - $add_default_charset
  if $add_default_charset {
    concat::fragment { "${name}-charsets":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 310,
      content => template('corp104_apache_conf/vhost/_charsets.erb'),
    }
  }

  # Template uses:
  # - $jk_mounts
  if $jk_mounts and ! empty($jk_mounts) {
    concat::fragment { "${name}-jk_mounts":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 330,
      content => template('corp104_apache_conf/vhost/_jk_mounts.erb'),
    }
  }

  # Template uses:
  # - $locations
  if $locations and ! empty($locations) {
    concat::fragment { "${name}-locations":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 340,
      content => template('corp104_apache_conf/vhost/_locations.erb'),
    }
  }

  # Template uses:
  # - $directories
  if $directories and ! empty($directories) {
    concat::fragment { "${name}-directories":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 345,
      content => template('corp104_apache_conf/vhost/_directories.erb'),
    }
  }

  # Template uses:
  # - $keepalive
  # - $keepalive_timeout
  # - $max_keepalive_requests
  if $keepalive or $keepalive_timeout or $max_keepalive_requests {
    concat::fragment { "${name}-keepalive_options":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 350,
      content => template('corp104_apache_conf/vhost/_keepalive_options.erb'),
    }
  }

  # - $use_canonical_name
  if $use_canonical_name {
    concat::fragment { "${name}-use_canonical_name":
      target  => "${vhost_dir}/${filename}.conf",
      order   => 360,
      content => template('corp104_apache_conf/vhost/_use_canonical_name.erb'),
    }
  }

  # Template uses no variables
  concat::fragment { "${name}-file_footer":
    target  => "${vhost_dir}/${filename}.conf",
    order   => 999,
    content => template('corp104_apache_conf/vhost/_file_footer.erb'),
  }

}
