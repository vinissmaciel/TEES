# Use a imagem oficial do pgvector
FROM pgvector/pgvector:pg17

# Variáveis de ambiente para o PostgreSQL
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=qualquer_uma
ENV POSTGRES_DB=BD_NIV2
ENV POSTGRES_HOST_AUTH_METHOD=trust


# Copie o arquivo de dump, o script de preparação e o script de inicialização para o container
COPY init_db.sh /docker-entrypoint-initdb.d/init_db.sh

# Concede permissão de execução ao script de inicialização
RUN chmod +x /docker-entrypoint-initdb.d/init_db.sh

# Expõe a porta 5437
EXPOSE 5437

