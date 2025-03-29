#!/bin/sh

# Função para exibir mensagens formatadas
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Solicitar informações do servidor antigo
read -p "Informe o IP do servidor antigo: " OLD_SERVER_IP
read -p "Informe o usuário do servidor antigo: " OLD_SERVER_USER
read -p "Informe a senha do servidor antigo: " -s OLD_SERVER_PWD
echo
read -p "Informe o caminho da pasta public no servidor antigo (ex: /home/deploy/gdschat/backend/public): " OLD_PUBLIC_DIR

# Solicitar informações do servidor novo
read -p "Informe o caminho para salvar os backups no servidor novo (ex: /backups): " NEW_BACKUP_DIR
read -p "Informe o nome da instância no servidor novo (ex: empresa): " INSTANCE_NAME
read -p "Informe o caminho base da pasta public no servidor novo (ex: /home/deploy): " NEW_BASE_DIR

# Definir caminho completo da pasta public no servidor novo
NEW_PUBLIC_DIR="$NEW_BASE_DIR/$INSTANCE_NAME/backend/public"

# Verificar se o diretório de backup no servidor novo existe
mkdir -p "$NEW_BACKUP_DIR"
if [ $? -ne 0 ]; then
    log "Erro ao criar o diretório de backup no servidor novo."
    exit 1
fi

# Nome dos arquivos de backup
BACKUP_DB="postgres_backup_$(date +'%Y%m%d_%H%M%S').sql"
BACKUP_DB_TAR="$BACKUP_DB.tar.gz"
BACKUP_PUBLIC="public_backup_$(date +'%Y%m%d_%H%M%S').tar.gz"

# Passo 1: Fazer backup do cluster PostgreSQL no servidor antigo e compactar
log "Conectando ao servidor antigo para fazer o backup do PostgreSQL..."
ssh $OLD_SERVER_USER@$OLD_SERVER_IP "pg_dumpall -U postgres -f /tmp/$BACKUP_DB && tar -czvf /tmp/$BACKUP_DB_TAR -C /tmp $BACKUP_DB && rm /tmp/$BACKUP_DB"
if [ $? -eq 0 ]; then
    log "Backup do PostgreSQL concluído e compactado com sucesso."
else
    log "Erro ao fazer o backup do PostgreSQL."
    exit 1
fi

# Passo 2: Fazer backup da pasta public no servidor antigo
log "Conectando ao servidor antigo para fazer o backup da pasta public..."
ssh $OLD_SERVER_USER@$OLD_SERVER_IP "tar -czvf /tmp/$BACKUP_PUBLIC -C $(dirname $OLD_PUBLIC_DIR) $(basename $OLD_PUBLIC_DIR)"
if [ $? -eq 0 ]; then
    log "Backup da pasta public concluído com sucesso."
else
    log "Erro ao fazer o backup da pasta public."
    exit 1
fi

# Passo 3: Transferir os backups para o servidor novo
log "Transferindo os backups para o servidor novo..."
scp $OLD_SERVER_USER@$OLD_SERVER_IP:/tmp/$BACKUP_DB_TAR "$NEW_BACKUP_DIR/"
scp $OLD_SERVER_USER@$OLD_SERVER_IP:/tmp/$BACKUP_PUBLIC "$NEW_BACKUP_DIR/"
if [ $? -eq 0 ]; then
    log "Transferência dos backups concluída com sucesso."
else
    log "Erro ao transferir os backups."
    exit 1
fi

# Passo 4: Descompactar e restaurar o cluster PostgreSQL no servidor novo
log "Descompactando e restaurando o cluster PostgreSQL no servidor novo..."
tar -xzvf "$NEW_BACKUP_DIR/$BACKUP_DB_TAR" -C "$NEW_BACKUP_DIR"
sudo -u postgres psql -f "$NEW_BACKUP_DIR/$BACKUP_DB"
if [ $? -eq 0 ]; then
    log "Restauração do PostgreSQL concluída com sucesso."
else
    log "Erro ao restaurar o PostgreSQL."
    exit 1
fi

# Passo 5: Descompactar e restaurar a pasta public no servidor novo
log "Descompactando e restaurando a pasta public no servidor novo..."
mkdir -p "$NEW_PUBLIC_DIR"
tar -xzvf "$NEW_BACKUP_DIR/$BACKUP_PUBLIC" -C "$NEW_PUBLIC_DIR" --strip-components=1
if [ $? -eq 0 ]; then
    log "Restauração da pasta public concluída com sucesso."
else
    log "Erro ao restaurar a pasta public."
    exit 1
fi

# Passo 6: Limpar backups temporários no servidor antigo
log "Limpando backups temporários no servidor antigo..."
ssh $OLD_SERVER_USER@$OLD_SERVER_IP "rm /tmp/$BACKUP_DB_TAR /tmp/$BACKUP_PUBLIC"
if [ $? -eq 0 ]; then
    log "Limpeza dos backups temporários concluída com sucesso."
else
    log "Erro ao limpar os backups temporários."
fi

log "Migração concluída com sucesso!"