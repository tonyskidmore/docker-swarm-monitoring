Docker Swarm Monitoring
=======================

### Introduction

This repository is a result of some learning and investigation I performed into some technologies that were mostly new to me, namely:

* [Docker Swarm mode](https://docs.docker.com/engine/swarm/)
* [Consul](https://www.consul.io/)
* [RabbitMQ](https://www.rabbitmq.com/)
* [HAProxy](http://www.haproxy.org/)
* [Prometheus](https://prometheus.io/)
* [Grafana](https://grafana.com/oss/grafana/)
* [Java Apps](https://www.java.com)

Primarily, I was interested in how Prometheus and Grafana worked in combination with each other.

The code in this project is meant to be deployed onto a Docker Swarm mode cluster that was previously deployed using [tonyskidmore/docker-swarm](https://github.com/tonyskidmore/docker-swarm).  Although that Docker swarm deployment here is hosted on a Windows 10 system running Vagrant and a few other requirements, the code in this repo can be deployed directly from a Linux system also.  Although not covered in detail here it was originally created and tested in a purely Linux environment.

In this lab style environment it is intended that each service is deployed to the Docker Swarm cluster as stacks by a series of separate [docker compose](https://docs.docker.com/compose/) files.  These are layered with the intention of taking a step at a time to review the different applications as they are deployed onto the cluster.  The series in which these are intended to be deployed are:

1. Consul
2. RabbitMQ
3. HAProxy
4. Java app
5. Prometheus and Grafana
6. Messaging publishing service
7. Messaging consumer service

Content published by [Ahmet Vehbi Olgaç](https://www.linkedin.com/in/ahmetvehbiolgac/?originalSubdomain=tr) and [Marcel Dempers](https://www.linkedin.com/in/marceldempers/?originalSubdomain=au) and courses on [Pluralsight](https://www.pluralsight.com) by [Elton Stoneman](https://www.linkedin.com/in/eltonstoneman/?originalSubdomain=uk) really helped me a lot as the basis of the content of this repo (see section the [References](#references)).

_Note_:  
None of the deployments are meant to describe how these products should be deployed in a Production or any other environment.  The aim is just to show from a high-level perspective how these products work and how some of them can be monitored.


### References

#### RabbitMQ

[Monitoring with Prometheus & Grafana](https://www.rabbitmq.com/prometheus.html)

[Implementing Highly Available RabbitMQ Cluster on Docker Swarm using Consul-based Discovery](https://medium.com/hepsiburadatech/implementing-highly-available-rabbitmq-cluster-on-docker-swarm-using-consul-based-discovery-45c4e7919634) by Ahmet Vehbi Olgaç  

[RabbitMQ : Message Queues for beginners](https://www.youtube.com/watch?v=hfUIWe1tK8E) by Marcel Dempers  

[RabbitMQ : How to setup a RabbitMQ cluster - for beginners](https://www.youtube.com/watch?v=FzqjtU2x6YA) by Marcel Dempers  

[Observe and understand RabbitMQ](https://www.youtube.com/watch?v=L-tYXpirbpA) by Gerhard Lazu & Michal Kuratczyk  

#### Prometheus

[Getting Started with Prometheus (Pluralsight)](https://app.pluralsight.com/library/courses/getting-started-prometheus) by Elton Stoneman  

[Monitoring Containerized Application Health with Docker (Pluralsight)](https://app.pluralsight.com/library/courses/monitoring-containerized-app-health-docker/table-of-contents) by Elton Stoneman

