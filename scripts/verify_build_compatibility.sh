#!/bin/bash
#
# Script de Verificação de Compatibilidade Build_32.yml vs Custom ROM
# Verifica se o kernel compilado é compatível com as configurações da custom ROM
# em .github/workflows/level2 e level3
#

# Don't exit on error, we want to show all issues
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Verificação de Compatibilidade Build 32-bit${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Contador de problemas
CRITICAL_ISSUES=0
WARNING_ISSUES=0
INFO_ISSUES=0

# 1. Verificar UIMAGE_LOADADDR
echo -e "${BLUE}[1] Verificando UIMAGE_LOADADDR...${NC}"
EXPECTED_LOADADDR="0x1080000"
CURRENT_LOADADDR=$(grep "UIMAGE_LOADADDR=" scripts/amlogic/mkimage_32.sh | head -1 | cut -d'=' -f2)

if [ "$CURRENT_LOADADDR" = "$EXPECTED_LOADADDR" ]; then
    echo -e "${GREEN}✓ UIMAGE_LOADADDR correto: ${CURRENT_LOADADDR}${NC}"
else
    echo -e "${RED}✗ UIMAGE_LOADADDR INCORRETO!${NC}"
    echo -e "  Atual: ${CURRENT_LOADADDR}"
    echo -e "  Esperado: ${EXPECTED_LOADADDR}"
    echo -e "  Custom ROM base: 0x01078000, offset: 0x00008000"
    echo -e "  ${YELLOW}CRÍTICO: O kernel não vai bootar com este endereço!${NC}"
    ((CRITICAL_ISSUES++))
fi
echo ""

# 2. Verificar SELinux
echo -e "${BLUE}[2] Verificando suporte a SELinux...${NC}"
if grep -q "CONFIG_SECURITY_SELINUX=y" .configatv 2>/dev/null; then
    echo -e "${GREEN}✓ SELinux habilitado no kernel${NC}"
    if grep -q "CONFIG_AUDIT=y" .configatv 2>/dev/null; then
        echo -e "${GREEN}✓ Audit habilitado (necessário para Android)${NC}"
    else
        echo -e "${YELLOW}⚠ Audit não habilitado${NC}"
        ((WARNING_ISSUES++))
    fi
else
    echo -e "${RED}✗ SELinux NÃO habilitado!${NC}"
    echo -e "  ${YELLOW}AVISO: Android 9 Pie requer SELinux${NC}"
    ((WARNING_ISSUES++))
fi
echo ""

# 3. Verificar Device Trees
echo -e "${BLUE}[3] Verificando Device Trees...${NC}"
REQUIRED_DTS=(
    "arch/arm/boot/dts/amlogic/gxl_p212_2g.dts"
    "arch/arm/boot/dts/amlogic/gxl_p212_1g.dts"
)

for dts in "${REQUIRED_DTS[@]}"; do
    if [ -f "$dts" ]; then
        echo -e "${GREEN}✓ Encontrado: $(basename $dts)${NC}"
    else
        echo -e "${YELLOW}⚠ Não encontrado: $(basename $dts)${NC}"
        ((WARNING_ISSUES++))
    fi
done
echo ""

# 4. Verificar LOCALVERSION
echo -e "${BLUE}[4] Verificando LOCALVERSION...${NC}"
if grep -q "CONFIG_LOCALVERSION=" .configatv 2>/dev/null; then
    LOCAL_VERSION=$(grep "CONFIG_LOCALVERSION=" .configatv | cut -d'"' -f2)
    if [ -z "$LOCAL_VERSION" ]; then
        echo -e "${YELLOW}⚠ LOCALVERSION vazio (será definido pelo workflow)${NC}"
        echo -e "  Workflow define: -s905x-arm32"
        ((INFO_ISSUES++))
    else
        echo -e "${GREEN}✓ LOCALVERSION: ${LOCAL_VERSION}${NC}"
    fi
else
    echo -e "${YELLOW}⚠ CONFIG_LOCALVERSION não encontrado${NC}"
    ((INFO_ISSUES++))
fi
echo ""

# 5. Verificar arquivos da Custom ROM
echo -e "${BLUE}[5] Verificando arquivos da Custom ROM...${NC}"

# Level3 - Boot parameters
if [ -f ".github/workflows/level3/boot/boot.PARTITION-base" ]; then
    BOOT_BASE=$(cat .github/workflows/level3/boot/boot.PARTITION-base)
    KERNEL_OFFSET=$(cat .github/workflows/level3/boot/boot.PARTITION-kernel_offset)
    EXPECTED_LOAD=$(printf "0x%x" $((BOOT_BASE + KERNEL_OFFSET)))
    
    echo -e "${GREEN}✓ Boot parameters encontrados:${NC}"
    echo -e "  Base: ${BOOT_BASE}"
    echo -e "  Kernel Offset: ${KERNEL_OFFSET}"
    echo -e "  Load Address calculado: ${EXPECTED_LOAD}"
else
    echo -e "${YELLOW}⚠ Arquivos level3/boot não encontrados${NC}"
    ((WARNING_ISSUES++))
fi

# Level2 - Partition sizes
if [ -f ".github/workflows/level2/vendor_size" ]; then
    VENDOR_SIZE=$(cat .github/workflows/level2/vendor_size)
    VENDOR_SIZE_MB=$((VENDOR_SIZE / 1024 / 1024))
    echo -e "${GREEN}✓ Partição vendor: ${VENDOR_SIZE_MB} MB${NC}"
    
    if [ "$VENDOR_SIZE_MB" -eq 512 ]; then
        echo -e "${GREEN}✓ Tamanho da partição vendor está correto (512 MB)${NC}"
    else
        echo -e "${RED}✗ Tamanho da partição vendor incorreto!${NC}"
        echo -e "  Esperado: 512 MB, Atual: ${VENDOR_SIZE_MB} MB"
        ((CRITICAL_ISSUES++))
    fi
else
    echo -e "${YELLOW}⚠ Arquivos level2 não encontrados${NC}"
    ((INFO_ISSUES++))
fi
echo ""

# 6. Verificar configuração do workflow
echo -e "${BLUE}[6] Verificando build_32.yml...${NC}"
if [ -f ".github/workflows/build_32.yml" ]; then
    echo -e "${GREEN}✓ Workflow build_32.yml encontrado${NC}"
    
    # Verificar se usa .configatv
    if grep -q ".configatv" .github/workflows/build_32.yml; then
        echo -e "${GREEN}✓ Usa .configatv como base${NC}"
    else
        echo -e "${YELLOW}⚠ Não usa .configatv${NC}"
        ((INFO_ISSUES++))
    fi
    
    # Verificar se compila zImage
    if grep -q "zImage" .github/workflows/build_32.yml; then
        echo -e "${GREEN}✓ Compila zImage${NC}"
    else
        echo -e "${RED}✗ Não compila zImage!${NC}"
        ((CRITICAL_ISSUES++))
    fi
    
    # Verificar se compila DTBs
    if grep -q "dtbs" .github/workflows/build_32.yml; then
        echo -e "${GREEN}✓ Compila DTBs${NC}"
    else
        echo -e "${YELLOW}⚠ Não compila DTBs${NC}"
        ((WARNING_ISSUES++))
    fi
    
    # Verificar se compila módulos
    if grep -q "modules" .github/workflows/build_32.yml; then
        echo -e "${GREEN}✓ Compila módulos${NC}"
    else
        echo -e "${YELLOW}⚠ Não compila módulos${NC}"
        ((WARNING_ISSUES++))
    fi
else
    echo -e "${RED}✗ Workflow build_32.yml não encontrado!${NC}"
    ((CRITICAL_ISSUES++))
fi
echo ""

# 7. Verificar ferramentas necessárias
echo -e "${BLUE}[7] Verificando ferramentas de build...${NC}"
TOOLS=(
    "make:GNU Make"
    "dtc:Device Tree Compiler"
)

for tool_entry in "${TOOLS[@]}"; do
    tool="${tool_entry%%:*}"
    name="${tool_entry##*:}"
    if command -v "$tool" &> /dev/null; then
        version=$($tool --version 2>&1 | head -1 || echo "unknown")
        echo -e "${GREEN}✓ $name: $version${NC}"
    else
        echo -e "${YELLOW}⚠ $name não instalado${NC}"
        ((INFO_ISSUES++))
    fi
done
echo ""

# Resumo final
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}RESUMO DA VERIFICAÇÃO${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

if [ $CRITICAL_ISSUES -eq 0 ] && [ $WARNING_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ TUDO OK! Build compatível com a custom ROM${NC}"
    exit 0
elif [ $CRITICAL_ISSUES -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNING_ISSUES} aviso(s) encontrado(s)${NC}"
    echo -e "${YELLOW}  Build pode funcionar, mas verifique os avisos${NC}"
    exit 0
else
    echo -e "${RED}✗ ${CRITICAL_ISSUES} problema(s) crítico(s) encontrado(s)!${NC}"
    [ $WARNING_ISSUES -gt 0 ] && echo -e "${YELLOW}⚠ ${WARNING_ISSUES} aviso(s) adicional(is)${NC}"
    echo -e "${RED}  BUILD NÃO É COMPATÍVEL - Corrija os problemas críticos${NC}"
    echo ""
    echo -e "${BLUE}Consulte ANALISE_COMPATIBILIDADE_BUILD32.md para mais detalhes${NC}"
    exit 1
fi
