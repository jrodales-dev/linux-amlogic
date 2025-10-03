# Android Pie Partition Table Fix for USB Burning Tool

## Problema / Problem

O processo de flash da custom ROM Android 9 Pie com o kernel compilado estava falho ao tentar gravar a partição vendor usando a ferramenta USB Burning Tool. O erro ocorria durante o processo de flash, não no primeiro boot do device.

The flash process for Android 9 Pie custom ROM with the compiled kernel was failing when trying to write the vendor partition using the USB Burning Tool. The error occurred during the flash process, not on the device's first boot.

## Causa Raiz / Root Cause

A tabela de partições no arquivo `partition_mbox_normal.dtsi` estava incompleta para os requisitos do Android 9 Pie. Faltavam partições essenciais que o Android Pie requer:

The partition table in the `partition_mbox_normal.dtsi` file was incomplete for Android 9 Pie requirements. Essential partitions required by Android Pie were missing:

1. **metadata** - Partição de metadados (16MB)
2. **vbmeta** - Partição de verified boot (2MB)
3. **product** - Partição de apps/libs específicos do produto (128MB)

Além disso, a configuração do firmware estava referenciando uma partição vbmeta que não existia na tabela de partições, causando falhas durante o processo de flash.

Additionally, the firmware configuration was referencing a vbmeta partition that didn't exist in the partition table, causing failures during the flash process.

## Solução / Solution

### Alterações Realizadas / Changes Made

1. **Atualização da Contagem de Partições**
   - De 14 partições para 17 partições
   - Updated partition count from 14 to 17

2. **Adição de Partições Obrigatórias do Android Pie**
   - `metadata` (16MB) - Armazena metadados do sistema
   - `vbmeta` (2MB) - Informações de verificação de boot
   - `product` (128MB) - Apps e bibliotecas específicas do produto

3. **Ajuste de Tamanhos de Partições**
   - `vendor`: 256MB → 512MB (padrão Android Pie)
   - `odm`: 256MB → 128MB (balanceamento de armazenamento)

4. **Correção da Configuração do Firmware**
   - Atualizado vbmeta parts de "boot,system,vendor" para "vbmeta,boot,system,vendor"
   - Adicionado mount point product no fstab

### Arquivos Modificados / Modified Files

- `arch/arm64/boot/dts/amlogic/partition_mbox_normal.dtsi`
- `arch/arm/boot/dts/amlogic/partition_mbox_normal.dtsi`

### Nova Estrutura de Partições / New Partition Structure

```
Partição        | Tamanho    | Mask | Descrição
----------------|------------|------|------------------------------------------
logo            | 8MB        | 1    | Logo do bootloader
recovery        | 24MB       | 1    | Imagem de recovery
misc            | 8MB        | 1    | Dados diversos
dtbo            | 8MB        | 1    | Device Tree Blob Overlay
cri_data        | 8MB        | 2    | Dados críticos
rsv             | 16MB       | 1    | Reservado
metadata        | 16MB       | 1    | Metadados do sistema Android
vbmeta          | 2MB        | 1    | Verified Boot Metadata
param           | 16MB       | 2    | Parâmetros
boot            | 16MB       | 1    | Kernel e ramdisk
tee             | 32MB       | 1    | Trusted Execution Environment
vendor          | 512MB      | 1    | Vendor image (HALs, firmware)
odm             | 128MB      | 1    | ODM image (customizações OEM)
system          | 1856MB     | 1    | Android system image
product         | 128MB      | 1    | Product apps e libs
cache           | 1120MB     | 2    | Cache do sistema
data            | Restante   | 4    | Dados do usuário
```

## Como Aplicar / How to Apply

1. Recompilar o kernel com as alterações:
   ```bash
   make ARCH=arm64 dtbs
   ```

2. Atualizar o arquivo de imagem do USB Burning Tool com o novo DTB

3. Executar o processo de flash normalmente

4. A ferramenta agora deve reconhecer e gravar corretamente todas as partições, incluindo vendor

## Verificação / Verification

Após o flash bem-sucedido, você pode verificar as partições no device:

After successful flash, you can verify partitions on the device:

```bash
adb shell
cat /proc/partitions
ls -l /dev/block/by-name/
```

Você deve ver todas as 17 partições listadas, incluindo metadata, vbmeta e product.

You should see all 17 partitions listed, including metadata, vbmeta, and product.

## Referências / References

- Android Partitions Documentation: https://source.android.com/devices/bootloader/partitions
- Amlogic USB Burning Tool Guide
- Android Verified Boot 2.0: https://source.android.com/security/verifiedboot

## Notas Adicionais / Additional Notes

- Esta correção é compatível com Android Pie (9.0) e versões superiores
- Para versões anteriores do Android, use os arquivos de partição originais
- O tamanho da partição vendor pode ser ajustado conforme necessário pela sua ROM

- This fix is compatible with Android Pie (9.0) and higher versions
- For earlier Android versions, use the original partition files
- The vendor partition size can be adjusted as needed by your ROM
