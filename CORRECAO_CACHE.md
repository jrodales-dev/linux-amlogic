# Correção do Erro de Montagem da Partição Cache

## Descrição do Problema

Após fazer o flash com sucesso de uma custom ROM com kernel modificado (versão ARM 32 bits) usando a USB Burning Tool, o sistema estava falhando ao inicializar e voltando para o bootloader com os seguintes erros:

```
suporter api: 3
E: failed to mount /cache (Invalid argument)
E: failed to mount /cache/recovery/last_locale
E: failed to mount /cache (Invalid argument)
```

## Análise da Causa Raiz

O problema foi causado por uma **entrada fstab faltando para a partição cache** no arquivo de configuração da device tree `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi`.

Embora a partição cache estivesse devidamente definida na seção de partições:
```c
cache:cache
{
    pname = "cache";
    size = <0x0 0x46000000>;  // 1120 MB
    mask = <2>;
};
```

Ela estava **faltando na seção firmware fstab**, que é necessária para o sistema init do Android e o modo recovery montarem corretamente a partição.

## Solução Aplicada

Adicionada a entrada da partição cache na seção fstab em `partition_mbox_p212_custom.dtsi`:

```diff
      metadata {
        compatible = "android,metadata";
        dev = "/dev/block/metadata";
        type = "ext4";
        mnt_flags = "defaults";
        fsmgr_flags = "wait";
        };
+     cache {
+       compatible = "android,cache";
+       dev = "/dev/block/cache";
+       type = "ext4";
+       mnt_flags = "nosuid,nodev,barrier=1";
+       fsmgr_flags = "wait";
+       };
      };
    };
  };
};
```

### Detalhes da Configuração

- **compatible**: `"android,cache"` - Identifica esta como a partição cache do Android
- **dev**: `"/dev/block/cache"` - Caminho do dispositivo de bloco para a partição cache
- **type**: `"ext4"` - Tipo de sistema de arquivos (ext4 é o padrão para cache do Android)
- **mnt_flags**: `"nosuid,nodev,barrier=1"` - Flags de montagem:
  - `nosuid`: Não permite que bits set-user-ID ou set-group-ID tenham efeito
  - `nodev`: Não interpreta dispositivos especiais de caractere ou bloco
  - `barrier=1`: Habilita barreiras de escrita para integridade de dados
- **fsmgr_flags**: `"wait"` - Aguarda a partição estar disponível antes de continuar o boot

## Por Que Esta Correção Funciona

1. **Modo Recovery**: O recovery do Android lê o fstab da device tree para determinar quais partições montar. Sem a entrada cache, o recovery não consegue montar `/cache` e falha com erro "Invalid argument".

2. **Processo de Boot**: O sistema init usa o fstab para montar partições durante o boot. A entrada cache faltando causa falha no boot ou retorno ao recovery.

3. **Uso da Partição Cache**: A partição cache é usada pelo Android para:
   - Logs do recovery (`/cache/recovery/`)
   - Pacotes de atualização OTA
   - Arquivos temporários durante atualizações
   - Cache de dados de aplicativos (em versões antigas do Android)

## Resultado Esperado

Após aplicar esta correção e recompilar o kernel com a device tree corrigida:

✅ O sistema deve inicializar normalmente sem voltar ao bootloader  
✅ O modo recovery montará `/cache` com sucesso  
✅ Os logs do recovery serão gravados corretamente em `/cache/recovery/`  
✅ As atualizações OTA funcionarão corretamente  

## Como Aplicar

1. **Recompilar o Device Tree Blob (DTB)**:
   ```bash
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs
   ```

2. **Recompilar o Kernel** (se necessário):
   ```bash
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
   ```

3. **Fazer Flash da ROM/Kernel Atualizado**:
   - Use a USB Burning Tool com a imagem atualizada
   - O arquivo DTB deve ser: `arch/arm/boot/dts/amlogic/gxl_p212_2g_custom.dtb`

4. **Verificar Após o Boot**:
   ```bash
   # Conectar via ADB
   adb shell mount | grep cache
   # Deve mostrar: /dev/block/cache on /cache type ext4 (...)
   ```

## Arquivos Relacionados

- **Modificado**: `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi`
- **Usa Este**: `arch/arm/boot/dts/amlogic/gxl_p212_2g_custom.dts`

## Notas Adicionais

- Esta correção é específica para esquemas de partição não-A/B. Sistemas A/B (como `partition_mbox_ab_P_32.dtsi`) não usam partição cache.
- O tamanho da partição cache (1120 MB / 0x46000000 bytes) já estava corretamente definido e não precisa ser alterado.
- Todas as outras partições (system, vendor, odm, product, metadata) já tinham entradas no fstab.

## Resumo das Mudanças

**Arquivo modificado**: `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi`

**Alterações**:
- Adicionada entrada fstab para partição cache (7 linhas)
- Configurada com flags apropriadas para segurança e integridade de dados

**Total**: 1 arquivo modificado, 7 linhas adicionadas

---

**Status**: ✅ Correção aplicada com sucesso

## O Que Fazer Agora

1. Recompile o kernel com as alterações da device tree
2. Faça o flash da nova imagem usando a USB Burning Tool
3. O dispositivo deve inicializar normalmente no Android
4. Verifique se o sistema está funcionando corretamente

Se você ainda encontrar problemas após aplicar esta correção, por favor verifique:
- Se o flash foi completado com sucesso
- Se a partição cache existe no dispositivo (`ls -la /dev/block/`)
- Se não há problemas de corrupção no sistema de arquivos da partição cache
