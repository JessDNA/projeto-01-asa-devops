#!/bin/bash
# Script de Automação Completa - Projeto DevOps com Vagrant e Ansible
# Uso: ./run-all.sh

set -e  # Sair se algum comando falhar

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções
write_title() {
    echo -e "\n${CYAN}============================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}============================================================${NC}\n"
}

write_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

write_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

write_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar flags
DESTROY=false
SKIP_VAGRANT=false
SKIP_ANSIBLE=false
VERBOSE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--destroy) DESTROY=true; shift ;;
        --skip-vagrant) SKIP_VAGRANT=true; shift ;;
        --skip-ansible) SKIP_ANSIBLE=true; shift ;;
        -v|--verbose) VERBOSE="-v"; shift ;;
        *) echo "Opção desconhecida: $1"; exit 1 ;;
    esac
done

# Verificar pré-requisitos
write_title "VERIFICANDO PRÉ-REQUISITOS"

if command -v vagrant &> /dev/null; then
    VAGRANT_VERSION=$(vagrant --version)
    write_success "$VAGRANT_VERSION"
else
    write_error "Vagrant NÃO encontrado. Instale de: https://www.vagrantup.com"
    exit 1
fi

if command -v ansible-playbook &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    write_success "$ANSIBLE_VERSION"
else
    write_error "Ansible NÃO encontrado. Instale com: pip install ansible"
    exit 1
fi

# Verificar arquivos necessários
if [[ ! -f "Vagrantfile" ]]; then
    write_error "Vagrantfile não encontrado no diretório atual!"
    exit 1
fi

if [[ ! -f "hosts.ini" ]]; then
    write_error "hosts.ini não encontrado no diretório atual!"
    exit 1
fi

if [[ ! -d "playbooks" ]]; then
    write_error "Diretório 'playbooks' não encontrado!"
    exit 1
fi

write_success "Todos os arquivos necessários encontrados"

# Destruir VMs existentes (se flag -d)
if [ "$DESTROY" = true ]; then
    write_title "DESTRUINDO VMs EXISTENTES"
    write_warning "Destruindo todas as máquinas virtuais..."
    vagrant destroy -f
    write_success "VMs destruídas com sucesso"
fi

# Vagrant Up
if [ "$SKIP_VAGRANT" = false ]; then
    write_title "INICIANDO MÁQUINAS VIRTUAIS COM VAGRANT"
    echo -e "${YELLOW}Criando e iniciando 4 VMs (arq, db, app, cli)...${NC}"
    echo -e "${YELLOW}Isso pode levar 5-15 minutos...${NC}\n"
    
    vagrant up
    
    write_success "Vagrant up concluído!"
    
    # Aguardar VMs ficarem prontas
    write_title "AGUARDANDO MÁQUINAS FICAREM PRONTAS"
    echo -e "${YELLOW}Aguardando 30 segundos para VMs estabilizarem...${NC}"
    sleep 30
    write_success "VMs prontas"
fi

# Testar conectividade
write_title "TESTANDO CONECTIVIDADE ANSIBLE"
echo -e "${YELLOW}Testando conexão SSH com as máquinas...${NC}"

if ansible all -i hosts.ini -m ping $VERBOSE; then
    write_success "Conectividade testada com sucesso"
else
    write_warning "Alguns hosts podem estar indisponíveis ainda. Aguardando mais 30 segundos..."
    sleep 30
    ansible all -i hosts.ini -m ping $VERBOSE
fi

# Executar Playbooks Ansible
if [ "$SKIP_ANSIBLE" = false ]; then
    write_title "EXECUTANDO CONFIGURAÇÕES ANSIBLE"
    
    PLAYBOOKS=(
        "playbooks/common.yml"
        "playbooks/arq.yml"
        "playbooks/db.yml"
        "playbooks/app.yml"
        "playbooks/cli.yml"
    )
    
    COUNTER=1
    TOTAL=${#PLAYBOOKS[@]}
    
    for PLAYBOOK in "${PLAYBOOKS[@]}"; do
        write_title "EXECUTANDO PLAYBOOK [$COUNTER/$TOTAL]: $PLAYBOOK"
        
        if ansible-playbook -i hosts.ini "$PLAYBOOK" $VERBOSE; then
            write_success "$PLAYBOOK executado com sucesso!"
        else
            write_error "Erro ao executar $PLAYBOOK"
            exit 1
        fi
        
        ((COUNTER++))
    done
fi

# Resumo final
write_title "INFRAESTRUTURA PRONTA! ✓"

cat << "EOF"
┌─────────────────────────────────────────────────────┐
│  Seu ambiente DevOps foi configurado com sucesso!   │
└─────────────────────────────────────────────────────┘

📋 MÁQUINAS VIRTUAIS:
  • arq  (192.168.56.109)  - Servidor de Arquivos, DHCP, DNS
  • db   (192.168.56.134)  - Banco de Dados (MariaDB)
  • app  (192.168.56.194)  - Aplicação (Apache2)
  • cli  (DHCP)            - Host Cliente (Firefox)

🔧 PRÓXIMOS PASSOS:

1️⃣  Acessar uma VM:
    vagrant ssh arq
    vagrant ssh db
    vagrant ssh app
    vagrant ssh cli

2️⃣  Verificar status:
    vagrant status

3️⃣  Parar/Reiniciar:
    vagrant suspend        # Pausar
    vagrant resume         # Retomar
    vagrant reload         # Reiniciar
    vagrant destroy        # Destruir

4️⃣  Ver logs Ansible com verbose:
    ansible-playbook -i hosts.ini playbooks/arq.yml -v

ℹ️  ARQUIVO DE CONFIGURAÇÃO: ansible.cfg
   INVENTÁRIO: hosts.ini
   PLAYBOOKS: playbooks/

⏱️  Tempo total: ~25 minutos

EOF

write_success "Pronto para usar! 🚀"
