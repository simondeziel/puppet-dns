# == Class dns
#
class dns (
  Boolean $purge_dir = true,
) {
  file { '/var/lib/dns':
    ensure  => directory,
    owner   => 0,
    group   => 0,
    mode    => '0755',
    purge   => $purge_dir,
    recurse => $purge_dir,
  }

  # tool to bump a zone's serial with some smarts
  file { '/usr/local/bin/bump-serial':
    mode   => '0755',
    source => 'puppet:///modules/dns/bump-serial',
  }
}
