locals {
  DATESTAMP = formatdate("YYYY-MM-DD-hhmm", timestamp())
}

variable "release_channel" {
    type = string
    default = "nightly"
}

variable "ansible_extra_vars" {
  type    = string
  default = "vars/generic-pi.ansiblevars.yml"
}

variable "image_name" {
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

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "arm" "base_image" {
  file_checksum_type    = "sha256"
  file_checksum_url     = "${var.base_image_checksum}"
  file_target_extension = "${var.base_image_ext}"
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
  image_path                   = "dist/${var.image_name}.img"
  image_size                   = "6G"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
  
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.arm.base_image"]

  provisioner "shell" {
    inline = ["touch /boot/ssh"]
  }

  provisioner "shell" {
    inline = [
        "DEBIAN_FRONTEND=noninteractive apt-get -y update",
        "DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade --force-yes",
        "DEBIAN_FRONTEND=noninteractive apt-get clean"
    ]
    pause_before = "60s"
    timeout      = "800s"
  }

  provisioner "ansible" {
    extra_arguments = [
        "--extra-vars", "@${var.ansible_extra_vars}",
    ]
    inventory_file_template = "default ansible_host=/tmp/rpi_chroot ansible_connection=chroot ansible_ssh_pipelining=True\n"
    galaxy_file     = "./playbooks/requirements.yml"
    playbook_file   = "./playbooks/generic.yml"
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
      image_path = "releases/${var.image_name}/${var.release_channel}/${local.DATESTAMP}-${image_name}"
      image_name = "${image_name}.img"
      release_channel = "${var.release_channel}"
      datestamp = "${local.DATESTAMP}"
      base_image_checksum = "${var.base_image_checksum}"
      base_image_ext = "${var.base_image_ext}"
      base_image_url = "${var.base_image_url}"
    }
  }

  post-processor "compress" {
    output = "dist/${local.DATESTAMP}-${var.image_name}.zip"
  }

}
