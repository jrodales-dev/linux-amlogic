#!/bin/bash
#
# Verificação Rápida do Fix Aplicado
# Confirma que o UIMAGE_LOADADDR está correto no workflow
#

echo "============================================"
echo "Verificação do Fix UIMAGE_LOADADDR"
echo "============================================"
echo ""

EXPECTED="0x1080000"

# Verificar no workflow
echo "[1] Verificando .github/workflows/build_32.yml..."
if grep -q "UIMAGE_LOADADDR=0x1080000" .github/workflows/build_32.yml; then
    echo "✅ UIMAGE_LOADADDR correto no workflow: 0x1080000"
    echo ""
    echo "Contexto:"
    grep -B2 -A2 "UIMAGE_LOADADDR=0x1080000" .github/workflows/build_32.yml | head -10
    echo ""
    echo "✅ FIX APLICADO COM SUCESSO!"
    echo ""
    echo "O kernel agora será compilado com o endereço correto"
    echo "para ser compatível com a custom ROM Android 9 Pie."
    exit 0
else
    echo "❌ UIMAGE_LOADADDR ainda incorreto no workflow!"
    echo "Esperado: $EXPECTED"
    exit 1
fi
