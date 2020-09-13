module example.com/cadence-sqlite

go 1.13

require (
	github.com/iancoleman/strcase v0.0.0-20190422225806-e506e3ef7365
	github.com/jmoiron/sqlx v1.2.0
	github.com/mattn/go-sqlite3 v2.0.1+incompatible
	github.com/stretchr/testify v1.4.0
	github.com/uber/cadence v0.8.2-0.20191213182835-1e63e9323222
)

replace github.com/jmoiron/sqlx v1.2.0 => github.com/longquanzheng/sqlx v0.0.0-20191125235044-053e6130695c
