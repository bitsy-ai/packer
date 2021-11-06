base_image_url = "https://raspi.debian.net/tested/20210823_raspi_4_bullseye.img.xz"
base_image_checksum = "https://raspi.debian.net/tested/20210823_raspi_4_bullseye.img.xz.sha256"
base_image_ext = "xz"
base_distro_version = "20210823-raspi4-bullseye-arm64"
base_image_unarchive_cmd = ["xz", "-d", "$ARCHIVE_PATH"]
playbook_file = "./playbooks/printnanny.yml"