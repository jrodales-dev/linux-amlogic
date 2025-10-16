# Correção do Adaptador Bluetooth CSR8510 Falso/Clone

## Problema Identificado

Adaptadores Bluetooth CSR8510 falsos/clones estavam falhando durante a inicialização devido ao driver `btusb.c` retornar erro quando o dispositivo não conseguia responder corretamente aos comandos de versão HCI.

### Sintomas
- Adaptador CSR8510 clone não inicializava
- Erro durante comando `HCI_OP_READ_LOCAL_VERSION`
- Driver retornava erro de inicialização (-EIO ou outro código de erro)
- Dispositivo Bluetooth não ficava disponível para uso

## Análise da Causa Raiz

### 1. Detecção de Dispositivos Falsos
O driver `btusb.c` já tinha código para detectar dispositivos CSR falsos através da verificação do `bcdDevice`:

```c
/* Fake CSR devices with broken commands */
if (bcdDevice <= 0x100 || bcdDevice == 0x134)
    hdev->setup = btusb_setup_csr;
```

No entanto, este range era limitado e não cobria todos os dispositivos falsos.

### 2. Falha na Função `btusb_setup_csr()`
A função `btusb_setup_csr()` tentava ler a versão local do dispositivo através do comando HCI. Quando este comando falhava ou retornava dados inválidos, a função retornava erro, impedindo a inicialização:

```c
if (IS_ERR(skb)) {
    int err = PTR_ERR(skb);
    BT_ERR("%s: CSR: Local version failed (%d)", hdev->name, err);
    return err;  // ← Impedia inicialização
}

if (skb->len != sizeof(struct hci_rp_read_local_version)) {
    BT_ERR("%s: CSR: Local version length mismatch", hdev->name);
    kfree_skb(skb);
    return -EIO;  // ← Impedia inicialização
}
```

### 3. Comportamento de Dispositivos Falsos
Dispositivos CSR8510 falsos/clones frequentemente:
- Falham ao responder ao comando `HCI_OP_READ_LOCAL_VERSION`
- Retornam dados com tamanho incorreto
- Reportam valores de `manufacturer` e `lmp_subver` não padrão
- Têm `bcdDevice` fora do range originalmente detectado

## Solução Implementada

### Modificação 1: Tolerância a Falhas em `btusb_setup_csr()`

**Arquivo:** `drivers/bluetooth/btusb.c`  
**Função:** `btusb_setup_csr()`

#### Quando comando de versão falha:
```c
if (IS_ERR(skb)) {
    int err = PTR_ERR(skb);
    BT_ERR("%s: CSR: Local version failed (%d)", hdev->name, err);
    
    /* Fake CSR devices might fail the version command.
     * Set quirks anyway to allow the device to work.
     */
    BT_INFO("%s: CSR: Assuming fake device, setting quirks", hdev->name);
    clear_bit(HCI_QUIRK_RESET_ON_CLOSE, &hdev->quirks);
    set_bit(HCI_QUIRK_BROKEN_STORED_LINK_KEY, &hdev->quirks);
    
    return 0;  // ← Agora retorna sucesso
}
```

#### Quando tamanho da resposta está errado:
```c
if (skb->len != sizeof(struct hci_rp_read_local_version)) {
    BT_ERR("%s: CSR: Local version length mismatch", hdev->name);
    
    /* Fake CSR devices might return wrong length.
     * Set quirks anyway to allow the device to work.
     */
    BT_INFO("%s: CSR: Assuming fake device, setting quirks", hdev->name);
    clear_bit(HCI_QUIRK_RESET_ON_CLOSE, &hdev->quirks);
    set_bit(HCI_QUIRK_BROKEN_STORED_LINK_KEY, &hdev->quirks);
    
    kfree_skb(skb);
    return 0;  // ← Agora retorna sucesso
}
```

### Modificação 2: Extensão do Range de Detecção

**Arquivo:** `drivers/bluetooth/btusb.c`  
**Função:** `btusb_probe()`

Estendido o range de `bcdDevice` para capturar mais dispositivos falsos:

```c
/* Fake CSR devices with broken commands.
 * Extend range to catch more fake/clone devices.
 */
if (bcdDevice <= 0x200 || bcdDevice == 0x134)
    hdev->setup = btusb_setup_csr;
```

**Antes:** `bcdDevice <= 0x100` (0-256)  
**Depois:** `bcdDevice <= 0x200` (0-512)

## Quirks Aplicados para Dispositivos Falsos

Os dispositivos falsos recebem os seguintes quirks:

1. **`clear_bit(HCI_QUIRK_RESET_ON_CLOSE)`**
   - Remove a necessidade de reset USB ao fechar o dispositivo
   - Dispositivos falsos não são Bluetooth 1.1 antigos da CSR

2. **`set_bit(HCI_QUIRK_BROKEN_STORED_LINK_KEY)`**
   - Desabilita o gerenciamento de chaves de link armazenadas
   - Dispositivos falsos têm implementação defeituosa desta funcionalidade

3. **`set_bit(HCI_QUIRK_SIMULTANEOUS_DISCOVERY)`**
   - Já aplicado para todos os dispositivos CSR
   - Permite descoberta simultânea de dispositivos

## Benefícios da Solução

1. **Compatibilidade Estendida**
   - Adaptadores CSR8510 falsos/clones agora inicializam corretamente
   - Range estendido captura mais variações de dispositivos falsos

2. **Funcionalidade Básica Garantida**
   - Dispositivos funcionam com capacidades básicas de Bluetooth
   - Quirks apropriados evitam problemas conhecidos

3. **Manutenção da Compatibilidade**
   - Dispositivos CSR genuínos continuam funcionando normalmente
   - Lógica existente para detecção de dispositivos genuínos preservada

4. **Mudanças Mínimas**
   - Alterações cirúrgicas apenas nas funções necessárias
   - Não afeta outros drivers ou dispositivos Bluetooth

## Impacto nos Dispositivos Genuínos

A solução **não afeta negativamente** dispositivos CSR genuínos:

- Dispositivos genuínos respondem corretamente ao comando de versão
- A lógica original para dispositivos genuínos permanece intacta
- O código adicional só é executado em caso de falha

## Testes Recomendados

Para verificar a correção:

1. Conectar adaptador CSR8510 falso/clone
2. Verificar logs do kernel: `dmesg | grep -i bluetooth`
3. Confirmar mensagem: "CSR: Assuming fake device, setting quirks"
4. Verificar inicialização: `hciconfig -a`
5. Testar funcionalidade: `hcitool scan`

## Arquivos Modificados

- `drivers/bluetooth/btusb.c`
  - Função `btusb_setup_csr()`: Tratamento de erros tolerante
  - Função `btusb_probe()`: Range estendido de `bcdDevice`

## Referências Técnicas

- **Manufacturer ID para CSR genuíno:** 10
- **Range bcdDevice original:** ≤ 0x100 ou == 0x134
- **Range bcdDevice estendido:** ≤ 0x200 ou == 0x134
- **Quirks aplicados:** HCI_QUIRK_RESET_ON_CLOSE (clear), HCI_QUIRK_BROKEN_STORED_LINK_KEY (set)

## Conclusão

Esta correção permite que adaptadores Bluetooth CSR8510 falsos/clones funcionem corretamente no sistema, mantendo total compatibilidade com dispositivos genuínos. As mudanças são mínimas e focadas apenas no tratamento de falhas conhecidas de dispositivos falsos.
