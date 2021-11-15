
locals {
  DATESTAMP = formatdate("YYYY-MM-DD-hhmm", timestamp())
}

variable "release_channel" {
  type = string
  default = "nightly"
}

variable "ansible_extra_vars" {
  type    = string
  default = "vars/generic-pi-arm64.ansiblevars.yml"
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

# TODO remove
variable "base_image_ext" {
  type = string
  default = ""
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

variable "output_directory" {
  type = string
  default = "dist"
}

variable "target_image_size" {
  type = number
  default = 6*1024*1024*1024
}

variable "image_mount_path" {
  type = string
  default = "/mnt/raspbian"
}

variable "qemu_binary" {
  type = string
  default = "qemu-aarch64-static"
}

source "arm-image" "base" {
  image_mounts = ["/boot", "/"]
  iso_checksum = "${var.base_image_checksum}"
  iso_url      = "${var.base_image_url}"
  output_filename = "${var.output_directory}/${var.image_name}.img"
  mount_path = "${var.image_mount_path}"
  target_image_size = var.target_image_size
  qemu_binary = var.qemu_binary
}


# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build

build {
  sources = ["source.arm-image.base"]
  name = "ansible"

  provisioner "ansible" {
    extra_arguments = [
        "--extra-vars", "@${var.ansible_extra_vars}",
    ]
    inventory_file_template = "default ansible_host=${var.image_mount_path} ansible_connection=chroot ansible_ssh_pipelining=True\n"
    galaxy_file     = "./playbooks/requirements.yml"
    playbook_file   = "${var.playbook_file}"
  }

  post-processors {
    # chain compress -> artifice -> checksum
    # compress .img into tarball
    post-processor "compress" {
      output = "dist/${var.image_name}.zip"
      format = ".zip"
      # keep the img artifact so checksum is generated for both .img and .zip files
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