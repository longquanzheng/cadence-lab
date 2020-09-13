package main

import (
	"os"

	_ "example.com/cadence-sqlite/sqlite-plugin" // needed to load sqlite plugin

	"github.com/uber/cadence/tools/sql"
)

func main() {
	sql.RunTool(os.Args)
}
