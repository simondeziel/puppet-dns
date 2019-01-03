# == Define dns::record
#
# `dns::record` defines a DNS record to add to a BIND formatted zone.
#
define dns::record (
  String $zone,
  String $host,
  String $data,
  Optional[String] $type              = undef,
  Optional[String] $ttl               = undef,
  String $order                       = '20',
) {
  # if no type is provided, try to guess it based on the data provided
  if $type {
    $real_type = $type
  } else {
    if $data =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ {
      $real_type = 'A'
    } elsif $data =~ /^[a-fA-F\d]{1,4}:[a-fA-F\d:]{1,34}$/ {
      $real_type = 'AAAA'
    } else {
      fail("${module_name}::record: cannot guess the type from the data so please provide one")
    }
  }

  concat::fragment{ "${zone}-${name}-record":
    target  => "/var/lib/dns/${zone}",
    order   => $order,
    content => template("${module_name}/zone_record.erb"),
  }
}
