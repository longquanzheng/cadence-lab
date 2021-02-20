# What
This package contains examples of Cadence dashboards with Prometheus.

Cadence-Client is the dashboard of client metrics, and a few server side metrics that belong to client side but have to be emitted by server(for example, workflow timeout).

Cadence-Server-Basic is the the basic server dashboard to monitor/navigate the health/status of a Cadence cluster.

# How

To try it out locally, make sure you have client emit the prometheus metrics and collected by Prometheus:
* Follow this example to emit the client side metrics: https://github.com/uber-common/cadence-samples/pull/36/files for Golang client. Java client also has the equivalent configuration. 

* For local testing of Promethues, easies way is to use https://github.com/uber/cadence/blob/master/docker/docker-compose-prometheus.yml to start a local Cadence,
update the https://github.com/uber/cadence/blob/master/docker/prometheus_config.yml to ad "host.docker.internal:9098" to the scrape list before starting the docker-compose.

Note: `host.docker.internal` may not work for some docker versions, see https://docs.docker.com/docker-for-mac/networking/#use-cases-and-workarounds for more information. 

* After updating the prometheus_config.yaml as above, run `docker-compose -f docker-compose-prometheus.yml up` to start the local Cadence

* Go the the sample repo, build the helloworld sample `make helloworld` and run the worker `./bin/helloworld -m worker`, and then in another Shell start a workflow `./bin/helloworld`

* Go to Prometheus server: http://localhost:9090/ , you should be able to check the metrics handler from client/frontend/matching/history/sysWorker are all healthy as targets: http://localhost:9090/targets
<img width="1192" alt="Screen Shot 2021-02-20 at 11 31 11 AM" src="https://user-images.githubusercontent.com/4523955/108606555-8d0dfb80-736f-11eb-968d-7678df37455c.png">


* Go to Grafana: http://localhost:3000 , login as admin/admin. 
* Configure Prometheus as datasource: use `http://host.docker.internal:9090` as URL of prometheus. 
* Import the dashboard as JSON files in this package under prometheus/ folder. 

Client side dashboard looks like this:
<img width="1513" alt="Screen Shot 2021-02-20 at 12 32 23 PM" src="https://user-images.githubusercontent.com/4523955/108607838-b7fc4d80-7377-11eb-8fd9-edc0e58afaad.png">

And server basic dashboard:
<img width="1514" alt="Screen Shot 2021-02-20 at 12 31 54 PM" src="https://user-images.githubusercontent.com/4523955/108607843-baf73e00-7377-11eb-9759-e67a1a00f442.png">


Note that some non-latency metrics are not properly shown until this fix: https://github.com/uber/cadence/pull/4007 , unless you manually configure the buckets for Prometheus. 
This is because of issue https://github.com/uber/cadence/issues/4006 
<img width="1519" alt="Screen Shot 2021-02-20 at 11 06 54 AM" src="https://user-images.githubusercontent.com/4523955/108606577-b169d800-736f-11eb-8fcb-88801f23b656.png">


