# What
This package contains examples of Cadence dashboards with Prometheus.

Cadence-Client is the dashboard of client metrics, and a few server side metrics that belong to client side but have to be emitted by server(for example, workflow timeout).

TODO: Cadence-Server-Basic the the basic server dashboard to monitor/navigate the health/status of a Cadence cluster.

# How

To try it out locally, make sure you have client emit the prometheus metrics and collected by Prometheus:
* Follow this example to emit the client side metrics: https://github.com/uber-common/cadence-samples/pull/36/files for Golang client. Java client also has the equivalent configuration. 

* For local testing of Promethues, easies way is to use https://github.com/uber/cadence/blob/master/docker/docker-compose-prometheus.yml to start a local Cadence,
update the https://github.com/uber/cadence/blob/master/docker/prometheus_config.yml to ad "host.docker.internal:9098" to the scrape list before starting the docker-compose.

Note: `host.docker.internal` may not work for some docker versions, see https://docs.docker.com/docker-for-mac/networking/#use-cases-and-workarounds for more information. 

* After updating the prometheus_config.yaml as above, run `docker-compose -f docker-compose-prometheus.yml up` to start the local Cadence

* Go the the sample repo, build the helloworld sample `make helloworld` and run the worker `./bin/helloworld -m worker`, and then in another Shell start a workflow `./bin/helloworld`

* Go to Prometheus server: http://localhost:9090/ , you should be able to check the metrics handler from client/frontend/matching/history/sysWorker are all healthy as targets: http://localhost:9090/targets

* Go to Grafana: http://localhost:3000 , login as admin/admin. 
* Import the dashboard as JSON files in this package. 

