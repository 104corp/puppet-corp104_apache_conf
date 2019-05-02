# Class corp104_apache_conf::mod::security
#
# Manages mod_security module
#
class corp104_apache_conf::mod::security (
  $httpd_dir                   = $corp104_apache_conf::httpd_dir,
  $conf_dir                    = $corp104_apache_conf::conf_dir,
  $file_mode                   = $corp104_apache_conf::file_mode,
  $mod_security_conf           = $corp104_apache_conf::mod_security_conf,
  $mod_security_rules          = $corp104_apache_conf::mod_security_rules,
){
  # File resource common parameters
  File {
    ensure  => file,
    mode    => $file_mode,
  }

  # Workers file
  # Template uses:
  # - $mod_security_rules
  $mod_security_path = $mod_security_conf ? {
    /^\//   => $mod_security_conf,
    default => "${httpd_dir}/${mod_security_conf}",
  }
  file { $mod_security_path:
    path    => $mod_security_path,
    content => template('corp104_apache_conf/mod/security.conf.erb'),
  }

}
