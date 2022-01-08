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
  chroot = "/tmp/rpi_chroot"
  image_name = "${var.datestamp}-${var.image_family}-${var.image_os_version}-${var.cpu_arch}-${var.image_variant}"
  image_filename = "${local.image_name}.tar.gz"
  image_path = "${var.image_family}/${var.image_os_version}/${var.cpu_arch}/${var.image_variant}/${var.release_channel}"
  output = "${var.output}/${var.datestamp}"
  image_url = "./${local.output}/${local.image_filename}"
}

source "arm" "base_image" {
  file_checksum_type    = "sha256"
  file_checksum_url    = "${var.base_image_checksum}"
  file_target_extension = "${var.base_image_ext}"
  file_urls             = [
    "${var.base_image_url}"
  ]
  image_build_method    = "reuse"
  image_mount_path      = "${local.chroot}"

  // fdisk -l 2021-10-30-raspios-bullseye-arm64.img
  // Disk 2021-10-30-raspios-bullseye-arm64.img: 3.83 GiB, 4093640704 bytes, 7995392 sectors
  // Units: sectors of 1 * 512 = 512 bytes
  // Sector size (logical/physical): 512 bytes / 512 bytes
  // I/O size (minimum/optimal): 512 bytes / 512 bytes
  // Disklabel type: dos
  // Disk identifier: 0xae083906

  // Device                                                       Boot  Start     End Sectors  Size Id Type
  // 2021-10-30-raspios-bullseye-arm64.img1        8192  532479  524288  256M  c W95 FAT3
  // 2021-10-30-raspios-bullseye-arm64.img2      532480 7995391 7462912  3.6G 83 Linux
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
  image_path                   = "${local.output}/${local.image_name}.tar.gz"
  image_size                   = "${var.image_size}"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
  
}

build {
  sources = ["source.arm.base_image"]
  name = "ansible"

  provisioner "shell" {
    inline = [
      "DEBIAN_FRONTEND=noninteractive sudo apt update",
      "DEBIAN_FRONTEND=noninteractive sudo apt install -y initramfs-tools lvm2"
    ]
  }

  provisioner "file" {
    source = "tools/initramfs-hook.sh"
    destination = "/etc/initramfs-tools/hooks/update_initrd"
  }

  // Workaround libfuse2 autoremove recommendation triggering libc-bin trigger (re-runs ldconfig and seg faults)
  // "Setting up libc-bin (2.31-13+rpt2+rpi1) ...", "qemu: uncaught target signal 11 (Segmentation fault) - core dumped", "Segmentation fault (core dumped)", "qemu: uncaught target signal 11 (Segmentation fault) - core dumped", "Segmentation fault (core dumped)", "dpkg: error processing package libc-bin (--configure):", " installed libc-bin package post-installation script subprocess returned error exit status 139", "Errors were encountered while processing:", " libc-bin"]}
  provisioner "shell" {
    scripts = [
      "tools/setup-initramfs.sh",
    ]
  }

  provisioner "breakpoint" {
    disable = false
    note    = "this is a breakpoint"
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
    post-processor "compress" {
      output = "${local.output}/${local.image_filename}"
      format = "${var.image_ext}"
      compression_level = 9
    }
    post-processor "checksum" {
        checksum_types = ["sha256"]
        output = "${local.output}/{{.ChecksumType}}.checksum"
    }
    post-processor "manifest" {
        output     = "${local.output}/manifest.json"
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
          image_envfile = "${local.output}/packer.env"
          dryrun = "${var.dryrun}"
        }
      }
    post-processor "shell-local" {
      environment_vars = [
        "OUTPUT=${local.output}/packer.env",
        "CHECKSUM_FILE=${local.output}/sha256.checksum",
        "MANIFEST_FILE=${local.output}/manifest.json"
      ]
      inline = ["./tools/manifest-to-packer-env.sh"]
    }
    post-processor "artifice" {
      files = [
        "${local.output}/manifest.json",
        "${local.output}/packer.env",
        "${local.output}/${local.image_filename}",
        "${local.output}/sha256.checksum"
      ]
    }
  }
}

