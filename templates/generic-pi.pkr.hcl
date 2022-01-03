locals {
  DATESTAMP = formatdate("YYYY-MM-DD-hhmm", timestamp())
}

variable "ansible_extra_vars" {
  type    = string
  default = "vars/generic-pi.ansiblevars.yml"
}

variable "image_name" {
  type = string
}

variable "base_image_id" {
  type = string
  default = ""
}

variable "base_image_stamp" {
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

variable "base_image_manifest_url" {
  type = string
  default = ""
}

variable "playbook_file" {
  type = string
  default = "./playbooks/generic.yml"
}

variable "image_size" {
  type = string
  default = "3.6G"
}

variable "dryrun" {
  type = bool
  default = false
}

variable "base_publish_path" {
  type = string
  default = "printnanny-os"
}

variable "hostgroup" {
  type = string
}

variable "base_image_name" {
  type = string
}

variable "output" {
  type = string
  default = "dist"
}

variable "datestamp" {
  type = string
  default = local.DATESTAMP
}

source "arm" "base_image" {
  file_checksum_type    = "sha256"
  file_checksum     = "${var.base_image_checksum}"
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
  image_path                   = "${var.output}/${var.datestamp}-${var.image_name}.img"
  image_size                   = "${var.image_size}"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
  
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.arm.base_image"]
  name = "ansible"

  // Workaround libfuse2 autoremove recommendation triggering libc-bin trigger (re-runs ldconfig and seg faults)
  // "Setting up libc-bin (2.31-13+rpt2+rpi1) ...", "qemu: uncaught target signal 11 (Segmentation fault) - core dumped", "Segmentation fault (core dumped)", "qemu: uncaught target signal 11 (Segmentation fault) - core dumped", "Segmentation fault (core dumped)", "dpkg: error processing package libc-bin (--configure):", " installed libc-bin package post-installation script subprocess returned error exit status 139", "Errors were encountered while processing:", " libc-bin"]}
  provisioner "shell" {
    scripts = [
      "tools/dist-upgrade.sh"
    ]
    environment_vars = [
      "DATESTAMP=${var.datestamp}",
      "IMAGE_VERSION=${var.datestamp}-${var.image_name}",
      "DRYRUN=${var.dryrun}"
    ]
  }

  provisioner "shell" {
    inline = [
      "reboot"
    ]
    expect_disconnect = true
    pause_after = "10s"
  }

  provisioner "ansible" {
    extra_arguments = [
        "--extra-vars", "@${var.ansible_extra_vars}",
    ]
    inventory_file_template = "${var.hostgroup } ansible_host=/tmp/rpi_chroot ansible_connection=chroot ansible_ssh_pipelining=True\n"
    galaxy_file     = "./playbooks/requirements.yml"
    playbook_file   = "${var.playbook_file}"
  }

  post-processors {
    post-processor "checksum" {
        checksum_types = ["sha256"]
        output = "${var.output}/{{.ChecksumType}}.checksum"
    }
    post-processor "manifest" {
        output     = "${var.output}/manifest.json"
        strip_path = true
        strip_time = true
        custom_data = {
          ansible_extra_vars = file("../${var.ansible_extra_vars}")
          image_path = "printnanny-os/${var.image_name}/nightly/${var.datestamp}-${var.image_name}.tar.gz"
          image_filename = "${var.datestamp}-${var.image_name}.tar.gz"
          image_stamp = "${var.datestamp}-${var.image_name}"
          image_name = "${var.image_name}"
          datestamp = "${var.datestamp}"
          base_image_id = "${var.base_image_id}"
          base_image_stamp = "${var.base_image_stamp}"
          base_image_checksum = "${var.base_image_checksum}"
          base_image_ext = "${var.base_image_ext}"
          base_image_url = "${var.base_image_url}"
          dryrun = "${var.dryrun}"
        }
      }
    }
}

