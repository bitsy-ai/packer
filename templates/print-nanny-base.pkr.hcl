# This file was autogenerated by the 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# Avoid mixing go templating calls ( for example ```{{ upper(`string`) }}``` )
# and HCL2 calls (for example '${ var.string_value_example }' ). They won't be
# executed together and the outcome will be unknown.

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/templates/hcl_templates/variables#type-constraints for more info.

locals {
  DATESTAMP = formatdate("YYYY-MM-DD-hhmm", timestamp())
  # Also here I believe naming this variable `buildtime` could lead to 
  # confusion mainly because this is evaluated a 'parsing-time'.
}

variable "DISTRO_VERSION" {
    type = string
    default = "2021-05-07-raspios"
}

variable "RELEASE_CHANNEL" {
  type    = string
  default = "main"
}

variable "CPU_ARCH" {
  type    = string
  default = "arm64"
}

variable "PLATFORM_VERSION" {
  type = string
  default = "buster"
}

variable "PRINTNANNY_CLI_VERSION" {
    type = string
    default = "0.1.1"
}

variable "OCTOPRINT_VERSION" {
    type = string
    default = "1.6.1"
}

variable "JANUS_VERSION" {
    type = string
    default = "v0.11.4"
}

variable "JANUS_USRSCTP_VERSION" {
    type = string
    default = "0.9.5.0"
}

variable "JANUS_LIBNICE_VERSION" {
    type = string
    default = "0.1.18"
}

variable "JANUS_LIBSRTP_VERSION" {
    type = string
    default = "2.2.0"
}

variable "JANUS_WEBSOCKETS_VERSION" {
    type = string
    default = "v3.2-stable"
}




# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "arm" "print_nanny" {
  file_checksum_type    = "sha256"
  file_checksum_url     = "https://downloads.raspberrypi.org/raspios_${var.CPU_ARCH}/images/raspios_${var.CPU_ARCH}-2021-05-28/2021-05-07-raspios-${var.PLATFORM_VERSION}-${var.CPU_ARCH}.zip.sha256"
  file_target_extension = "zip"
  file_urls             = ["https://downloads.raspberrypi.org/raspios_${var.CPU_ARCH}/images/raspios_${var.CPU_ARCH}-2021-05-28/2021-05-07-raspios-${var.PLATFORM_VERSION}-${var.CPU_ARCH}.zip"]
  image_build_method    = "resize"
//   image_chroot_env      = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  image_mount_path      = "/tmp/rpi_chroot"

  image_partitions {
    filesystem   = "vfat"
    mountpoint   = "/boot"
    name         = "boot"
    size         = "256M"
    start_sector = "8192"
    type         = "c"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "root"
    size         = "0"
    start_sector = "532480"
    type         = "83"
  }
  image_path                   = "dist/${local.DATESTAMP}-print-nanny-${var.RELEASE_CHANNEL}-${var.PLATFORM_VERSION}-${var.CPU_ARCH}.img"
  image_size                   = "6G"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.arm.print_nanny"]

  provisioner "shell" {
    inline = ["touch /boot/ssh"]
  }

  provisioner "ansible" {
    extra_arguments = [
        "--extra-vars", "printnanny_release_channel=${var.RELEASE_CHANNEL}",
        "--extra-vars", "printnanny_cli_version=${var.PRINTNANNY_CLI_VERSION}",
        "--extra-vars", "octoprint_version=${var.OCTOPRINT_VERSION}",
        "--extra-vars", "printnanny_cpu_arch=${var.CPU_ARCH}",
        "--extra-vars", "janus_version=${var.JANUS_VERSION}",
        "--extra-vars", "janus_usrsctp_version=${var.JANUS_USRSCTP_VERSION}",
        "--extra-vars", "janus_libnice_version=${var.JANUS_LIBNICE_VERSION}",
        "--extra-vars", "janus_libsrtp_version=${var.JANUS_LIBSRTP_VERSION}",
        "--extra-vars", "janus_websockets_version=${var.JANUS_WEBSOCKETS_VERSION}",
    ]
    inventory_file_template = "default ansible_host=/tmp/rpi_chroot ansible_connection=chroot\n"
    galaxy_file     = "./playbooks/requirements.yml"
    playbook_file   = "./playbooks/printnanny.yml"
  }
  post-processor "checksum" {
    checksum_types = ["sha1", "sha256"]
    output = "dist/{{.ChecksumType}}.checksum"
  }

  post-processor "manifest" {
    output     = "dist/manifest.json"
    strip_path = true
    strip_time = true
    custom_data = {
      image_path = "${local.DATESTAMP}-print-nanny-${var.RELEASE_CHANNEL}-${var.PLATFORM_VERSION}-${var.CPU_ARCH}"
      image_name = "${local.DATESTAMP}-print-nanny-${var.RELEASE_CHANNEL}-${var.PLATFORM_VERSION}-${var.CPU_ARCH}.img"
      release_channel = "${var.RELEASE_CHANNEL}"
      datestamp = "${local.DATESTAMP}"
      platform_version = "${var.PLATFORM_VERSION}"
      cpu_arch = "${var.CPU_ARCH}"
      printnanny_cli_version = "${var.PRINTNANNY_CLI_VERSION}"
      octoprint_version = "${var.OCTOPRINT_VERSION}"
      distro_version = "${var.DISTRO_VERSION}"
      janus_version = "${var.JANUS_VERSION}"
      janus_usrsctp_version = "${var.JANUS_USRSCTP_VERSION}"
      janus_libnice_version = "${var.JANUS_LIBNICE_VERSION}"
      janus_libsrtp_version = "${var.JANUS_LIBSRTP_VERSION}"
      janus_websockets_version = "${var.JANUS_WEBSOCKETS_VERSION}"
    }
  }

  post-processor "compress" {
    output = "dist/${local.DATESTAMP}-print-nanny-${var.RELEASE_CHANNEL}-${var.PLATFORM_VERSION}-${var.CPU_ARCH}.zip"
  }

}
