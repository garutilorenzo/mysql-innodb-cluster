[![MySQL InnoDB Cluster CI](https://github.com/garutilorenzo/mysql-innodb-cluster/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/garutilorenzo/mysql-innodb-cluster/actions/workflows/ci.yml)
[![GitHub issues](https://img.shields.io/github/issues/garutilorenzo/mysql-innodb-cluster)](https://github.com/garutilorenzo/mysql-innodb-cluster/issues)
![GitHub](https://img.shields.io/github/license/garutilorenzo/mysql-innodb-cluster)
[![GitHub forks](https://img.shields.io/github/forks/garutilorenzo/mysql-innodb-cluster)](https://github.com/garutilorenzo/mysql-innodb-cluster/network)
[![GitHub stars](https://img.shields.io/github/stars/garutilorenzo/mysql-innodb-cluster)](https://github.com/garutilorenzo/mysql-innodb-cluster/stargazers)
[![Docker Stars](https://img.shields.io/docker/stars/garutilorenzo/docker-swarm-ingress?style=flat-square)](https://hub.docker.com/r/garutilorenzo/docker-swarm-ingress) 
[![Docker Pulls](https://img.shields.io/docker/pulls/garutilorenzo/docker-swarm-ingress?style=flat-square)](https://hub.docker.com/r/garutilorenzo/docker-swarm-ingress)

![MySQL Logo](https://garutilorenzo.github.io/images/mysql.png?)

# MySQL InnoDB Cluster

MySQL InnoDB Cluster dockerized environment for testing purposes

* [MySQL InnoDB Cluster](https://dev.mysql.com/doc/refman/8.0/en/mysql-innodb-cluster-introduction.html) - MySQL InnoDB Cluster provides a complete high availability solution for MySQL
* [MySQL Router](https://dev.mysql.com/doc/mysql-router/8.0/en/) - MySQL Router is part of InnoDB Cluster, and is lightweight middleware that provides transparent routing between your application and back-end MySQL Servers


## Notes about environment

* The master branch is based on MySQL 8.0, the 5.7 branch is based on MySQL 5.7 
* MySQL InnoDB cluster is created on an existing group replication (see mysql/docker-entrypoint.sh for datails)
* Unlike official MySQL docker image, user an database are created only on the first node and then propagated to other nodes. User an database are created after group repliation setup.
* MySQL router creates the cluster after all nodes are up (see mysqlrouter/docker-entrypoint.sh). The cluster is created only if cluster doesen't exist.

## Environment variables
* MySQL Server (mysql-innodb-cluster image)
  * MYSQL_ROOT_PASSWORD: MySQL root password
  * GROUP_NAME: uuid of the grpup replication
  * BOOTSTRAP: if value is set, MySQL InnoDB Cluster is bootstrapped
  * MYSQL_USER: mysql user (optional)
  * MYSQL_PASSWORD: mysql user password (optional)
  * MYSQL_DATABASE: mysql database (optional)
* MySQL Router (mysql-innodb-cluster-router image)
  * MYSQL_ROOT_PASSWORD: mysql for the root user
  * MYSQL_HOST: mysql primary node
  * CLUSTERMEMBERS: number of members expected in cluster

## Spin up the cluster

Start the cluster:

```console
docker-compose up -d
```

See if everything works correctrly:

```console
docker-compose ps
docker-compose logs -f
```

Build your own image, or build from scratch (Optional):

```console
docker-compose build
```

## Play with the cluster

Show current cluster statu:

```console
docker-compose exec mysql_node01 bash
root@mysql_node01:/#  mysqlsh --js root@mysql_node01
Logger: Tried to log to an uninitialized logger.
Please provide the password for 'root@mysql_node01': ****
Save password for 'root@mysql_node01'? [Y]es/[N]o/Ne[v]er (default No): 
MySQL Shell 8.0.20

Copyright (c) 2016, 2020, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
Creating a session to 'root@mysql_node01'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 22
Server version: 5.7.32-log MySQL Community Server (GPL)
No default schema selected; type \use <schema> to set one.
MySQL  mysql_node01:3306 ssl  JS > <Cluster:testcluster>
MySQL  mysql_node01:3306 ssl  JS > clu.status()
{
    "clusterName": "testcluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "mysql_node01:3306", 
        "ssl": "DISABLED", 
        "status": "OK", 
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.", 
        "topology": {
            "mysql_node01:3306": {
                "address": "mysql_node01:3306", 
                "mode": "R/W", 
                "readReplicas": {}, 
                "role": "HA", 
                "status": "ONLINE"
            }, 
            "mysql_node02:3306": {
                "address": "mysql_node02:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "role": "HA", 
                "status": "ONLINE"
            }, 
            "mysql_node03:3306": {
                "address": "mysql_node03:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "role": "HA", 
                "status": "ONLINE"
            }
        }, 
        "topologyMode": "Single-Primary"
    }, 
    "groupInformationSourceMember": "mysql_node01:3306"
}
```

For advanced usage see the [docs](https://dev.mysql.com/doc/mysql-shell/8.0/en/mysql-innodb-cluster.html)

## Tear down

```console
docker-compose down -v
```
