#!/bin/sh

# Configurações do PostgreSQL
DB_HOST="localhost"
DB_USER="postgres"  # Use um superusuário (como postgres) para pg_dumpall
DB_PASS="sua_senha_postgres"  # Senha do usuário postgres
DB_PORT="5432"

# Configurações do servidor novo
NEW_SERVER_IP="82.29.59.86"
NEW_SERVER_USER="root"
NEW_SERVER_DIR="/tmp"

# Nome do arquivo de backup
BACKUP_FILE="postgres_full_backup_$(date +%Y%m%d_%H%M%S).sql"

# Criar o backup completo do cluster PostgreSQL
echo "Iniciando backup completo do cluster PostgreSQL..."
PGPASSWORD=$DB_PASS pg_dumpall -h $DB_HOST -U $DB_USER -p $DB_PORT -f $BACKUP_FILE

# Verificar se o backup foi bem-sucedido
if [ $? -eq 0 ]; then
    echo "Backup completo do cluster PostgreSQL concluído com sucesso."
else
    echo "Erro ao fazer o backup do cluster PostgreSQL."
    exit 1
fi

# Compactar o backup
echo "Compactando o backup..."
tar -czvf $BACKUP_FILE.tar.gz $BACKUP_FILE

# Transferir o backup para o novo servidor (usando scp com senha manual)
echo "Iniciando transferência do backup para o novo servidor..."
scp $BACKUP_FILE.tar.gz $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_DIR

# Verificar se a transferência foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Backup transferido com sucesso para o novo servidor."
else
    echo "Erro ao transferir o backup. Verifique a conexão e tente novamente."
    exit 1
fi

# Limpar arquivos temporários
rm $BACKUP_FILE $BACKUP_FILE.tar.gz

echo "Processo de backup e transferência concluído."