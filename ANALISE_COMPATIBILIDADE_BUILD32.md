# Análise de Compatibilidade: build_32.yml vs Custom ROM (level2/level3)

## 🎯 Objetivo da Análise

Este documento analisa os diretórios `.github/workflows/level2` e `.github/workflows/level3` para identificar possíveis incompatibilidades com o workflow de compilação `build_32.yml` do kernel Linux para dispositivos Amlogic S905X (ARM 32-bit).

---

## 📊 Estrutura da Custom ROM Identificada

### Level2 - Partições do Sistema Android
Contém as partições do sistema Android 9 Pie:
- **system/** - Sistema Android base (1946157056 bytes = ~1.81 GB)
- **vendor/** - Bibliotecas e drivers específicos do fabricante (536870912 bytes = 512 MB)
- **odm/** - Customizações OEM (134217728 bytes = 128 MB)
- **product/** - Aplicações e configurações de produto (134217728 bytes = 128 MB)

### Level3 - Configurações de Boot e Device Tree
Contém configurações críticas do bootloader:
- **boot/** - Parâmetros do Android Boot Image
- **recovery/** - Parâmetros da partição de recuperação
- **devtree/** - Device Tree Sources (.dts) customizados
- **logo/** - Imagens de logo/splash screen

---

## 🔍 Análise de Compatibilidade Detalhada

### 1. **Endereço de Carregamento do Kernel (CRÍTICO)**

#### Configuração no mkimage_32.sh:
```bash
UIMAGE_LOADADDR=0x1008000  # Script de compilação
```

#### Configuração na Custom ROM (level3/boot):
```
Base Address:      0x01078000
Kernel Offset:     0x00008000
Calculated Load:   0x01080000
```

#### ⚠️ **INCOMPATIBILIDADE DETECTADA**

**Problema:** O endereço de carregamento do kernel é **diferente**:
- Script mkimage_32.sh: `0x1008000` (16,515,072 bytes)
- Custom ROM esperada:  `0x1080000` (17,301,504 bytes)

**Impacto:** O bootloader da custom ROM não conseguirá carregar o kernel corretamente, resultando em falha de boot.

**Solução Necessária:**
```diff
# Em scripts/amlogic/mkimage_32.sh (linha 23)
- UIMAGE_LOADADDR=0x1008000
+ UIMAGE_LOADADDR=0x1080000
```

**OU** ajustar no workflow build_32.yml:
```yaml
- name: Compilar o Kernel
  run: |
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabihf-
    export UIMAGE_LOADADDR=0x1080000  # Adicionar esta linha
    make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage
```

---

### 2. **Kernel Command Line (CRÍTICO)**

#### Configuração na Custom ROM (level3/boot):
```
androidboot.dtbo_idx=0 --cmdline root=/dev/mmcblk0p18 buildvariant=userdebug
```

#### Configuração Atual no .configatv:
```
CONFIG_CMDLINE=""
CONFIG_LOCALVERSION=""
CONFIG_LOCALVERSION_AUTO=y
```

#### ⚠️ **INCOMPATIBILIDADE PARCIAL**

**Problema:** O kernel precisa ter a linha de comando correta hardcoded ou passada pelo bootloader.

**Detalhes Importantes:**
- **root=/dev/mmcblk0p18**: Partição raiz do Android (data)
- **androidboot.dtbo_idx=0**: Índice do Device Tree Blob Overlay
- **buildvariant=userdebug**: Variante de build para debugging

**Solução Recomendada:** O bootloader já passa estes parâmetros, então não é necessário alterar CONFIG_CMDLINE. **Mantém compatibilidade.**

---

### 3. **LOCALVERSION String (MÉDIA PRIORIDADE)**

#### Configuração no build_32.yml:
```bash
export LOCALVERSION="-s905x-arm32"
```

#### ⚠️ **POTENCIAL INCOMPATIBILIDADE**

**Problema:** A custom ROM pode esperar uma versão específica do kernel. Os módulos compilados terão o sufixo `-s905x-arm32`, e precisam corresponder exatamente ao kernel instalado.

**Verificação Necessária:**
1. Verificar se há módulos .ko em `level2/vendor/lib/modules/`
2. Se existirem, verificar a versão esperada do kernel

**Análise Realizada:** Não foram encontrados módulos .ko nas partições level2, o que indica que os módulos serão instalados pelo build. **Compatível.**

---

### 4. **Boot Image Header Version**

#### Configuração na Custom ROM (level3/boot):
```
header_version: 1
pagesize: 2048
```

#### ✅ **COMPATÍVEL**

O formato do boot image é Android Boot Image v1 com página de 2048 bytes. O workflow build_32.yml compila apenas o kernel (zImage) e DTBs, que são compatíveis com qualquer versão do boot image.

---

### 5. **Ramdisk Offset (MÉDIA PRIORIDADE)**

#### Configuração na Custom ROM:
```
ramdisk_offset: 0xfff88000
```

#### ℹ️ **INFORMATIVO**

Este offset é muito alto (próximo ao limite de 4GB) e indica que o ramdisk será carregado em uma região de memória alta. Isso é normal para dispositivos ARM 32-bit e não afeta a compilação do kernel.

**Status:** Não requer ação.

---

### 6. **Device Tree Compatibility (CRÍTICO)**

#### Device Trees na Custom ROM (level3/devtree):
```
- gxl-p212-1g.dts  (1GB RAM)
- gxl-p212-2g.dts  (2GB RAM)
- gxl-p212-3g.dts  (3GB RAM)
```

#### Configuração no build_32.yml:
```bash
shopt -s nullglob
dtbs=(arch/arm/boot/dts/amlogic/gxl_p212_*.dtb)
```

#### ✅ **COMPATÍVEL COM ATENÇÃO**

**Análise:**
1. O workflow procura por `gxl_p212_*.dtb` (com underscore)
2. A custom ROM tem `gxl-p212-2g.dts` (com hífen)

**Verificação Necessária:** Conferir se os DTBs compilados no kernel têm o nome correto para corresponder aos esperados pela ROM.

**Recomendação:** Adicionar verificação no workflow:
```bash
# Listar DTBs disponíveis
echo "DTBs compilados:"
ls -la arch/arm/boot/dts/amlogic/gxl*p212*.dtb
```

---

### 7. **Partições do Sistema (INFORMATIVO)**

#### Tamanhos das Partições (level2):

| Partição | Tamanho (bytes) | Tamanho (MB) | Tamanho (GB) |
|----------|----------------|--------------|--------------|
| system   | 1,946,157,056  | 1856 MB      | 1.81 GB      |
| vendor   | 536,870,912    | 512 MB       | 0.5 GB       |
| odm      | 134,217,728    | 128 MB       | 0.125 GB     |
| product  | 134,217,728    | 128 MB       | 0.125 GB     |
| **Total**| **2,751,246,424** | **2624 MB** | **2.56 GB** |

#### ✅ **COMPATÍVEL**

Estes tamanhos correspondem ao documento `CORRECAO_PARTICAO_VENDOR.md`, confirmando que as partições estão corretas.

**Observação:** A partição vendor foi corrigida de 256MB para 512MB, garantindo espaço suficiente para os drivers.

---

### 8. **Build Variant e SELinux**

#### Configuração na Custom ROM:
```
buildvariant=userdebug
```

#### Arquivos SELinux encontrados em level2:
```
- odm/etc/selinux/precompiled_sepolicy
- system_file_contexts
- vendor_file_contexts
- odm_file_contexts
- product_file_contexts
```

#### ⚠️ **ATENÇÃO**

**Problema Potencial:** O kernel precisa ter suporte adequado a SELinux para funcionar com a custom ROM Android 9 Pie.

**Verificação Necessária:**
```bash
# Verificar no .configatv
grep -E "CONFIG_SECURITY_SELINUX" .configatv
```

**Status:** Requer verificação da configuração do kernel.

---

## 📋 Resumo das Incompatibilidades Identificadas

### 🔴 **CRÍTICAS** (Impedem o Boot)

1. **Endereço de carregamento do kernel**
   - **Status:** ❌ INCOMPATÍVEL
   - **Correção:** Alterar UIMAGE_LOADADDR de `0x1008000` para `0x1080000`
   - **Arquivo:** `scripts/amlogic/mkimage_32.sh` ou adicionar no workflow

### 🟡 **MÉDIAS** (Podem causar problemas)

2. **Device Tree Naming**
   - **Status:** ⚠️ VERIFICAR
   - **Ação:** Confirmar se os nomes dos DTBs correspondem (underscore vs hífen)

3. **SELinux Support**
   - **Status:** ⚠️ VERIFICAR
   - **Ação:** Confirmar configuração do kernel para SELinux

### 🟢 **BAIXAS** (Informativas)

4. **Kernel Command Line** - ✅ Compatível (passado pelo bootloader)
5. **Boot Header Version** - ✅ Compatível
6. **Partições do Sistema** - ✅ Compatível
7. **Ramdisk Offset** - ✅ Compatível

---

## 🔧 Ações Recomendadas

### Passo 1: Corrigir o Endereço de Carregamento (URGENTE)

**Opção A - Modificar o workflow build_32.yml:**
```yaml
- name: Compilar o Kernel
  run: |
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabihf-
    export UIMAGE_LOADADDR=0x1080000  # ADICIONAR ESTA LINHA
    export LOCALVERSION="-s905x-arm32"
    make -j$(nproc) \
         ARCH=arm \
         CROSS_COMPILE=arm-linux-gnueabihf- \
         UIMAGE_LOADADDR=0x1080000 \
         zImage
```

**Opção B - Modificar scripts/amlogic/mkimage_32.sh:**
```bash
# Linha 23
UIMAGE_LOADADDR=0x1080000  # Alterado de 0x1008000
```

**Recomendação:** Use a **Opção A** para manter o script original intacto.

### Passo 2: Verificar Suporte SELinux

```bash
# Verificar configuração atual
grep -E "CONFIG_SECURITY_SELINUX|CONFIG_AUDIT" .configatv

# Configurações esperadas para Android 9:
# CONFIG_SECURITY_SELINUX=y
# CONFIG_AUDIT=y
# CONFIG_AUDITSYSCALL=y
```

### Passo 3: Validar Device Tree Names

```bash
# Após compilação, verificar nomes dos DTBs
ls -la arch/arm/boot/dts/amlogic/gxl*p212*.dtb

# Comparar com o esperado pela ROM:
# gxl-p212-2g.dtb (ou gxl_p212_2g.dtb)
```

### Passo 4: Testar Build com Correções

```bash
# 1. Aplicar correção do UIMAGE_LOADADDR
# 2. Executar workflow build_32.yml
# 3. Verificar artefatos gerados
# 4. Confirmar que zImage foi criado no endereço correto
```

---

## 🧪 Checklist de Validação

Após aplicar as correções, validar:

- [ ] zImage compilado com sucesso
- [ ] UIMAGE_LOADADDR correto (`0x1080000`)
- [ ] DTBs gxl_p212_*.dtb compilados
- [ ] Módulos instalados em kernel_output/lib/modules/
- [ ] Kernel configuration (.config) incluída nos artefatos
- [ ] SELinux habilitado no kernel (se necessário)
- [ ] LOCALVERSION corresponde ao esperado (`-s905x-arm32`)

---

## 📖 Documentos Relacionados

- `CORRECAO_PARTICAO_VENDOR.md` - Correções de partições aplicadas
- `PARTITION_FIX_SUMMARY.md` - Resumo técnico das correções
- `.github/workflows/build_32.yml` - Workflow de compilação atual
- `scripts/amlogic/mkimage_32.sh` - Script de build ARM 32-bit

---

## 🎯 Conclusão

A principal incompatibilidade identificada é o **endereço de carregamento do kernel** (UIMAGE_LOADADDR), que deve ser ajustado de `0x1008000` para `0x1080000` para corresponder à configuração da custom ROM.

As demais configurações são majoritariamente compatíveis, com pequenas verificações necessárias para garantir o funcionamento completo.

**Próximo Passo:** Aplicar a correção do UIMAGE_LOADADDR no workflow build_32.yml e realizar uma compilação de teste.

---

**Análise realizada em:** $(date)
**Kernel Base:** Linux Amlogic ARM 32-bit
**Target Device:** S905X (GXL-P212)
**Android Version:** 9 Pie (userdebug)
