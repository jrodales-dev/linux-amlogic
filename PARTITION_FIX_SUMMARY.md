# Vendor Partition Flash Error - Fix Summary

## Problem Description (Portuguese)

A branch `vendor_partition_fix` introduziu alguns ajustes nos arquivos DTS e DTSI dentro de `arch/arm/boot/dts/amlogic/`, mais especificamente nos arquivos:
- `gxl_p212_2g_custom.dts`
- `partition_mbox_p212_custom.dtsi`

O processo de flash da custom ROM Android 9 Pie com o novo kernel compilado estava falhando durante o uso da ferramenta USB Burning Tool, com erros relacionados à partição vendor.

## Root Cause Analysis

Após comparar o arquivo DTS original funcional (`.github/workflows/original_gxl_p212_2g.dts`) com os arquivos customizados, foram identificadas **três diferenças críticas** que causavam a falha no flash:

### 1. Tamanho Incorreto da Partição Vendor (CRÍTICO)

**Arquivo:** `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi` (linha 99)

- **Original (funcional):** `size = <0x0 0x20000000>;` → **512 MB**
- **Custom (problemático):** `size = <0x0 0x10000000>;` → **256 MB**

A partição vendor estava com **metade do tamanho necessário**, causando erro de espaço insuficiente durante o processo de flash.

### 2. Tamanho Incorreto da Partição ODM (CRÍTICO)

**Arquivo:** `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi` (linha 105)

- **Original (funcional):** `size = <0x0 0x8000000>;` → **128 MB**
- **Custom (problemático):** `size = <0x0 0x10000000>;` → **256 MB**

A partição ODM estava com **o dobro do tamanho correto**, provavelmente causando sobreposição de limites de partição.

### 3. Lista de Verificação VBmeta Incompleta

**Arquivo:** `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi` (linha 140)

- **Original (funcional):** `parts = "vbmeta,boot,system,vendor";`
- **Custom (problemático):** `parts = "boot,system,vendor";`

A partição "vbmeta" estava faltando na lista de partes verificadas pelo Android Verified Boot.

## Solution Applied

As seguintes correções foram aplicadas no arquivo `partition_mbox_p212_custom.dtsi`:

```diff
vendor:vendor
{
    pname = "vendor";
-   size = <0x0 0x10000000>;  // 256 MB - INCORRETO
+   size = <0x0 0x20000000>;  // 512 MB - CORRETO
    mask = <1>;
};

odm:odm
{
    pname = "odm";
-   size = <0x0 0x10000000>;  // 256 MB - INCORRETO
+   size = <0x0 0x8000000>;   // 128 MB - CORRETO
    mask = <1>;
};

vbmeta {
    compatible = "android,vbmeta";
-   parts = "boot,system,vendor";                  // INCOMPLETO
+   parts = "vbmeta,boot,system,vendor";           // CORRETO
    by_name_prefix="/dev/block";
};
```

## Partition Layout Comparison

| Partition | Original (Working) | Custom (Before Fix) | Custom (After Fix) | Status |
|-----------|-------------------|---------------------|-------------------|--------|
| logo      | 8 MB             | 8 MB                | 8 MB              | ✅ OK  |
| recovery  | 24 MB            | 24 MB               | 24 MB             | ✅ OK  |
| misc      | 8 MB             | 8 MB                | 8 MB              | ✅ OK  |
| dtbo      | 8 MB             | 8 MB                | 8 MB              | ✅ OK  |
| cri_data  | 8 MB             | 8 MB                | 8 MB              | ✅ OK  |
| rsv       | 16 MB            | 16 MB               | 16 MB             | ✅ OK  |
| metadata  | 16 MB            | 16 MB               | 16 MB             | ✅ OK  |
| vbmeta    | 2 MB             | 2 MB                | 2 MB              | ✅ OK  |
| param     | 16 MB            | 16 MB               | 16 MB             | ✅ OK  |
| boot      | 16 MB            | 16 MB               | 16 MB             | ✅ OK  |
| tee       | 32 MB            | 32 MB               | 32 MB             | ✅ OK  |
| **vendor**| **512 MB**       | **256 MB** ❌       | **512 MB** ✅     | **FIXED** |
| **odm**   | **128 MB**       | **256 MB** ❌       | **128 MB** ✅     | **FIXED** |
| system    | 1856 MB          | 1856 MB             | 1856 MB           | ✅ OK  |
| product   | 128 MB           | 128 MB              | 128 MB            | ✅ OK  |
| cache     | 1120 MB          | 1120 MB             | 1120 MB           | ✅ OK  |
| data      | Remaining        | Remaining           | Remaining         | ✅ OK  |

## Expected Result

Com estas correções aplicadas:

1. ✅ A partição vendor agora tem o tamanho correto (512 MB) para acomodar os dados do vendor
2. ✅ A partição ODM está com o tamanho apropriado (128 MB) sem causar sobreposição
3. ✅ A verificação VBmeta incluirá a própria partição vbmeta na lista de partes verificadas
4. ✅ O processo de flash usando USB Burning Tool deve completar com sucesso

## Testing Recommendation

Após aplicar estas correções:

1. Recompilar o kernel com o arquivo DTS/DTSI corrigido
2. Testar o processo de flash usando USB Burning Tool
3. Verificar se o dispositivo inicializa corretamente após o flash
4. Confirmar que todas as partições estão montadas corretamente, especialmente vendor e ODM

## Files Modified

- `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi` (3 changes)
  - Line 99: vendor partition size corrected
  - Line 105: odm partition size corrected  
  - Line 140: vbmeta parts list completed

## References

- Original working DTS: `.github/workflows/original_gxl_p212_2g.dts`
- Custom DTS file: `arch/arm/boot/dts/amlogic/gxl_p212_2g_custom.dts`
- Custom partition DTSI: `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi`

---

**Note:** These changes align the custom partition configuration with the original working configuration that successfully flashes and boots on the TV box device.
