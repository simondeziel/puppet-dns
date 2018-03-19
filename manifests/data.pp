# == Define dns::data
#
# `dns::data` defines a DNS zone fragment to add to a BIND formatted zone.
#
define dns::data (
  String $zone,
  Optional[String] $content        = undef,
  Optional[String] $source         = undef,
  String $order                    = '10',
) {
  if $source and $content {
    fail("${module_name}::data source and content cannot be use at the same time")
  } elsif ! $source and ! $content {
    fail("${module_name}::data use one of source or content")
  }

  concat::fragment { $title:
    content => $content,
    source  => $source,
    target  => "/var/lib/dns/${zone}",
    order   => $order,
  }
}
