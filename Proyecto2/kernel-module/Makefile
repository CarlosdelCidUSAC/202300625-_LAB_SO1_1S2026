# Define el nombre del objeto resultante. Debe coincidir con el nombre de tu archivo .c
obj-m += sonda.o
sonda-objs := src/sonda.o

# Ruta a los headers del kernel actual
KDIR := /lib/modules/$(shell uname -r)/build

# Directorio actual
PWD := $(shell pwd)

BUILD_DIR := $(PWD)/build
MODULE_NAME := sonda
MODULE_FILE := $(BUILD_DIR)/$(MODULE_NAME).ko
ARTIFACTS := Module.symvers modules.order sonda.ko sonda.mod sonda.mod.c sonda.mod.o sonda.o \
	.module-common.o .module-common.o.cmd .Module.symvers.cmd .modules.order.cmd \
	.sonda.ko.cmd .sonda.mod.cmd .sonda.mod.o.cmd .sonda.o.cmd

.PHONY: all modules organize clean load unload reload

all: modules organize

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

organize:
	@mkdir -p $(BUILD_DIR)
	@for file in $(ARTIFACTS); do \
		if [ -e "$(PWD)/$$file" ]; then mv -f "$(PWD)/$$file" "$(BUILD_DIR)/"; fi; \
	done

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	@for file in $(ARTIFACTS); do \
		if [ -e "$(BUILD_DIR)/$$file" ]; then rm -f "$(BUILD_DIR)/$$file"; fi; \
	done

load: all
	sudo insmod $(MODULE_FILE)

unload:
	sudo rmmod $(MODULE_NAME)

reload: unload load