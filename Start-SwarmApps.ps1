# To allow script execution run PowerShell as Administrator and run
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

Param(

    # whether to open browser sessions for each app
    $OpenBrowser = $true

)

#region urlref
<#
UI URL Reference

Consul
http://192.168.217.133:8500

RabbitMQ
http://192.168.217.133:15672

Java App
http://192.168.217.133:8080

Prometheus
http://192.168.217.133:9090

Grafana
http://192.168.217.133:3000

#>
#endregion urlref

#region variables

$VerbosePreference = 'Continue'
# docker swarm network to create
$networkName = "test"
# if running interactively set OpenBrowser to true also
if([string]::IsNullOrEmpty($OpenBrowser)) { $OpenBrowser = $true }

#endregion variables

#region functions

function Get-RandomString {
    Param (
        $Length = 10
    )

    -join ((48..57) + (97..122) | Get-Random -Count $Length | ForEach-Object {[char]$_})

}

#endregion functions

#region setenvironment

# set communication for insecure access to docker swarm manager node
Write-Verbose -Message "Setting envirornment variables"
$env:DOCKER_HOST="192.168.217.133:2375"
$env:DOCKER_TLS_VERIFY=""

#endregion setenvironment

#region validate

# check communication and node status
Write-Verbose -Message "Checking Docker Swarm mode nodes"
docker node ls

#endregion validate

#region network

# create the docker network that our apps will be attached to
Write-Verbose -Message "Creating overlay network if it doesn't already exist"
& docker network inspect $networkName 2>&1 | Out-Null; if(-not $?) { & docker network create --driver=overlay --attachable $networkName }

# check network status
$networks = docker network ls --format='{{json .}}' | ConvertFrom-Json
$networks | Where-Object Name -eq $networkName

#endregion network

#region consul

# deploy consul if not already deployed
Write-Verbose -Message "Deploying Consul if not already deployed"
& docker stack services consul 2>&1 | Out-Null
if(-not $?) {
    docker stack deploy -c docker-compose-consul.yml consul
    $consulDeployed = $true
} else {
    $consulDeployed = $false
}

# wait for consule cluster to start up
if ($consulDeployed) { Start-Sleep -Seconds 10 }

# check the status of the service - we want to see REPLICAS 3/3
for($i = 0 ; $i -lt 40 ; $i++) {
    $consulService = docker stack services consul --format='{{json .}}' | ConvertFrom-Json
    Write-Verbose -Message "Waiting for Consul services to start"
    if($consulService.Replicas -eq '3/3') { $consulServiceOK = $true ; break } else { $consulServiceOK = $false }
    Start-Sleep -Seconds 1
}
if($consulServiceOK -eq $false) { throw "Failed to start Consul service" }

docker stack ps consul

# wait for a Consul election
for($i = 0 ; $i -lt 40 ; $i++) {
    Write-Verbose -Message "Waiting for Consul leader election"
    $consulLeader = ((Invoke-WebRequest -Uri 192.168.217.133:8500/v1/status/leader -UseBasicParsing).Content).Replace("`"","")
    if($consulLeader -ne "") { break }
    Start-Sleep -Seconds 1
}
$consulPeers = (Invoke-WebRequest -Uri 192.168.217.133:8500/v1/status/peers -UseBasicParsing).Content  | ConvertFrom-Json
Write-Output "Consule Leader:"
$consulLeader
Write-Output "Consul Peers:"
$consulPeers

# open Consul in default web browser
if($OpenBrowser) { Start-Process "http://192.168.217.133:8500" }

#endregion consul

#region rabbitmq

# label nodes so that rabbitmq containers can be placed correctly
Write-Verbose -Message "Setting node labels for RabbitMQ placement"
1..3 | ForEach-Object { 
            & docker node update --label-add "rabbitmq$_=true" "docker-swarm-0$_"
            (docker inspect "docker-swarm-0$_" | ConvertFrom-Json).Spec.Labels | ConvertTo-Json
       }

# deploy rabbitmq if not already deployed
Write-Verbose -Message "Deploying RabbitMQ if not already deployed"
& docker stack services rabbitmq 2>&1 | Out-Null
if(-not $?) {
    docker stack deploy -c docker-compose-rabbitmq.yml rabbitmq
    $rabbitmqDeployed = $true
} else {
    $rabbitmqDeployed = $false
}

# introduce short pause
if ($rabbitmqDeployed ) { Start-Sleep -Seconds 10 }

# check the status of the service - we want to see 3 x REPLICAS 1/1
for($i = 0 ; $i -lt 40 ; $i++) {
    Write-Verbose -Message "Waiting for RabbitMQ services to start"
    $rabbitmqService = docker stack services rabbitmq --format='{{json .}}' | ConvertFrom-Json
    if(($rabbitmqService | Where-Object Replicas -eq "1/1").Count -eq 3) { $rabbitmqServiceOK = $true ; break } else { $rabbitmqServiceOK = $false }
    Start-Sleep -Seconds 1
}
if($rabbitmqServiceOK -eq $false) { throw "Failed to start RabbitMQ service" }

docker stack ps rabbitmq

# RabbitMQ has been deployed behind haproxy so that needs to be brought up first

#endregion rabbitmq

#region haproxy

# deploy haproxy if not already deployed
Write-Verbose -Message "Deploying RabbitMQ if not already deployed"
& docker stack services haproxy 2>&1 | Out-Null
if(-not $?) {
    docker stack deploy -c docker-compose-haproxy.yml haproxy
    $haproxyDeployed = $true
} else {
    $haproxyDeployed = $false
}

# wait for haproxy to start up
if ($haproxyDeployed) { Start-Sleep -Seconds 10 }

# check the status of the service - we want to see REPLICAS 3/3
for($i = 0 ; $i -lt 40 ; $i++) {
    Write-Verbose -Message "Waiting for haproxy services to start"
    $haproxyService = docker stack services haproxy --format='{{json .}}' | ConvertFrom-Json
    if($haproxyService.Replicas -eq '3/3') { $haproxyServiceOK = $true ; break } else { $haproxyServiceOK = $false }
    Start-Sleep -Seconds 1
}
if($haproxyServiceOK -eq $false) { throw "Failed to start haproxy service" }

docker stack ps haproxy

#endregion haproxy

#region rabbitmqaccess

 

# open RabbitMQ in default web browser
# default credentials for Rabbit MQ: guest/guest
if($OpenBrowser) {

    
    for($i = 0 ; $i -lt 40 ; $i++) {
        Write-Verbose -Message "Waiting for RabbitMQ web UI to be available"
        try {
            $resp = Invoke-WebRequest -Uri "http://192.168.217.133:15672" -UseBasicParsing -ErrorAction Stop
        }
        catch {
            Write-Verbose -Message "Did not get successful response from RabbitMQ"
        }
        if($resp.StatusCode -eq 200) { break }
        Start-Sleep -Seconds 1
    }
    Start-Process "http://192.168.217.133:15672" 
}

#endregion rabbitmqaccess

#region javaapp

# deploy sample java app if not already deployed
Write-Verbose -Message "Deploying example Java app if not already deployed"
& docker stack services java 2>&1 | Out-Null
if(-not $?) {
    docker stack deploy -c docker-compose-java.yml java
    $javaDeployed = $true
} else {
    $javaDeployed = $false
}

# wait for java app replicas to start up
if ($javaDeployed) { Start-Sleep -Seconds 10 }

# check the status of the service - we want to see REPLICAS 3/3
for($i = 0 ; $i -lt 40 ; $i++) {
    $javaService = docker stack services java --format='{{json .}}' | ConvertFrom-Json
    Write-Verbose -Message "Waiting for java services to start"
    if($javaService.Replicas -eq '3/3') { $javaServiceOK = $true ; break } else { $javaServiceOK = $false }
    Start-Sleep -Seconds 1
}
if($javaServiceOK -eq $false) { throw "Failed to start java app service" }

docker stack ps java

# fire some activity at the java web server
for ($i=1 ;$i -lt 40 ; $i++) {  Invoke-WebRequest -Uri http://192.168.217.133:8080/ -UseBasicParsing | Out-Null }

# open java app in default web browser
if($OpenBrowser) { Start-Process "http://192.168.217.133:8080" }


#endregion javaapp

#region monitoring


# deploy prometheus/grafana monitoring if not already deployed
Write-Verbose -Message "Deploying Prometheus and Grafana if not already deployed"
& docker stack services monitoring 2>&1 | Out-Null
if(-not $?) {
    docker stack deploy -c docker-compose-monitoring.yml monitoring
    $monitoringDeployed = $true
} else {
    $monitoringDeployed = $false
}

# introduce short pause
if ($monitoringDeployed) { Start-Sleep -Seconds 10 }

# check the status of the service - we want to see 3 x REPLICAS 1/1
for($i = 0 ; $i -lt 40 ; $i++) {
    Write-Verbose -Message "Waiting for monitoring services to start"
    $monitoringService = docker stack services monitoring --format='{{json .}}' | ConvertFrom-Json
    if(($monitoringService | Where-Object Replicas -eq "1/1").Count -eq 2) { $monitoringServiceOK = $true ; break } else { $monitoringServiceOK = $false }
    Start-Sleep -Seconds 1
}
if($monitoringServiceOK -eq $false) { throw "Failed to start monitoring services" }

docker stack ps monitoring

# these have not been deploye behind haproxy in this example so we can access them directly
# open Prometheus
# check the Status - Targets
# check the Status - Configuration
# try executing a PromQL query in Graphs e.g:

# rabbitmq_build_info

if($OpenBrowser) { Start-Process "http://192.168.217.133:9090" }

# open Grafana
# default credentials for Grafana: admin/admin
if($OpenBrowser) { Start-Process "http://192.168.217.133:3000" }

#endregion monitoring

#region amqppublisher

# deploy publisher if not already deployed
Write-Verbose -Message "Deploying RabbitMQ messaging publisher service if not already deployed"
& docker stack services publisher 2>&1 | Out-Null
if(-not $?) {
    docker stack deploy -c docker-compose-publisher.yml publisher
    $publisherDeployed = $true
} else {
    $publisherDeployed = $false
}

# introduce short pause
if ($publisherDeployed) { Start-Sleep -Seconds 10 }

# check the status of the service - we want to see REPLICAS 1/1
for($i = 0 ; $i -lt 40 ; $i++) {
    Write-Verbose -Message "Waiting for publisher services to start"
    $publisherService = docker stack services publisher --format='{{json .}}' | ConvertFrom-Json
    if($publisherService | Where-Object Replicas -eq "1/1") { $publisherServiceOK = $true ; break } else { $publisherServiceOK = $false }
    Start-Sleep -Seconds 1
}
if($publisherServiceOK -eq $false) { throw "Failed to start publisher services" }

docker stack ps publisher

#endregion amqppublisher

#region queuemessages

$messages = 20
Write-Verbose -Message "Sending $messages messages to the RabbitMQ cluster"
for($i = 1 ; $i -le $messages ; $i++) {
    $message = Get-RandomString
    Invoke-RestMethod -Method POST -Uri "http://192.168.217.133:80/publish/$message" -UseBasicParsing
}

#endregion queuemessages

#region amqpconsumer

# deploy consumer if not already deployed
Write-Verbose -Message "Deploying RabbitMQ messaging consumer service if not already deployed"
& docker stack services consumer 2>&1 | Out-Null
if(-not $?) {
    docker stack deploy -c docker-compose-consumer.yml consumer
    $consumerDeployed = $true
} else {
    $consumerDeployed = $false
}

# introduce short pause
if ($consumerDeployed) { Start-Sleep -Seconds 10 }

# check the status of the service - we want to see REPLICAS 1/1
for($i = 0 ; $i -lt 40 ; $i++) {
    Write-Verbose -Message "Waiting for consumer services to start"
    $consumerService = docker stack services consumer --format='{{json .}}' | ConvertFrom-Json
    if($consumerService | Where-Object Replicas -eq "1/1") { $consumerServiceOK = $true ; break } else { $consumerServiceOK = $false }
    Start-Sleep -Seconds 1
}
if($consumerServiceOK -eq $false) { throw "Failed to start consumer services" }

docker stack ps consumer

#endregion amqpconsumer

#region removestacks

# run the code in the script block to remove the deployed stacks
# code will not run by default

{
    docker stack ls
    docker stack rm consumer
    docker stack rm publisher
    docker stack rm monitoring
    docker stack rm java
    docker stack rm rabbitmq
    docker stack rm haproxy
    docker stack rm consul
    docker stack ls
}


#endregion removestacks