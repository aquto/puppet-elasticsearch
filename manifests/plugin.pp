# == Define: elasticsearch::plugin
#
# This define allows you to install arbitrary Elasticsearch plugins
# either by using the default repositories or by specifying an URL
#
# All default values are defined in the elasticsearch::params class.
#
#
# === Parameters
#
# [*module_dir*]
#   Directory name where the module will be installed
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*ensure*]
#   Whether the plugin will be installed or removed.
#   Set to 'absent' to ensure a plugin is not installed
#   Value type is string
#   Default value: present
#   This variable is optional
#
# [*version*]
#   What the version of the plugin is being requested 
#   Value type is string
#   Default value: "" 
#   This variable is optional
#
# [*url*]
#   Specify an URL where to download the plugin from.
#   Value type is string
#   Default value: None
#   This variable is optional
#
#
# === Examples
#
# # From official repository
# elasticsearch::plugin{'mobz/elasticsearch-head': module_dir => 'head'}
#
# # From custom url
# elasticsearch::plugin{ 'elasticsearch-jetty':
#  module_dir => 'elasticsearch-jetty',
#  url        => 'https://oss-es-plugins.s3.amazonaws.com/elasticsearch-jetty/elasticsearch-jetty-0.90.0.zip',
# }
#
# === Authors
#
# * Matteo Sessa <mailto:matteo.sessa@catchoftheday.com.au>
# * Dennis Konert <mailto:dkonert@gmail.com>
#
define elasticsearch::plugin(
    $module_dir,
    $ensure      = 'present',
    $version     = '',
    $url         = ''
) {

  require elasticsearch::params

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  $notify_elasticsearch = $elasticsearch::restart_on_change ? {
    false   => undef,
    default => Class['elasticsearch::service'],
  }

  if ($module_dir != '') {
      validate_string($module_dir)
  } else {
      fail("module_dir undefined for plugin ${name}")
  }

  if ($version != '') {
    $path = "${name}/${version}"
  } else {
    $path = $name
  }

  if ($url != '') {
    validate_string($url)
    $install_cmd = "${elasticsearch::plugintool} install ${url}"
    $exec_rets = [0,1]
  } else {
    $install_cmd = "${elasticsearch::plugintool} install ${path}"
    $exec_rets = [0,]
  }

  case $ensure {
    'installed', 'present': {
      exec {"install-plugin-${name}":
        command  => $install_cmd,
        creates  => "${elasticsearch::plugindir}/${module_dir}",
        returns  => $exec_rets,
        notify   => $notify_elasticsearch,
      }
    }
    default: {
      exec {"remove-plugin-${name}":
        command => "${elasticsearch::plugintool} remove ${module_dir}",
        onlyif  => "test -d ${elasticsearch::plugindir}/${module_dir}",
        notify  => $notify_elasticsearch,
      }
    }
  }
}
