# Projeto 01 - DevOps com Vagrant e Ansible

## 📋 Descrição

Este projeto implementa uma infraestrutura completa de DevOps utilizando **Vagrant** para orquestração de máquinas virtuais e **Ansible** para configuração automatizada. A solução provisiona um ambiente com múltiplos servidores especializados em diferentes funções.

## 👥 Integrantes da Equipe

- **Jesse** (Primeiro Integrante)
- **João** (Segundo Integrante)

**Disciplina:** Administração de Sistemas Abertos  
**Professor:** Leonidas Lima  
**Período:** 2026.1  
**Campus:** João Pessoa - IFPB

---

## 🏗️ Arquitetura da Infraestrutura

### Máquinas Virtuais

| Máquina | Hostname | IP Privado | Memória | Função |
|---------|----------|-----------|---------|--------|
| **arq** | arq.jesse.joao.devops | 192.168.56.109 | 512 MB | Servidor de Arquivos, DHCP, DNS |
| **db** | db.jesse.joao.devops | 192.168.56.134* | 512 MB | Banco de Dados (MariaDB) |
| **app** | app.jesse.joao.devops | 192.168.56.194* | 512 MB | Servidor Web (Apache2) |
| **cli** | cli.jesse.joao.devops | DHCP | 1024 MB | Host Cliente |

*IP atribuído via DHCP do servidor arq

---

## 📦 Componentes Principais

### 1. Servidor de Arquivos (arq)

**Responsabilidades:**
- ✅ LVM e Formatação ext4
- ✅ Servidor NFS
- ✅ Servidor DHCP (isc-dhcp-server)
- ✅ Servidor DNS (Bind9)

**Configurações:**
- Volume Group: `dados` (3 discos de 10 GB)
- Logical Volume: `ifpb` (15 GB)
- Montagem: `/dados`
- Exportação NFS: `/dados/nfs`
- DHCP Range: 192.168.56.50 - 192.168.56.100
- Lease Time: 180 segundos
- Max Lease Time: 3600 segundos
- DNS Domain: jesse.joao.devops
- Forwarders DNS: 1.1.1.1, 8.8.8.8

### 2. Servidor de Banco de Dados (db)

**Responsabilidades:**
- ✅ MariaDB Server
- ✅ Montagem automática de NFS via autofs
- ✅ Acesso a `/var/nfs`

**Configurações:**
- Banco de dados: MariaDB
- Montagem: `/var/nfs` (NFS do servidor arq)
- Autofs: Montagem automática

### 3. Servidor de Aplicação (app)

**Responsabilidades:**
- ✅ Apache2 Web Server
- ✅ Página HTML personalizada
- ✅ Montagem automática de NFS via autofs
- ✅ Charset UTF-8

**Configurações:**
- Servidor Web: Apache2
- Página padrão: `/var/www/html/index.html` com informações do projeto
- Montagem: `/var/nfs` (NFS do servidor arq)
- Charset: UTF-8

### 4. Host Cliente (cli)

**Responsabilidades:**
- ✅ Firefox ESR
- ✅ X11 Forwarding via SSH
- ✅ Montagem automática de NFS
- ✅ Acesso aos recursos compartilhados

**Configurações:**
- Navegador: Firefox ESR
- X11Forwarding: Habilitado
- Montagem: `/var/nfs` (NFS do servidor arq)

---

## 🚀 Como Usar

### Pré-requisitos

- Vagrant instalado
- VirtualBox instalado
- Ansible instalado
- Debian Bookworm64 box para Vagrant

### Inicializar a Infraestrutura

```bash
# Criar diretório do projeto
mkdir leonidas-devops
cd leonidas-devops

# Inicializar Vagrant
vagrant init -m debian/bookworm64

# Copiar Vagrantfile, ansible.cfg, hosts.ini e playbooks

# Iniciar máquinas virtuais
vagrant up

# Verificar status
vagrant status
```

### Provisionar com Ansible

```bash
# Provisionar servidor arq com LVM, NFS, DHCP e DNS
ansible-playbook -i hosts.ini playbooks/arq.yml

# Provisionar servidor db com MariaDB e NFS
ansible-playbook -i hosts.ini playbooks/db.yml

# Provisionar servidor app com Apache2 e NFS
ansible-playbook -i hosts.ini playbooks/app.yml

# Provisionar cliente com Firefox e X11 Forwarding
ansible-playbook -i hosts.ini playbooks/cli.yml

# Provisionar configurações comuns em todos os servidores
ansible-playbook -i hosts.ini playbooks/common.yml
```

### Acessar as Máquinas

```bash
# Acessar servidor arq
vagrant ssh arq

# Acessar servidor db
vagrant ssh db

# Acessar servidor app
vagrant ssh app

# Acessar cliente com X11 Forwarding
vagrant ssh cli -- -X
```

### Parar e Remover

```bash
# Parar máquinas virtuais
vagrant halt

# Remover máquinas virtuais completamente
vagrant destroy
```

---

## 📂 Estrutura de Arquivos

```
leonidas-devops/
├── Vagrantfile              # Configuração das VMs
├── ansible.cfg              # Configuração do Ansible
├── hosts.ini                # Inventário do Ansible
├── README.md                # Este arquivo
└── playbooks/
    ├── common.yml           # Configurações comuns
    ├── arq.yml              # Servidor de Arquivos
    ├── db.yml               # Banco de Dados
    ├── app.yml              # Servidor de Aplicação
    ├── cli.yml              # Host Cliente
    ├── dhcpd.conf           # Configuração DHCP
    ├── named.conf.options   # Configuração DNS (options)
    ├── named.conf.internal-zones  # Configuração DNS (zones)
    ├── jesse.joao.devops.db # Zona DNS direta
    └── 56.168.192.db        # Zona DNS reversa
```

---

## 🔧 Configurações Principais

### Rede Privada

- **Subnet:** 192.168.56.0/24
- **Gateway:** 192.168.56.1
- **DNS:** 192.168.56.109 (servidor arq)

### LVM (Logical Volume Manager)

```
Physical Volumes: /dev/sdb, /dev/sdc, /dev/sdd (10 GB cada)
Volume Group: dados
Logical Volume: ifpb (15 GB)
Filesystem: ext4
Mountpoint: /datos
```

### NFS (Network File System)

- **Servidor:** arq (192.168.56.109)
- **Exportação:** /dados/nfs
- **Clientes:** db, app, cli
- **Opções:** rw,sync,all_squash,anonuid=1001,anongid=1001
- **Usuário NFS:** nfs-ifpb (UID 1001)

### DHCP (Dynamic Host Configuration Protocol)

- **Servidor:** arq
- **Interface:** eth1
- **Range:** 192.168.56.50 - 192.168.56.100
- **Default Lease Time:** 180 segundos
- **Max Lease Time:** 3600 segundos
- **Domain Name:** jesse.joao.devops
- **Domain Servers:** 192.168.56.109

### DNS (Domain Name System)

- **Servidor:** arq (Bind9)
- **Zonas:**
  - `jesse.joao.devops` (direta)
  - `56.168.192.in-addr.arpa` (reversa)
- **Forwarders:** 1.1.1.1, 8.8.8.8
- **Recursão:** Habilitada
- **ACL:** Rede interna 192.168.56.0/24

### Segurança SSH

- **PermitRootLogin:** no
- **PasswordAuthentication:** no
- **AllowGroups:** vagrant, ifpb
- **X11Forwarding:** Habilitado (em cli)

### Grupos de Usuários

- **ifpb:** Grupo para usuários de integração
  - Membros: jesse, joao
  - Acesso: Sudo sem senha
  - Shell: /bin/bash

---

## ✅ Validação e Testes

### Testar Conectividade

```bash
# Do servidor cli
vagrant ssh cli

# Testar ping para arq
ping -c 4 arq.jesse.joao.devops

# Testar resolução DNS
dig arq.jesse.joao.devops
dig -x 192.168.56.109

# Testar NFS
ls -la /var/nfs

# Testar acesso a Apache
curl http://app.jesse.joao.devops
```

### Monitorar Serviços

```bash
# Verificar status DHCP
vagrant ssh arq
sudo systemctl status isc-dhcp-server

# Verificar status DNS
sudo systemctl status bind9

# Verificar status NFS
sudo systemctl status nfs-kernel-server

# Verificar logs
sudo journalctl -u bind9 -f
sudo journalctl -u isc-dhcp-server -f
```

---

## 📝 Notas Importantes

1. **Automatização Completa:** Toda a infraestrutura é provisionada automaticamente via Ansible
2. **Segurança:** SSH com autenticação por chaves, sem acesso root
3. **Resiliência:** NFS com autofs para montagem automática
4. **Escalabilidade:** Estrutura permite adicionar novos servidores facilmente
5. **Documentação:** Todos os playbooks estão bem comentados

---

## 🔗 Referências

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Bind9 Administrator Reference Manual](https://bind9.readthedocs.io/)
- [ISC DHCP Server](https://www.isc.org/dhcp/)
- [NFS Protocol](https://tools.ietf.org/html/rfc3530)

---

## 📄 Licença

Este projeto é desenvolvido para fins educacionais no Instituto Federal da Paraíba.

**Última atualização:** 13 de maio de 2026
