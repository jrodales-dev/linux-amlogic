# Makefile corrigido para drivers/pinctrl/meson/

# Arquivo base comum, compilado se qualquer driver meson for usado
obj-$(CONFIG_AMLOGIC_PINCTRL) += pinctrl-meson.o

# Compila cada driver APENAS se sua respectiva opção estiver habilitada no .config
obj-$(CONFIG_AMLOGIC_PINCTRL_MESON8)   += pinctrl-meson8.o
obj-$(CONFIG_AMLOGIC_PINCTRL_MESON8B)  += pinctrl-meson8b.o
obj-$(CONFIG_AMLOGIC_PINCTRL_MESON_GXBB) += pinctrl-meson-gxbb.o

# Adicione esta linha se você já adicionou o arquivo pinctrl-meson-gxl.c
obj-$(CONFIG_AMLOGIC_PINCTRL_MESON_GXL)  += pinctrl-meson-gxl.o
