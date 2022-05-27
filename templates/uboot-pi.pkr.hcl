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

variable "skiptags" {
  type = string
  default = "secret,secrets,credential,credentials,keys,key,private,env"
}

locals {
  image_name = "${var.datestamp}-${var.image_family}-${var.image_os_version}-${var.cpu_arch}-${var.image_variant}"
  image_filename = "${local.image_name}.img"
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
  image_build_method    = "new"
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
    name         = "rootA"
    size         = "4GB"
    start_sector = "0"
    // "type" field is passed as sgdisk -t parameter
    // partition type GUIDs are used by Discoverable Partition Specification:
    // https://www.freedesktop.org/wiki/Specifications/DiscoverablePartitionsSpec/
    // systemd's reference implementation of discoverable partition spec:
    // https://www.freedesktop.org/software/systemd/man/systemd-gpt-auto-generator.html
    //
    // list all partition type GUID codes:
    // $ sgdisk -L
    // 8200 Linux swap                          8300 Linux filesystem
    // 8301 Linux reserved                      8302 Linux /home
    // 8303 Linux x86 root (/)                  8304 Linux x86-64 root (/)
    // 8305 Linux ARM64 root (/)                8306 Linux /srv
    // 8307 Linux ARM32 root (/)                8308 Linux dm-crypt
    // 8309 Linux LUKS                          830a Linux IA-64 root (/)
    // 830b Linux x86 root verity               830c Linux x86-64 root verity
    // 830d Linux ARM32 root verity             830e Linux ARM64 root verity
    // 830f Linux IA-64 root verity             8310 Linux /var
    type         = "8301"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "rootB"
    size         = "4GB"
    start_sector = "0"
    type         = "8301"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/var"
    name         = "var"
    size         = "1GB"
    start_sector = "0"
    type         = "8310"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/home"
    name         = "home"
    // last partition can be extended to fill available disk via growpart
    size         = "256M"
    start_sector = "0"
    type         = "8302"
  }

  image_path                   = "${local.image_name}.img"
  image_size                   = "${var.image_size}"
  image_type                   = "gpt"
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
      "tools/image-version.sh",
      "tools/dist-upgrade.sh"
    ]
    environment_vars=[
      "IMAGE_VERSION=${local.image_name}"
    ]
  }

  provisioner "shell" {
    inline = [
      "reboot"
    ]
    expect_disconnect = true
    pause_after = "10s"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/rpi_chroot/etc/ansible/"
    ]
  }

  provisioner "ansible" {
    extra_arguments = [
        "--extra-vars", "@${var.ansible_extra_vars}",
        "--skip-tags", "${var.skiptags}"
    ]
    inventory_file_template = "${var.hostgroup } ansible_host=/tmp/rpi_chroot ansible_connection=chroot ansible_ssh_pipelining=True\n"
    galaxy_file     = "./playbooks/requirements.yml"
    playbook_file   = "${var.playbook_file}"
  }

  post-processors {
    // then move zip to output dir
    post-processor "shell-local" {
      inline = [
        "mv ${local.image_filename} ${local.output}/${local.image_filename}",
        "cd ${local.output} && zip ${local.image_name}.zip ${local.image_filename}",
        "sha256sum * > sha256.checksum && cd -"
      ]
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

