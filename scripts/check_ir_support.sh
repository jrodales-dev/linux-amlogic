#!/bin/bash
# Script para verificar suporte IR na TV Box S905X
# Usage: bash scripts/check_ir_support.sh

echo "=== Verificando Suporte IR na TV Box S905X ==="
echo

echo "1. Verificando Driver Meson IR..."
if [ -e /sys/class/rc/rc0 ]; then
    echo "✅ Driver IR carregado"
    echo "   Device: $(cat /sys/class/rc/rc0/device/uevent 2>/dev/null | grep DRIVER || echo "meson-ir")"
    echo "   Name: $(cat /sys/class/rc/rc0/input*/name 2>/dev/null || echo "IR Receiver")"
else
    echo "❌ Driver IR não encontrado em /sys/class/rc/rc0"
    echo "   Possíveis causas:"
    echo "   - Driver não carregado: execute 'modprobe meson-ir'"
    echo "   - Device Tree não configurado corretamente"
    echo "   - Hardware IR defeituoso ou não presente"
fi

echo
echo "2. Verificando Protocolos Suportados..."
if [ -e /sys/class/rc/rc0/protocols ]; then
    PROTOCOLS=$(cat /sys/class/rc/rc0/protocols)
    echo "Protocolos disponíveis:"
    echo "   $PROTOCOLS"
    
    if echo "$PROTOCOLS" | grep -q "nec"; then
        echo "   ✅ Protocolo NEC suportado (usado por controles TCL)"
    else
        echo "   ⚠️ Protocolo NEC não habilitado"
        echo "   Execute: echo '+nec' > /sys/class/rc/rc0/protocols"
    fi
else
    echo "❌ Arquivo de protocolos não encontrado"
fi

echo
echo "3. Verificando Keymap Atual..."
if [ -e /sys/class/rc/rc0/protocols ]; then
    CURRENT_MAP=$(cat /sys/devices/platform/*/rc/rc0/uevent 2>/dev/null | grep NAME | cut -d= -f2)
    if [ -n "$CURRENT_MAP" ]; then
        echo "Keymap atual: $CURRENT_MAP"
    else
        echo "Keymap: Não identificado"
    fi
else
    echo "⚠️ Não foi possível verificar o keymap"
fi

echo
echo "4. Verificando Device Tree IR..."
DT_PATHS=(
    "/sys/firmware/devicetree/base/ir@c8100000/status"
    "/sys/firmware/devicetree/base/soc/ir@c8100000/status"
    "/sys/firmware/devicetree/base/soc/cbus@c1100000/ir@8000/status"
)

IR_FOUND=0
for DT_PATH in "${DT_PATHS[@]}"; do
    if [ -e "$DT_PATH" ]; then
        STATUS=$(cat "$DT_PATH" 2>/dev/null)
        echo "✅ Device Tree IR encontrado"
        echo "   Path: $DT_PATH"
        echo "   Status: $STATUS"
        IR_FOUND=1
        break
    fi
done

if [ $IR_FOUND -eq 0 ]; then
    echo "⚠️ Device Tree IR não encontrado nos caminhos padrão"
    echo "   Verifique manualmente: find /sys/firmware/devicetree -name 'ir@*'"
fi

echo
echo "5. Verificando Input Devices..."
if [ -d /dev/input ]; then
    echo "Dispositivos de entrada disponíveis:"
    for dev in /dev/input/event*; do
        if [ -e "$dev" ]; then
            NAME=$(cat /sys/class/input/$(basename $dev | sed 's/event/input/')/name 2>/dev/null)
            if echo "$NAME" | grep -qi "ir\|remote\|rc"; then
                echo "   ✅ $dev - $NAME"
            fi
        fi
    done
else
    echo "❌ Diretório /dev/input não encontrado"
fi

echo
echo "6. Verificando Ferramentas de Teste..."
if command -v ir-keytable &> /dev/null; then
    echo "✅ ir-keytable instalado: $(which ir-keytable)"
elif [ -e /system/bin/ir-keytable ]; then
    echo "✅ ir-keytable instalado: /system/bin/ir-keytable"
else
    echo "⚠️ ir-keytable não instalado"
    echo "   Instale para testes avançados: apt-get install ir-keytable"
fi

if command -v evtest &> /dev/null; then
    echo "✅ evtest instalado: $(which evtest)"
elif [ -e /system/bin/evtest ]; then
    echo "✅ evtest instalado: /system/bin/evtest"
else
    echo "⚠️ evtest não instalado"
    echo "   Instale para testes: apt-get install evtest"
fi

echo
echo "7. Verificando Módulos do Kernel..."
if command -v lsmod &> /dev/null; then
    echo "Módulos RC carregados:"
    lsmod | grep -E "rc_|ir_|meson" || echo "   Nenhum módulo RC detectado com lsmod"
else
    if [ -d /sys/module ]; then
        echo "Módulos RC detectados em /sys/module:"
        ls /sys/module | grep -E "rc_|ir_|meson" || echo "   Nenhum módulo RC detectado"
    fi
fi

echo
echo "8. Verificando Keymaps Disponíveis..."
KEYMAP_PATHS=(
    "/lib/modules/$(uname -r)/kernel/drivers/media/rc/keymaps"
    "/system/lib/modules/drivers/media/rc/keymaps"
    "/lib/udev/rc_keymaps"
)

KEYMAPS_FOUND=0
for KEYMAP_PATH in "${KEYMAP_PATHS[@]}"; do
    if [ -d "$KEYMAP_PATH" ]; then
        echo "Keymaps em: $KEYMAP_PATH"
        if ls "$KEYMAP_PATH"/*tcl* 2>/dev/null | grep -q .; then
            echo "   ✅ Keymap TCL encontrado:"
            ls "$KEYMAP_PATH"/*tcl* 2>/dev/null | sed 's/^/      /'
            KEYMAPS_FOUND=1
        else
            echo "   ⚠️ Keymap TCL não encontrado neste diretório"
        fi
    fi
done

if [ $KEYMAPS_FOUND -eq 0 ]; then
    echo "   ⚠️ Keymap TCL não encontrado em nenhum diretório padrão"
    echo "   Compile o kernel com CONFIG_RC_MAP=m e inclua rc-tcl-tv"
fi

echo
echo "=== Resumo da Verificação ==="
echo

# Fazer resumo final
ERRORS=0
WARNINGS=0

if [ ! -e /sys/class/rc/rc0 ]; then
    echo "❌ Driver IR não detectado"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Driver IR presente"
fi

if [ -e /sys/class/rc/rc0/protocols ] && cat /sys/class/rc/rc0/protocols | grep -q "nec"; then
    echo "✅ Protocolo NEC suportado"
else
    echo "⚠️ Protocolo NEC precisa ser habilitado"
    WARNINGS=$((WARNINGS + 1))
fi

if [ $KEYMAPS_FOUND -eq 1 ]; then
    echo "✅ Keymap TCL disponível"
else
    echo "⚠️ Keymap TCL precisa ser compilado"
    WARNINGS=$((WARNINGS + 1))
fi

echo
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 Sistema pronto para usar controle remoto TCL!"
    echo "   Execute 'bash scripts/test_tcl_remote.sh' para testar"
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️ Sistema parcialmente configurado ($WARNINGS avisos)"
    echo "   O controle pode funcionar, mas alguns ajustes podem ser necessários"
else
    echo "❌ Sistema não está pronto ($ERRORS erros, $WARNINGS avisos)"
    echo "   Corrija os problemas indicados acima"
fi

echo
echo "=== Fim da Verificação ==="
