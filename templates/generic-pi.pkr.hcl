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

variable "base_image_name" {
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
    default = "6G"
}

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

  provisioner "ansible" {
    extra_arguments = [
        "--extra-vars", "@${var.ansible_extra_vars}",
    ]
    inventory_file_template = "default ansible_host=/tmp/rpi_chroot ansible_connection=chroot ansible_ssh_pipelining=True\n"
    galaxy_file     = "./playbooks/requirements.yml"
    playbook_file   = "${var.playbook_file}"
  }

  # https://www.freedesktop.org/software/systemd/man/machine-id.html#First%20Boot%20Semantics
  # reset machine id so systemd ConditionFirstBoot=yes units are run when user first boots images
  # see also https://wiki.debian.org/MachineId
  provisioner "shell" {
      inline = [
        "echo uninitialized\n > /etc/machine-id",
        "rm /var/lib/dbus/machine-id"
    ]
  }

  post-processors {
    # chain compress -> artifice -> checksum
    # compress .img into tarball
    post-processor "compress" {
      output = "dist/${var.image_name}.tar.gz"
      format = ".tar.gz"
      # keep the img artifact so checksum is generated for both .img and .tar.gz files
      keep_input_artifact = true
    }
    # register tarball as new artiface
    post-processor "artifice" {
      files = [
        "dist/${var.image_name}.tar.gz"
      ]
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
          ansible_extra_vars = file("../${var.ansible_extra_vars}")
          image_stamp = "${local.DATESTAMP}-${var.image_name}"
          image_path = "releases/${var.image_name}/${local.DATESTAMP}-${var.image_name}"
          image_filename = "${var.image_name}.tar.gz"
          image_name = "${var.image_name}"
          release_channel = "${var.release_channel}"
          datestamp = "${local.DATESTAMP}"
          base_image_name = "${var.base_image_name}"
          base_image_manifest_url = "${var.base_image_manifest_url}"
          base_image_checksum = "${var.base_image_checksum}"
          base_image_ext = "${var.base_image_ext}"
          base_image_url = "${var.base_image_url}"
        }
      }
    }
}

