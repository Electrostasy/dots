KERNELRELEASE ?= $(shell uname -r)
KERNEL_DIR ?= /lib/modules/$(KERNEL_RELEASE)/build/

obj-m = emc230x.o

modules:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules

modules_install:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules_install

# For using with Nix, first enter a dev shell with `nix develop` and then run
# `export $makeFlags` to pass the parameters from the Nix derivation to make.
dev:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) compile_commands.json
