.PHONY: init
init:
	@test -f inventory.ini || cp inventory.ini.example inventory.ini
	@test -f ansible.cfg || cp ansible.cfg.example ansible.cfg

.PHONY: up
up: init
	ansible-playbook -i inventory.ini playbook.yml

.PHONY: up-with-clean-etcd
up-with-clean-etcd: init
	ansible-playbook -i inventory.ini playbook.yml -e "clean_etcd=true"

.PHONY: prometheus-grafana
prometheus-grafana: init
	ansible-playbook -i inventory.ini prometheus_grafana.yml

.PHONY: haproxy.check.master
haproxy.check.master: init
	@PGPASSWORD=`grep postgresql_superuser_password group_vars/promoters.yml | awk '{print $$2}'` && \
	ANSIBLE_HOST='192.168.64.100' && \
	PGPASSWORD=$$PGPASSWORD psql -h 192.168.64.100 -p 5000 -U postgres -c "SELECT pg_is_in_recovery()" | grep -q 'f' && \
	echo "HAProxy master is OK" || echo "HAProxy master check failed"

.PHONY: haproxy.check.slave
haproxy.check.slave: init
	@PGPASSWORD=`grep postgresql_superuser_password group_vars/promoters.yml | awk '{print $$2}'` && \
	PGPASSWORD=$$PGPASSWORD psql -h 192.168.64.100 -p 5001 -U postgres -c "SELECT pg_is_in_recovery()" | grep -q 't' && \
	echo "HAProxy slave is OK" || echo "HAProxy slave check failed"

.PHONY: haproxy.check
haproxy.check: haproxy.check.master haproxy.check.slave

.PHONY: check-metrics.node-exporter
check-metrics.node-exporter: init
	@NODE_EXPORTER_PORT=9100 && \
	HOST=`grep patroni1 inventory.ini | awk '{print $$2}' | sed 's/ansible_host=//'` && \
	curl -sf http://$$HOST:$$NODE_EXPORTER_PORT/metrics | grep -q 'node_cpu_seconds_total' && \
	echo "Node exporter metrics collected successfully" || echo "Node exporter metrics check failed!"

.PHONY: check-metrics.postgres-exporter
check-metrics.postgres-exporter: init
	@POSTGRES_EXPORTER_PORT=9187 && \
	HOST=`grep patroni1 inventory.ini | awk '{print $$2}' | sed 's/ansible_host=//'` && \
	curl -sf http://$$HOST:$$POSTGRES_EXPORTER_PORT/metrics | grep -q 'pg_database_size' && \
	echo "Postgres exporter metrics collected successfully" || echo "Postgres exporter metrics check failed!"

.PHONY: check-metrics
check-metrics: check-metrics.node-exporter check-metrics.postgres-exporter

.PHONY: lint
lint:
	find . -name "*.yml" -exec ansible-lint {} \;
