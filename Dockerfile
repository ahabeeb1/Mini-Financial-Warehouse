FROM postgres:15

ENV POSTGRES_DB=taxi_warehouse
ENV POSTGRES_USER=warehouse_user  
ENV POSTGRES_PASSWORD=warehouse_pass

COPY init-scripts/ /docker-entrypoint-initdb.d/

EXPOSE 5432
