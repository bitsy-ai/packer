base_image_name = "2021-10-30-raspios-bullseye-arm64"
base_image_url = "https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2021-11-08/2021-10-30-raspios-bullseye-arm64.zip"
base_image_checksum = "https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2021-11-08/2021-10-30-raspios-bullseye-arm64.zip.sha256"
base_image_ext = "zip"
playbook_file = "./playbooks/generic.yml"
ansible_extra_vars = "generic-pi-arm64.ansiblevars.yml"