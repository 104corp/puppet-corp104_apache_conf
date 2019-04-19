define apache::mod (
  $lib            = undef,
  $lib_path       = $::apache::lib_path,
  $id             = undef,
  $path           = undef,
  $loadfile_name  = undef,
  $loadfiles      = undef,
) {

  $mod = $name
  #include apache #This creates duplicate resources in rspec-puppet
  $mod_dir = $::apache::mod_dir

  # Determine if we have special lib
  $mod_libs = $::apache::mod_libs
  if $lib {
    $_lib = $lib
  } elsif has_key($mod_libs, $mod) { # 2.6 compatibility hack
    $_lib = $mod_libs[$mod]
  } else {
    $_lib = "mod_${mod}.so"
  }

  # Determine if declaration specified a path to the module
  if $path {
    $_path = $path
  } else {
    $_path = "${lib_path}/${_lib}"
  }

  if $id {
    $_id = $id
  } else {
    $_id = "${mod}_module"
  }

  if $loadfile_name {
    $_loadfile_name = $loadfile_name
  } else {
    $_loadfile_name = "${mod}.load"
  }

  file { $_loadfile_name:
    ensure  => file,
    path    => "${mod_dir}/${_loadfile_name}",
    owner   => 'root',
    group   => $::apache::params::root_group,
    mode    => $::apache::file_mode,
    content => template('apache/mod/load.erb'),
    require => [
      Exec["mkdir ${mod_dir}"],
    ],
    before  => File[$mod_dir],
  }

}
