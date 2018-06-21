# == Define dns::zone
#
# `dns::zone` defines a DNS zone in BIND format.
#
define dns::zone (
  String $zone                        = $name,
  String $zone_ttl                    = '604800',
  String $soa_mname                   = $fqdn,
  String $soa_email                   = "hostmaster.${name}",
  String $serial                      = '0000000000',
  String $soa_refresh                 = '18000',
  String $soa_retry                   = '3600',
  String $soa_expire                  = '864000',
  String $soa_minimum                 = '3600',
  Array[String] $nameservers          = [$fqdn],
  Optional[String] $nameservers_ttl   = undef,
  Stdlib::AbsolutePath $zones_dir     = undef,
  Boolean $collect_exported           = true,
  String $owner                       = '0',
  String $group                       = '0',
  String $mode                        = '0644',
  Optional[String] $checkzone_cmd     = undef,
  Optional[Type[Resource]] $notify    = undef,
  Enum['present','absent'] $ensure    = 'present',
) {
  include dns
  $fragment_file = "/var/lib/dns/${zone}"
  $zone_file     = "${zones_dir}/${zone}"

  if $ensure == 'absent' {
    file { [$fragment_file,$zone_file]:
      ensure => absent,
    }
  } else {

    if $checkzone_cmd {
      $validate_cmd = "${checkzone_cmd} ${zone} %"
    } else {
      $validate_cmd = undef
    }

    concat { $fragment_file:
      backup       => false,
      owner        => $owner,
      group        => $group,
      mode         => $mode,
      validate_cmd => $validate_cmd,
      notify       => Exec["bump ${zone} serial"],
    }

    # file populated by bump-serial command
    file { $zone_file:
      ensure => file,
      owner  => $owner,
      group  => $group,
      mode   => $mode,
      # if created after the $fragment_file this will populate it
      notify => Exec["bump ${zone} serial"],
    }

    dns::data { "${zone}-header":
      zone    => $zone,
      order   => '01',
      content => epp("${module_name}/zone_header.epp", {
                                                       'zone'            => $zone,
                                                       'zone_ttl'        => $zone_ttl,
                                                       'soa_mname'       => $soa_mname,
                                                       'soa_email'       => $soa_email,
                                                       'serial'          => $serial,
                                                       'soa_refresh'     => $soa_refresh,
                                                       'soa_retry'       => $soa_retry,
                                                       'soa_expire'      => $soa_expire,
                                                       'soa_minimum'     => $soa_minimum,
                                                       'nameservers'     => $nameservers,
                                                       # special handling for cosmetic alignment
                                                       'nameservers_ttl' => $nameservers_ttl ? {
                                                          undef   => "\t",
                                                          default => $nameservers_ttl,
                                                       },
                                                     }),
    }
    dns::data { "${zone}-trailer":
      zone    => $zone,
      order   => 'zzzz',
      content => "\n",
    }

    if $collect_exported {
      Dns::Data <<| zone == $name |>>
      Dns::Record <<| zone == $name |>>
    }
    # else: the resources have been created and they introduced their
    # concat fragments. We don't have to do anything about them.

    exec { "bump ${zone} serial":
      command     => "bump-serial ${fragment_file} ${zone_file}",
      user        => $owner,
      group       => $group,
      refreshonly => true,
      notify      => $notify,
    }
  }
}
