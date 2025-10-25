#!/bin/bash
# Script para aplicar keymap TCL no sistema
# Usage: bash scripts/apply_tcl_keymap.sh

echo "=== Aplicando Keymap TCL para Controle Remoto ==="
echo

# Verificar se o driver IR está carregado
if [ ! -e /sys/class/rc/rc0 ]; then
    echo "❌ ERRO: Driver IR não encontrado!"
    echo
    echo "Carregando módulo meson-ir..."
    if command -v modprobe &> /dev/null; then
        modprobe meson-ir 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Módulo meson-ir carregado"
        else
            echo "❌ Falha ao carregar meson-ir"
            echo "   Verifique se o módulo existe e se você tem permissões root"
            exit 1
        fi
    else
        echo "❌ modprobe não disponível"
        exit 1
    fi
fi

echo "✅ Driver IR presente"
echo

# Verificar e habilitar protocolo NEC
if [ -e /sys/class/rc/rc0/protocols ]; then
    CURRENT_PROTOCOLS=$(cat /sys/class/rc/rc0/protocols)
    echo "Protocolos atuais: $CURRENT_PROTOCOLS"
    
    if ! echo "$CURRENT_PROTOCOLS" | grep -q "\[nec\]"; then
        echo "Habilitando protocolo NEC..."
        echo "+nec" > /sys/class/rc/rc0/protocols 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Protocolo NEC habilitado"
        else
            echo "⚠️ Não foi possível habilitar protocolo NEC"
            echo "   Pode ser necessário acesso root"
        fi
    else
        echo "✅ Protocolo NEC já está habilitado"
    fi
else
    echo "⚠️ Não foi possível verificar protocolos"
fi

echo

# Tentar carregar módulo keymap TCL
echo "Carregando módulo keymap rc-tcl-tv..."

# Tentar diferentes métodos de carregamento
MODULE_LOADED=0

# Método 1: modprobe
if command -v modprobe &> /dev/null; then
    modprobe rc-tcl-tv 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Módulo rc-tcl-tv carregado via modprobe"
        MODULE_LOADED=1
    fi
fi

# Método 2: insmod
if [ $MODULE_LOADED -eq 0 ]; then
    # Procurar pelo módulo
    MODULE_PATHS=(
        "/lib/modules/$(uname -r)/kernel/drivers/media/rc/keymaps/rc-tcl-tv.ko"
        "/system/lib/modules/rc-tcl-tv.ko"
        "$(pwd)/drivers/media/rc/keymaps/rc-tcl-tv.ko"
    )
    
    for MODULE_PATH in "${MODULE_PATHS[@]}"; do
        if [ -e "$MODULE_PATH" ]; then
            echo "Encontrado em: $MODULE_PATH"
            insmod "$MODULE_PATH" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "✅ Módulo rc-tcl-tv carregado via insmod"
                MODULE_LOADED=1
                break
            fi
        fi
    done
fi

if [ $MODULE_LOADED -eq 0 ]; then
    echo "⚠️ Módulo rc-tcl-tv não encontrado ou não pode ser carregado"
    echo "   Compile o kernel com: make modules"
    echo "   Ou instale o módulo em /lib/modules/"
fi

echo

# Aplicar keymap usando ir-keytable se disponível
if command -v ir-keytable &> /dev/null; then
    echo "Aplicando keymap TCL via ir-keytable..."
    
    # Tentar aplicar keymap pelo nome
    ir-keytable -c -s rc0 -w /lib/udev/rc_keymaps/tcl_tv.toml 2>/dev/null
    
    if [ $? -ne 0 ]; then
        # Se falhar, tentar método alternativo
        echo "Configurando para protocolo NEC genérico..."
        ir-keytable -c -p nec -s rc0 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ Configurado para NEC (os códigos TCL devem funcionar)"
        else
            echo "⚠️ Falha ao configurar via ir-keytable"
        fi
    else
        echo "✅ Keymap TCL aplicado com sucesso!"
    fi
else
    echo "⚠️ ir-keytable não disponível"
    echo "   O keymap será aplicado automaticamente se o módulo estiver carregado"
    echo "   Ou configure via Device Tree: linux,rc-map-name = \"rc-tcl-tv\";"
fi

echo

# Verificar configuração final
echo "=== Verificação Final ==="
echo

if [ -e /sys/class/rc/rc0/protocols ]; then
    echo "Protocolos ativos:"
    cat /sys/class/rc/rc0/protocols | tr ' ' '\n' | grep '\[' | tr -d '[]' | sed 's/^/   /'
fi

if command -v lsmod &> /dev/null; then
    if lsmod | grep -q "rc_tcl_tv\|tcl"; then
        echo "✅ Módulo TCL carregado:"
        lsmod | grep -E "rc_tcl|tcl" | sed 's/^/   /'
    fi
fi

echo
echo "=== Configuração Concluída ==="
echo
echo "📝 Próximos passos:"
echo "   1. Teste o controle: bash scripts/test_tcl_remote.sh"
echo "   2. Verifique se as teclas funcionam corretamente"
echo "   3. Se necessário, customize os códigos em rc-tcl-tv.c"
echo
echo "Para tornar a configuração permanente:"
echo "   1. Configure o Device Tree com: linux,rc-map-name = \"rc-tcl-tv\";"
echo "   2. Ou adicione modprobe rc-tcl-tv em /etc/modules"
echo "   3. Ou crie script de init em /system/etc/init.d/"
echo
