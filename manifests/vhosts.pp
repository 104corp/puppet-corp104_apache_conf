class corp104_apache_conf::vhosts (
  $vhosts = {},
) {
  include corp104_apache_conf
  create_resources('corp104_apache_conf::vhost', $vhosts)
}
