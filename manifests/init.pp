# Class: vmware-tools
#
#   This module handles installing the VMware Tools Operating System Specific
#   Packages.  http://packages.vmware.com/
#   On Debian like operating systems, it installs the open-vm-tools package.
#
# Parameters:
#   [*version*]: vmware-tools version (defaults to 'latest')
#
# Actions:
#   Installs a vmware YUM repository, if needed.
#   Install the OSP or open vmware tools.
#   Starts the vmware-tools service.
#
# Requires:
#   It requres the $::osfamily facter, supported by Facter 1.6.1+
#
# Sample Usage:
#   class{ "vmware-tools":
#     version='5.0u1',
#   }
#
class vmware-tools(
$version='latest'
){
  case $::productname {
    'VMware Virtual Platform': {

      case $::osfamily {
        RedHat: {
          $yum_basearch = $::architecture ? {
            i386    => 'i686',
            default => $::architecture,
          }
          package { "vmware-tools-repo-RHEL${::lsbmajdistrelease}.${yum_basearch}" :
            ensure   => 'present',
            provider => 'rpm',
            source   => "http://packages.vmware.com/tools/esx/${version}/repos/vmware-tools-repo-RHEL${::lsbmajdistrelease}-8.6.5-2.${yum_basearch}.rpm"
          }

          case $::operatingsystemrelease {
            /^5\.\d*$/: {
              package { 'vmware-tools-esx-kmods':
                ensure  => latest,
                require => Package["vmware-tools-repo-RHEL${::lsbmajdistrelease}.${yum_basearch}"]
              }
            }
            default: {
              notice 'No additional kmods required'
            }
          }
          package{ 'vmware-tools-esx-nox':
            ensure  => latest,
            require => Package["vmware-tools-repo-RHEL${::lsbmajdistrelease}.${yum_basearch}"]
          }
          service { 'vmware-tools-services':
            ensure     => 'running',
            enable     => true,
            hasrestart => true,
            hasstatus  => true,
            require    => Package['vmware-tools-esx-nox']
          }
        }
        Debian: {
          package { 'open-vm-tools':
            ensure => latest
          }
        }
        default: {
          notify { "${module_name}_unsupported":
            message => "The ${module_name} module is not supported on ${::osfamily}"
          }
        }
      }
    }
    default: {
      notice 'I am NOT a vmware guest'
    }
  }
}
