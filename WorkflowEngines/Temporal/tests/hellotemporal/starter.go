package main

import (
	"context"
	"fmt"
	"os"

	"go.temporal.io/sdk/client"
	"go.uber.org/zap"

	"github.com/temporalio/temporal-go-samples/helloworld"
)

// https://stackoverflow.com/questions/40326540/how-to-assign-default-value-if-env-var-is-empty
func getenv(key, fallback string) string {
    value := os.Getenv(key)
    if len(value) == 0 {
        return fallback
    }
    return value
}

func main() {
	logger, err := zap.NewDevelopment()
	if err != nil {
		panic(err)
	}

	// The client is a heavyweight object that should be created once per process.
	c, err := client.NewClient(client.Options{HostPort: fmt.Sprintf("%v:%v", getenv("TFEADDR","127.0.0.1"), getenv("TFEPORT",7233))})
	if err != nil {
		logger.Fatal("Unable to create client", zap.Error(err))
	}
	defer c.Close()

	workflowOptions := client.StartWorkflowOptions{
		ID:        "hello_world_workflowID",
		TaskQueue: "hello-world",
	}

	we, err := c.ExecuteWorkflow(context.Background(), workflowOptions, helloworld.Workflow, "Temporal")
	if err != nil {
		logger.Fatal("Unable to execute workflow", zap.Error(err))
	}

	logger.Info("Started workflow", zap.String("WorkflowID", we.GetID()), zap.String("RunID", we.GetRunID()))

	// Synchronously wait for the workflow completion.
	var result string
	err = we.Get(context.Background(), &result)
	if err != nil {
		logger.Fatal("Unable get workflow result", zap.Error(err))
	}
	logger.Info("Workflow result", zap.String("Result", result))
}
