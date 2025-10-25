#!/bin/bash
# Script para testar controle remoto TCL
# Usage: bash scripts/test_tcl_remote.sh

echo "=== Teste do Controle Remoto TCL ==="
echo
echo "Este script irá monitorar eventos do receptor IR."
echo "Pressione as teclas do seu controle remoto TCL para ver os códigos."
echo
echo "Use Ctrl+C para sair do teste."
echo

# Verificar se o driver IR está carregado
if [ ! -e /sys/class/rc/rc0 ]; then
    echo "❌ ERRO: Driver IR não encontrado!"
    echo
    echo "Possíveis soluções:"
    echo "1. Carregue o módulo: modprobe meson-ir"
    echo "2. Verifique o Device Tree"
    echo "3. Execute: bash scripts/check_ir_support.sh"
    exit 1
fi

echo "✅ Driver IR detectado"
echo

# Encontrar o dispositivo IR
IR_DEVICE=""
for dev in /dev/input/event*; do
    if [ -e "$dev" ]; then
        NAME=$(cat /sys/class/input/$(basename $dev | sed 's/event/input/')/name 2>/dev/null)
        if echo "$NAME" | grep -qi "ir\|remote\|rc\|meson"; then
            IR_DEVICE="$dev"
            echo "Dispositivo IR encontrado: $dev ($NAME)"
            break
        fi
    fi
done

if [ -z "$IR_DEVICE" ]; then
    echo "⚠️ Dispositivo IR específico não identificado"
    echo "Tentando com /dev/input/event2 (padrão)"
    IR_DEVICE="/dev/input/event2"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " INICIANDO TESTE - Pressione as teclas do controle TCL"
echo "═══════════════════════════════════════════════════════"
echo

# Escolher ferramenta de teste disponível
if command -v ir-keytable &> /dev/null; then
    echo "Usando ir-keytable para teste..."
    echo
    ir-keytable -t
    
elif command -v evtest &> /dev/null; then
    echo "Usando evtest para teste..."
    echo "Formato: tipo código valor"
    echo "  - Tipo 4 = Scancode (código do controle)"
    echo "  - Tipo 1 = Key event (tecla pressionada/solta)"
    echo
    evtest "$IR_DEVICE"
    
elif [ -e /system/bin/getevent ]; then
    echo "Usando getevent (Android) para teste..."
    echo
    /system/bin/getevent -l "$IR_DEVICE"
    
else
    # Método alternativo usando dmesg
    echo "Usando dmesg para monitorar eventos IR..."
    echo "NOTA: Este método pode ter delay e não mostrar todos os eventos"
    echo
    
    # Habilitar logging detalhado
    echo 8 > /proc/sys/kernel/printk 2>/dev/null
    
    # Monitorar dmesg
    dmesg -C
    dmesg -w | grep --line-buffered -E "rc|ir|key|event" | while read line; do
        if echo "$line" | grep -qi "scancode\|key.*down\|key.*up"; then
            echo "$line"
        fi
    done
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " FIM DO TESTE"
echo "═══════════════════════════════════════════════════════"
echo

# Informações adicionais
echo
echo "📝 Anote os scancodes das teclas importantes:"
echo "   - Power: 0x____"
echo "   - OK/Enter: 0x____"
echo "   - Setas (Cima/Baixo/Esquerda/Direita): 0x____ / 0x____ / 0x____ / 0x____"
echo "   - Volume +/-: 0x____ / 0x____"
echo "   - Números 0-9: 0x____ até 0x____"
echo
echo "Se os códigos forem diferentes dos padrões (0x04xx ou 0x14xx),"
echo "você precisará criar um keymap customizado."
echo
echo "Para criar um keymap customizado, edite:"
echo "  drivers/media/rc/keymaps/rc-tcl-tv.c"
echo
echo "Ou use ir-keytable para criar um arquivo .toml:"
echo "  ir-keytable -t > /tmp/tcl_codes.txt"
echo "  # Edite e converta para formato .toml"
echo
