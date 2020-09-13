package main

import (
	"os"

	_ "example.com/cadence-sqlite/sqlite-plugin" // needed to load sqlite plugin

	"github.com/uber/cadence/cmd/server/cadence"
)

// main entry point for the cadence server
func main() {
	app := cadence.BuildCLI()
	app.Run(os.Args)
}
