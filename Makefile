.PHONY: up
up:
	ansible-playbook -i inventory.ini playbook.yml

.PHONY: up-with-clean-etcd
up-with-clean-etcd:
	ansible-playbook -i inventory.ini playbook.yml -e "clean_etcd=true"

.PHONY: haproxy
haproxy:
	ansible-playbook -i inventory.ini haproxy.yml

.PHONY: pg-observe
pg-observe:
	ansible-playbook -i inventory.ini pg_observe.yml

.PHONY: prometheus-grafana
prometheus-grafana:
	ansible-playbook -i inventory.ini prometheus_grafana.yml
