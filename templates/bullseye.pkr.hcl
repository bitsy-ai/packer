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

variable "ansible_extra_vars" {
  type    = string
  default = "main"
}

variable "release_channel" {
  type = string
}

variable "base_image_url" {
  type = string
}

variable "base_image_checksum" {
  type = string
}

variable "base_image_ext" {
  type = string
}

variable "base_distro_version" {
  type = string
}

variable "base_image_unarchive_cmd" {
  type = list(string)
}

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "arm" "printnanny" {
  file_checksum_type    = "sha256"
  file_checksum_url     = "${var.base_image_checksum}"
  file_target_extension = "${var.base_image_ext}" 
  # todo - custom unarchive cmd only required for xz file here, otherwise we could combine buster/bullseye templaets
  file_unarchive_cmd = var.base_image_unarchive_cmd 
  file_urls             = [
    "${var.base_image_url}"
  ]
  image_build_method    = "resize"
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
  image_path                   = "dist/printnanny-pi-bullseye.img"
  image_size                   = "6G"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
  
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.arm.printnanny"]

  provisioner "shell" {
    inline = ["touch /boot/ssh"]
  }

  provisioner "shell" {
    inline = [
        "DEBIAN_FRONTEND=noninteractive apt-get -y update",
        "DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade --allow",
        "DEBIAN_FRONTEND=noninteractive apt-get -y install python3 python3-pip",
        "DEBIAN_FRONTEND=noninteractive apt-get clean"
    ]
    pause_before = "60s"
    timeout      = "800s"
  }

  provisioner "ansible" {
    extra_arguments = [
        "--extra-vars", "${var.ansible_extra_vars}",
    ]
    inventory_file_template = "default ansible_host=/tmp/rpi_chroot ansible_connection=chroot ansible_ssh_pipelining=True\n"
    galaxy_file     = "./playbooks/requirements.yml"
    playbook_file   = "./playbooks/printnanny.yml"
  }

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output = "dist/{{.ChecksumType}}.checksum"
  }

  post-processor "manifest" {
    output     = "dist/manifest.json"
    strip_path = true
    strip_time = true
    custom_data = {
      image_path = "releases/${var.release_channel}/${local.DATESTAMP}-printnanny-os-bullseye-arm64"
      image_name = "dist/printnanny-pi-bullseye.img"
      release_channel = "${var.release_channel}"
      datestamp = "${local.DATESTAMP}"
      base_image_checksum = "${var.base_image_checksum}"
      base_image_ext = "${var.base_image_ext}"
      base_image_url = "${var.base_image_url}"
    }
  }

  post-processor "compress" {
    output = "dist/${local.DATESTAMP}-print-nanny-${var.release_channel}-${var.base_distro_version}.zip"
  }

}
