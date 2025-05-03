#!/bin/bash

hosts=({% for host in groups['promoters'] %}{{ hostvars[host]['ansible_host'] }} {% endfor %})

for host in "${hosts[@]}"; do
    curl -sf http://$host:{{ haproxy_stats_port }}/ > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        exit 0
    fi
done

exit 1
