## Cadence SQL Plugin Demo
Implement SQL Plugin with SQLITE for [Cadence](https://github.com/uber/cadence/blob/master/docs/persistence.md)

### HOW
1. Build binaries:
```
make
```
2. Install schemas:
```
make install-schema-sqlite
```
3. Run:
```
./cadence-server start
```
You should see logs like:
```
$./cadence-server start
2019/12/13 13:53:52 Loading config; env=development,zone=,configDir=./config
2019/12/13 13:53:52 Loading configFiles=[./config/development.yaml]
2019/12/13 13:53:52 error creating file based dynamic config client, use no-op config client instead. error: error checking dynamic config file at path , error: stat : no such file or directory
{"level":"info","ts":"2019-12-13T13:53:52.013-0800","msg":"Created RPC dispatcher and listening","service":"cadence-frontend","address":"127.0.0.1:7933","logging-call-at":"rpc.go:81"}
{"level":"info","ts":"2019-12-13T13:53:52.014-0800","msg":"Get dynamic config","name":"system.advancedVisibilityWritingMode","value":"off","default-value":"off","logging-call-at":"config.go:58"}
{"level":"info","ts":"2019-12-13T13:53:52.014-0800","msg":"Get dynamic config","name":"system.enableGlobalDomain","value":"false","default-value":"false","logging-call-at":"config.go:58"}
{"level":"info","ts":"2019-12-13T13:53:52.014-0800","msg":"Creating RPC dispatcher outbound","service":"cadence-frontend","address":"localhost:7933","logging-call-at":"clientBean.go:276"}
{"level":"info","ts":"2019-12-13T13:53:52.015-0800","msg":"Starting service frontend","logging-call-at":"server.go:207"}
...
```
