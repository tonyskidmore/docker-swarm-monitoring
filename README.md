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
None of the deployments are meant to describe how these products should be deployed in a Production or any other type of environment.  The aim is just to show from a high-level perspective how these products work and how some of them can be monitored.  

### Services layout
![Alt text](images/layout.png "Services layout")

The layout above represents a high-level view of the services that will be deployed and the externally accessible ports from the Windows host system.  It also shows the monitoring scraping communication lines from Prometheus to: Docker Swarm nodes, RabbitMQ cluster nodes and the Java application.  Grafana is shown using Prometheus as a data source.

### Getting started

The first step is to ensure that the Docker Swarm mode cluster has been deployed as per the [tonyskidmore/docker-swarm](https://github.com/tonyskidmore/docker-swarm) project.  A differently deployed Docker swarm cluster can be used if desired but references to the specifics of that cluster will need to be adjusted. 

If you are following along with the initial cluster deployment and then moving here perform the following steps on you Windows 10 host:  

````powershell

cd \vagrant

git clone https://github.com/tonyskidmore/docker-swarm-monitoring.git

cd docker-swarm-monitoring

````

#### Windows host PowerShell access
The default Docker Swarm mode cluster has been deployed in such a way that access to it from the Windows host is made via unencrypted communication to to the Docker Swarm manager node (`192.168.217.133:2375`).  It is necessary to set environment variables in any PowerShell session so this works:

````powershell
$env:DOCKER_HOST="192.168.217.133:2375"
$env:DOCKER_TLS_VERIFY=""

docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
qmh74hjo5djwwzqa7jkyknisb *   docker-swarm-01     Ready               Active              Leader              19.03.13
fu8kqvcxfuficfi1ld0owy0l6     docker-swarm-02     Ready                Active                                 19.03.13
ydqqjvpshir1nhss6surd11kr     docker-swarm-03     Ready               Active                                  19.03.13

````
If your output is similar to the above then you are good to go.

### Service deployment

#### TLDR

The [Start-SwarmApps.ps1](https://github.com/tonyskidmore/docker-swarm-monitoring/blob/main/Start-SwarmApps.ps1) PowerShell script can be used interactively or ran from a PowerShell prompt on the Windows 10 host to drive all of the deployments.  The script needs some refactoring but for now it has worked in testing.  Further below are the more individual and generic steps that can be performed to deploy the application stacks.  

If you wanted to just deploy everything without stepping through everything then you should be able to execute the following:

````powershell

cd c:\vagrant\docker-swarm-monitoring
.\Start-SwarmApps.ps1

````
If there are no issues then the script should deploy all of the services shown in the [Services layout](#services-layout) section, opening a browser to each as it goes.  Click on the script window to refocus on the script.  You can run with the `-OpenBrowser $false` parameter to avoid the browser functionality if desired.  

_Note_:  
PowerShell script execution has to be allowed on your system to be able to run scripts.  To allow script execution, if not already enabled, run PowerShell as Administrator and run the following prior to running the instructions above:  

````powershell

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

````

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

