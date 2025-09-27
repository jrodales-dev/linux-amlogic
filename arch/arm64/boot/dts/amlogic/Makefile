# arch/arm64/boot/dts/amlogic/Makefile
dtb-y += gxl_p212_1g.dtb
dtb-y += gxl_p212_1g_buildroot.dtb
dtb-y += gxl_p212_1g_hd.dtb
dtb-y += gxl_p212_2g.dtb
dtb-y += gxl_p212_2g_buildroot.dtb

targets += dtbs

DTB_NAMES := $(subst $\",,$(CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE_NAMES))
ifneq ($(DTB_NAMES),)
DTB_LIST := $(addsuffix .dtb,$(DTB_NAMES))
else
DTB_LIST := $(dtb-y)
endif
targets += $(DTB_LIST)

dtbs: $(addprefix $(obj)/, $(DTB_LIST))

$(info DTB_LIST: $(DTB_LIST))

clean-files := *.dtb
