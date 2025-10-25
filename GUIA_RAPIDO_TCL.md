# Guia Rápido: Controle Remoto TCL no S905X

## ✅ Resposta Rápida

**SIM! Você pode usar um controle remoto TCL na sua TV Box S905X com Android Pie 9.**

O driver IR já está presente no kernel e foi criado um keymap específico para controles TCL.

---

## 🚀 Configuração Rápida (3 Passos)

### 1. Compile o Kernel

```bash
# Configure
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

# Habilite:
# Device Drivers > Multimedia > Remote Controller
#   [M] Remote controller decoders
#   [*] Enable IR raw decoder for NEC protocol
#   [M] Amlogic Meson IR remote receiver

# Compile
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc) zImage modules dtbs
```

### 2. Configure o Device Tree

Edite o arquivo DTS da sua placa (ex: `arch/arm/boot/dts/amlogic/gxl_p212_2g.dts`):

```dts
&ir {
    status = "okay";
    pinctrl-0 = <&remote_pins>;
    pinctrl-names = "default";
    linux,rc-map-name = "rc-tcl-tv";
};
```

### 3. Flash e Teste

```bash
# Flash o kernel e DTB na TV Box
# Via USB Burning Tool ou adb

# Teste via ADB
adb shell
ir-keytable -t
# Pressione teclas do controle TCL
```

---

## 📋 Checklist Rápida

- [ ] Driver `meson-ir` habilitado no kernel
- [ ] Keymap `rc-tcl-tv` compilado
- [ ] Device Tree configurado com `linux,rc-map-name = "rc-tcl-tv"`
- [ ] Kernel e DTB atualizados na TV Box
- [ ] Protocolo NEC habilitado: `echo '+nec' > /sys/class/rc/rc0/protocols`
- [ ] Testado com script: `bash scripts/test_tcl_remote.sh`

---

## 🔍 Verificação Rápida

```bash
# Verificar se IR está funcionando
adb shell ls /sys/class/rc/rc0
# Deve listar: device, input*, protocols, etc.

# Verificar protocolos
adb shell cat /sys/class/rc/rc0/protocols
# Deve incluir: [nec] ou nec

# Testar recepção
adb shell ir-keytable -t
# Pressione teclas do controle
```

---

## 🛠️ Scripts Disponíveis

```bash
# 1. Verificar suporte IR
bash scripts/check_ir_support.sh

# 2. Testar controle remoto
bash scripts/test_tcl_remote.sh

# 3. Aplicar keymap TCL
bash scripts/apply_tcl_keymap.sh
```

---

## 📚 Documentação Completa

Para informações detalhadas, consulte:

- **`CONTROLE_REMOTO_TCL_S905X.md`** - Documentação completa (português)
  - Análise técnica detalhada
  - 3 métodos de configuração
  - Troubleshooting completo
  - Tabela de compatibilidade

- **`arch/arm/boot/dts/amlogic/ir-tcl-remote-example.dtsi`** - Exemplo Device Tree

- **`drivers/media/rc/keymaps/rc-tcl-tv.c`** - Código do keymap

---

## ⚡ Solução de Problemas Rápida

### Controle não responde?
```bash
# Carregar driver
modprobe meson-ir

# Habilitar NEC
echo '+nec' > /sys/class/rc/rc0/protocols

# Testar
ir-keytable -t
```

### Códigos diferentes?
```bash
# Capture os códigos do seu controle
ir-keytable -t
# Anote os scancodes

# Edite rc-tcl-tv.c com os códigos corretos
# Recompile o kernel
```

### Device Tree não funciona?
```bash
# Verifique status
cat /sys/firmware/devicetree/base/ir@*/status
# Deve mostrar: okay

# Se não, edite o DTS e recompile
```

---

## 📊 Compatibilidade

| Controle TCL | Protocolo | Compatível |
|--------------|-----------|------------|
| RC200        | NEC 0x04  | ✅ Sim     |
| RC300        | NEC 0x14  | ✅ Sim     |
| RC802N       | NEC 0x14  | ✅ Sim     |
| Smart Remote | NEC 0x14  | ✅ Sim     |
| Roku Remote  | RC6       | ⚠️ Parcial |

---

## 🎯 Comandos Úteis

```bash
# Ver eventos IR em tempo real
adb shell getevent -l /dev/input/event2

# Listar keymaps disponíveis
ls /lib/modules/*/kernel/drivers/media/rc/keymaps/

# Aplicar keymap temporariamente
ir-keytable -c -p nec -s rc0

# Ver dmesg do IR
dmesg | grep -i "meson.*ir\|rc"
```

---

## ✅ Resultado Esperado

Após a configuração, o controle TCL deve funcionar como:
- ✅ Power liga/desliga a TV Box
- ✅ Números 0-9 funcionam
- ✅ Navegação (setas + OK) funciona
- ✅ Volume +/- funciona
- ✅ Menu, Back, Home funcionam
- ✅ Controles de mídia funcionam (Play, Pause, etc.)

---

## 💡 Dicas

1. **Bateria Nova:** Use bateria nova no controle para melhor alcance
2. **Linha de Visão:** Mantenha linha de visão direta com o receptor IR
3. **Distância:** Funciona até ~10 metros de distância
4. **LED IR:** O LED do controle deve piscar ao pressionar teclas (visível com câmera de celular)

---

## 🔗 Links Úteis

- Driver Meson IR: `drivers/media/rc/meson-ir.c`
- Keymap TCL: `drivers/media/rc/keymaps/rc-tcl-tv.c`
- Device Tree: `arch/arm/boot/dts/amlogic/`
- Protocolos: `Documentation/media/uapi/rc/`

---

**Status: ✅ PRONTO PARA USO**

Para começar, compile o kernel e configure o Device Tree conforme acima!
