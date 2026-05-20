# == Define: iface
#
# Resource to define an interface configuration stanza within interfaces(5).
#
# == Parameters
#
# [*ifname*] => *(namevar)* - string
#   Name of the interface to be configured.
#
# [*method*] - string
#   Configuration method to be used. Supported methods are:
#   * loopback
#   * dhcp
#   * static
#   * manual
#   * wvdial
#
# [*auto*] - bool
#   Sets the interface on automatic setup on startup. This is affected by
#   ifup -a and ifdown -a commands.
#
# [*allows*] - array
#   Adds an allow- entry to the interface stanza.
#
# [*family*] - string
#   Address family. Currently, only inet family is supported. Support for
#   inet6 is comming soon.
#
# [*order*] - int
#   Order of the entry to be created in /etc/network/interfaces. Innate
#   odering is preset with default value of 10 for loopback and 20 for dhcp
#   and static stanzas. The order attribute of the resource is added to the
#   default value.
#
# [*hwaddress*] - string
#   The MAC address of the interface. This value is validated as standard
#   IEEE MAC address of 6 bytes, written hexadecimal, delimited with
#   colons (:) or dashes (-).
#
# [*hostname*] - string
#   The hostname to be submitted with dhcp requests.
#
# [*leasetime*] - int
#   The requested leasetime of dhcp leases.
#
# [*vendor*] - string
#   The vendor id to be submitted with dhcp requests.
#
# [*client*] - string
#  The client id to be submitted with dhcp requests.
#
# [*metric*] - int
#  Routing metric for routes added resolved on this interface.
#
# [*address*] - string
#  IP address formatted as dotted-quad for IPv4.
#
# [*netmask*] - string
#  Netmask as dotted-quad or CIDR prefix length.
#
# [*broadcast*] - string
#  Broadcast address as dotted-quad or + or -.
#
# [*gateway*] - string
#  Default route to be brought up with this interface.
#
# [*pointopoint*] - stirng
#  Address of the ppp endpoint as dotted-quad.
#
# [*mtu*] - int
#  Size of the maximum transportable unit over this interface.
#
# [*scope*] - string
#  Scope of address validity. Values allowed are global, link or host.
#
# [*pre_ups*] - array
#  Array of commands to be run prior to bringing this interface up.
#
# [*ups*] - array
#  Array of commands to be run after bringing this interface up.
#
# [*downs*] - array
#  Array of commands to be run prior to bringing this interface down.
#
# [*post_downs*] - array
#  Array of commands to be run after bringing this interface down.
#
# [*aux_ops*] - hash
#  Hash of key-value pairs with auxiliary options for this interface.
#  To be used by other debnet types only.
#
# [*tx_queue*] - int
#  Feature helper for setting tx queue on the interface.
#
# [*routes*] - hash
#  Feature helper for setting static routes via the interface.
#
# [*dns_nameserver*] - array
#  Feature helper to add a list of nameservers to be configures via resolvconf
#  while the interface is set up.
#
# [*dns_search*] - array
#  Feature helper to add a list of domain names as dns search via resolvconf
#  while the interface is set up.
#
# === Authors
#
# Tibor Repasi
#
# === Copyright
#
# Copyright 2016 Tibor Repasi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
define debnet::iface (
  Enum['loopback', 'dhcp', 'static', 'manual', 'wvdial'] $method,
  String $ifname = $title,
  Boolean $auto = true,
  Array $allows = [],
  Enum['inet'] $family = 'inet',
  $order = 0,
  Variant[Pattern[/^[a-zA-Z][a-zA-Z0-9_]*$/], Undef] $iface_d = undef,

  # options for multiple methods
  Variant[Pattern[/^\d+$/], Undef] $metric = undef,
  Variant[Pattern[/^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/], Undef] $hwaddress = undef,

  # options for method dhcp
  Variant[Pattern[/^(?![0-9]+$)(?!-)[a-zA-Z0-9-]{,63}(?<!-)$/], Undef] $hostname = undef,
  Variant[Pattern[/^\d+$/], Undef] $leasetime = undef,
  Variant[String, Undef] $vendor = undef,
  Variant[String, Undef] $client = undef,

  #Variant[Pattern[//], Undef]
  # options for method static
  Variant[Pattern[/^(:?[0-9]{1,3}\.){3}[0-9]{1,3}$/], Undef] $address = undef,
  Variant[Pattern[/^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9]{1,2}$/], Integer, Undef] $netmask = undef,
  Variant[Pattern[/^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[+-]$/], Undef] $broadcast = undef,
  Variant[Pattern[/(:?[0-9]{1,3}\.){3}[0-9]{1,3}$/], Undef] $gateway = undef,
  Variant[Pattern[/(:?[0-9]{1,3}\.){3}[0-9]{1,3}$/], Undef] $pointopoint = undef,
  Variant[Pattern[/^\d+$/], Undef] $mtu = undef,
  Variant[Enum['global', 'link', 'host'], Undef] $scope = undef,

  # up and down commands
  Array $pre_ups = [],
  Array $ups = [],
  Array $downs = [],
  Array $post_downs = [],

  # auxiliary options
  Hash $aux_ops = {},

  # feature-helpers
  Variant[Integer, Undef] $tx_queue = undef,
  Hash $routes = {},
  Variant[Array, Undef] $dns_nameservers = undef,
  Variant[Array, Undef] $dns_search = undef,
) {
  include debnet

  if $iface_d {
    if $::facts['os']['family'] == 'Debian' and
      $::facts['os']['release']['major'] =~ /!^8.*/ {
      fail('This feature is not available prior to Debian release 8.')
    }
    $cfgtgt = "${debnet::params::interfaces_dir}/${iface_d}"
  } else {
    $cfgtgt = $debnet::params::interfaces_file
  }
  assert_type(Stdlib::AbsolutePath, $cfgtgt)

  if !defined(Concat[$cfgtgt])
  {
    concat { $cfgtgt:
      owner          => 'root',
      group          => 'root',
      mode           => '0644',
      ensure_newline => true,
      order          => 'numeric',
    }

    concat::fragment { "${cfgtgt}_header":
      target  => $cfgtgt,
      content => template('debnet/header.erb'),
      order   => 10,
    }
  }

  case $method {
    'loopback' : {
      concat::fragment { 'lo_stanza':
        target  => $cfgtgt,
        content => template('debnet/loopback.erb'),
        order   => 20 + $order,
      }
    }

    'dhcp' : {
      if !defined(Package[$debnet::params::dhclient_pkg]) {
        package { $debnet::params::dhclient_pkg: ensure => 'installed', }
      }
      concat::fragment { "${ifname}_stanza":
        target  => $cfgtgt,
        content => template(
          'debnet/iface_header.erb',
          'debnet/inet_dhcp.erb',
          'debnet/iface_aux.erb',
          'debnet/iface_routes.erb'),
        order   => 30 + $order,
      }
    }

    'static' : {
      concat::fragment { "${ifname}_stanza":
        target  => $cfgtgt,
        content => template(
          'debnet/iface_header.erb',
          'debnet/inet_static.erb',
          'debnet/iface_aux.erb',
          'debnet/iface_routes.erb'),
        order   => 40 + $order,
      }
    }

    'manual' : {
      concat::fragment { "${ifname}_stanza":
        target  => $cfgtgt,
        content => template(
          'debnet/iface_header.erb',
          'debnet/inet_misc.erb',
          'debnet/iface_aux.erb'),
        order   => 50 + $order,
      }
    }

    'wvdial' : {
      if !defined(Package[$debnet::params::wvdial_pkg]) {
        package { $debnet::params::wvdial_pkg: ensure => 'installed', }
      }

      concat::fragment { "${ifname}_stanza":
        target  => $cfgtgt,
        content => template(
          'debnet/iface_header.erb',
          'debnet/inet_misc.erb',
          'debnet/iface_aux.erb',
          'debnet/iface_routes.erb'),
        order   => 60 + $order,
      }
    }

    default: {
      err('unrecognized method')
    }
  }
}
