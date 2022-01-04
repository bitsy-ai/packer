variable "ansible_extra_vars" {
  type    = string
  default = "vars/generic-pi.ansiblevars.yml"
}

variable "base_image_family" {
  type = string
}

variable "image_family" {
  type = string
}

variable "base_image_datestamp" {
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
}

variable "image_os_version" {
  type = string
}

variable "image_variant" {
}

variable "cpu_arch" {
  type = string
}

variable "release_channel" {
  type = string
  default = "nightly"
}

variable "image_ext" {
  type = string
}

locals {
  image_name = "${var.datestamp}-${var.image_family}-${var.image_os_version}-${var.cpu_arch}-${var.image_variant}"
  image_filename = "${local.image_name}.tar.gz"
  image_path = "${var.image_family}/${var.image_os_version}/${var.cpu_arch}/${var.image_variant}/${var.release_channel}"
  image_url = "file:${local.image_path}/${local.image_filename}"
  output = "${var.output}/${var.datestamp}"
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

  # TODO parameterize partition scheme for A/B swap
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
  image_path                   = "${var.output}/${local.image_name}.img"
  image_size                   = "${var.image_size}"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
  
}

build {
  sources = ["source.arm.base_image"]
  name = "ansible"

  // Workaround libfuse2 autoremove recommendation triggering libc-bin trigger (re-runs ldconfig and seg faults)
  // "Setting up libc-bin (2.31-13+rpt2+rpi1) ...", "qemu: uncaught target signal 11 (Segmentation fault) - core dumped", "Segmentation fault (core dumped)", "qemu: uncaught target signal 11 (Segmentation fault) - core dumped", "Segmentation fault (core dumped)", "dpkg: error processing package libc-bin (--configure):", " installed libc-bin package post-installation script subprocess returned error exit status 139", "Errors were encountered while processing:", " libc-bin"]}
  provisioner "shell" {
    scripts = [
      "echo ${local.image_name} > /boot/image_version.txt",
      "DEBIAN_FRONTEND=noninteractive apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y libfuse2",
      "DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade"
    ]
  }

  // provisioner "shell" {
  //   inline = [
  //     "reboot"
  //   ]
  //   expect_disconnect = true
  //   pause_after = "10s"
  // }

  // provisioner "ansible" {
  //   extra_arguments = [
  //       "--extra-vars", "@${var.ansible_extra_vars}",
  //   ]
  //   inventory_file_template = "${var.hostgroup } ansible_host=/tmp/rpi_chroot ansible_connection=chroot ansible_ssh_pipelining=True\n"
  //   galaxy_file     = "./playbooks/requirements.yml"
  //   playbook_file   = "${var.playbook_file}"
  // }

  post-processors {
    post-processor "checksum" {
        checksum_types = ["sha256"]
        output = "${var.output}/{{.ChecksumType}}.checksum"
        keep_input_artifact = true
    }
    # chain compress -> artifice -> checksum
    # compress .img into tarball
    post-processor "compress" {
      output = "${var.output}/${local.image_filename}"
      format = "${var.image_ext}"
    }
    post-processor "manifest" {
        output     = "${var.output}/manifest.json"
        strip_path = true
        strip_time = true
        custom_data = {
          ansible_extra_vars = file("../${var.ansible_extra_vars}")
          base_image_checksum = "${var.base_image_checksum}"
          base_image_datestamp = "${var.base_image_datestamp}"
          base_image_ext = "${var.base_image_ext}"
          base_image_family = "${var.base_image_family}"
          base_image_name = "${var.base_image_name}"
          base_image_url = "${var.base_image_url}"
          cpu_arch = "${var.cpu_arch}"
          image_datestamp = "${var.datestamp}"
          image_ext = "${var.image_ext}"
          image_family = "${var.image_family}"
          image_filename = "${local.image_filename}"
          image_name = "${var.datestamp}-${var.image_family}"
          image_os_version = "${var.image_os_version}"
          image_path = "${local.output}"
          image_variant = "${var.image_variant}"
          image_url = "${local.image_url}"
          dryrun = "${var.dryrun}"
        }
      }
    post-processor "shell-local" {
      environment_vars = [
        "OUTPUT=${var.output}packer.env",
        "CHECKSUM_FILE=${var.output}/{{.ChecksumType}}.checksum",
        "MANIFEST_FILE=${var.output}/manifest.json"
      ]
      inline = ["./tools/manifest-to-packer-env.sh"]
    }
    post-processor "artifice" {
      files = [
        "${var.output}/manifest.json",
        "${var.output}/packer.env",
        "${var.output}/${local.image_filename}",
        "${var.output}/{{.ChecksumType}}.checksum"
      ]
    }
  }
}

