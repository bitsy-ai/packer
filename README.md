# Bitsy AI Labs Packer

Cross-arch Raspberry Pi image builder. Create ARM images from an x86 host using:

* https://github.com/multiarch/qemu-user-static
* https://github.com/mkaczanowski/packer-builder-arm


## Bake image from template

```
$ make dist/printnanny-pi-buster-arm64.img

$ make dist/my-custom-pi-buster-arm64.img \
    IMAGE_NAME=my-custom-pi \
    VAR_FILE=vars/generic-pi-buster-arm64.pkrvars.hcl \
    ANSIBLE_EXTRA_VARS=vars/generic-pi-buster-arm64.ansiblevars.yml
```
