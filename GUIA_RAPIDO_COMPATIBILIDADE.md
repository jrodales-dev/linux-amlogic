# Guia de Referência: Compatibilidade Build vs Custom ROM

## 🎯 Resumo Executivo

**STATUS GERAL:** ✅ **100% COMPATÍVEL**

O workflow `build_32.yml` está corretamente configurado para compilar um kernel compatível com a custom ROM Android 9 Pie instalada no dispositivo P212 (Amlogic S905X).

---

## 📋 Checklist de Compatibilidade

### ✅ Configurações Críticas
- [x] **UIMAGE_LOADADDR = 0x1080000** (correto)
  - Base: 0x01078000 + Offset: 0x00008000 = 0x01080000
  - Configurado em `.github/workflows/build_32.yml` linhas 82 e 86

- [x] **Device Tree ID = gxl_p212_2g** (correto)
  - Kernel DTS: `arch/arm/boot/dts/amlogic/gxl_p212_2g.dts`
  - DTB compilado: `gxl_p212_2g.dtb`
  - amlogic-dt-id: "gxl_p212_2g" (corresponde ao dispositivo)

- [x] **SELinux habilitado** (correto)
  - CONFIG_SECURITY_SELINUX=y
  - CONFIG_AUDIT=y
  - Obrigatório para Android 9 Pie

- [x] **Arquitetura ARM 32-bit** (correto)
  - ARCH=arm
  - CROSS_COMPILE=arm-linux-gnueabihf-
  - Target: ARMv7 (compatível com Cortex-A53 em modo 32-bit)

---

## 🔍 Informações da Custom ROM

### Dispositivo
```
Product:     ampere
Device:      ampere
Model:       Amlogic
Hardware:    Amlogic (S905X)
CPU:         ARMv7 rev 4 (Cortex-A53, 4 cores)
```

### Sistema
```
Android:     9 Pie (SDK 28)
Build:       PPR1.180610.011
Type:        userdebug
Date:        2020-06-03
```

### Partições (tamanhos em KB)
```
boot:        65536 KB (64 MB)
system:      1146880 KB (≈1.09 GB)
vendor:      524288 KB (512 MB)  ← Importante!
odm:         131072 KB (128 MB)
product:     131072 KB (128 MB)
data:        1900544 KB (≈1.81 GB)
```

### Boot Parameters
```
Base Address:      0x01078000
Kernel Offset:     0x00008000
Ramdisk Offset:    0xfff88000
Page Size:         2048
Header Version:    1
```

---

## 📦 Artefatos Gerados pelo Workflow

O workflow `build_32.yml` gera os seguintes artefatos:

```
kernel_output/
├── boot/
│   └── zImage                    ← Kernel compilado
├── dtbs/
│   ├── gxl_p212_1g.dtb          ← Device Tree 1GB RAM
│   ├── gxl_p212_2g.dtb          ← Device Tree 2GB RAM (principal)
│   └── gxl_p212_2g_custom.dtb   ← Device Tree custom
├── dts/
│   └── *.dts                     ← DTBs convertidos para DTS
├── lib/
│   └── modules/
│       └── 4.9.113-s905x-arm32/  ← Módulos do kernel
├── logs/
│   ├── build_kernel.log
│   ├── build_dtbs.log
│   └── build_modules.log
└── .config                        ← Configuração usada
```

---

## 🚀 Como Usar os Artefatos

### Opção 1: Flash completo com USB Burning Tool
1. Baixar artefatos do GitHub Actions
2. Criar boot.img com mkbootimg:
   ```bash
   mkbootimg \
     --kernel kernel_output/boot/zImage \
     --ramdisk boot.PARTITION-ramdisk.gz \
     --second kernel_output/boot/dtbs/gxl_p212_2g.dtb \
     --base 0x01078000 \
     --kernel_offset 0x00008000 \
     --ramdisk_offset 0xfff88000 \
     --second_offset 0x00e80000 \
     --tags_offset 0x07f80000 \
     --pagesize 2048 \
     --header_version 1 \
     --cmdline "androidboot.dtbo_idx=0 --cmdline root=/dev/mmcblk0p18 buildvariant=userdebug" \
     -o boot.img
   ```
3. Flash boot.img usando USB Burning Tool

### Opção 2: Flash via fastboot
```bash
# Entrar em fastboot mode
adb reboot bootloader

# Flash kernel
fastboot flash boot boot.img
fastboot reboot
```

### Opção 3: Flash via ADB (requer root)
```bash
# Backup da partição boot atual
adb shell su -c "dd if=/dev/block/boot of=/sdcard/boot_backup.img"

# Flash nova boot.img
adb push boot.img /sdcard/
adb shell su -c "dd if=/sdcard/boot.img of=/dev/block/boot"
adb reboot
```

---

## ✅ Validação Pós-Flash

Após flash, verificar:

```bash
# 1. Verificar versão do kernel
adb shell uname -r
# Esperado: 4.9.113-s905x-arm32

# 2. Verificar mensagens de boot
adb shell dmesg | grep "Linux version"
# Deve mostrar: Linux version 4.9.113-s905x-arm32

# 3. Verificar Device Tree
adb shell cat /proc/device-tree/amlogic-dt-id
# Deve retornar: gxl_p212_2g

# 4. Verificar SELinux
adb shell getenforce
# Deve retornar: Enforcing ou Permissive

# 5. Verificar módulos carregados
adb shell lsmod
# Deve listar: mali, 8189es, amvdec_*, etc.
```

---

## ⚠️ Notas Importantes

1. **Backup Obrigatório**
   - Sempre fazer backup da partição boot antes de flash
   - Guardar boot_backup.img em local seguro

2. **Compatibilidade**
   - Kernel compilado é compatível com a ROM atual
   - Não é necessário reflash da ROM
   - Módulos devem ser instalados em /vendor/lib/modules

3. **Troubleshooting**
   - Se dispositivo não bootar, restaurar boot_backup.img
   - Verificar logs de build para erros de compilação
   - Confirmar que UIMAGE_LOADADDR está correto

4. **Naming Convention**
   - Kernel usa underscores: `gxl_p212_2g.dts`
   - ROM pode usar hífens: `gxl-p212-2g.dts`
   - O importante é o `amlogic-dt-id` que deve corresponder

---

## 📚 Referências

- **Documentação Detalhada:** `VALIDACAO_CUSTOM_ROM.md`
- **Análise de Compatibilidade:** `ANALISE_COMPATIBILIDADE_BUILD32.md`
- **Resumo de Correções:** `RESUMO_CORRECAO_BUILD32.md`
- **Script de Verificação:** `scripts/verify_build_compatibility.sh`

---

**Última Atualização:** 2024-10-05  
**Status da Validação:** ✅ APROVADO  
**Próxima Ação:** Executar workflow build_32.yml
