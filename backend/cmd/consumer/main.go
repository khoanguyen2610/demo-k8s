package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"syscall"
	"time"
)

type Task interface {
	Run() error
	Name() string
}

// EmailProcessorTask simulates processing emails
type EmailProcessorTask struct{}

func (t *EmailProcessorTask) Name() string {
	return "email-processor"
}

func (t *EmailProcessorTask) Run() error {
	log.Printf("[%s] Starting task...", t.Name())
	
	for {
		// Simulate processing emails
		emailCount := rand.Intn(10) + 1
		log.Printf("[%s] Processing %d emails...", t.Name(), emailCount)
		
		time.Sleep(time.Duration(rand.Intn(5)+3) * time.Second)
		
		// Simulate different email operations
		operations := []string{"Sending", "Filtering", "Categorizing", "Archiving"}
		operation := operations[rand.Intn(len(operations))]
		log.Printf("[%s] %s %d emails completed", t.Name(), operation, emailCount)
	}
}

// DataSyncTask simulates syncing data between systems
type DataSyncTask struct{}

func (t *DataSyncTask) Name() string {
	return "data-sync"
}

func (t *DataSyncTask) Run() error {
	log.Printf("[%s] Starting task...", t.Name())
	
	for {
		// Simulate syncing data
		recordCount := rand.Intn(100) + 50
		log.Printf("[%s] Syncing %d records...", t.Name(), recordCount)
		
		time.Sleep(time.Duration(rand.Intn(7)+5) * time.Second)
		
		// Simulate different sync operations
		sources := []string{"Database", "API", "File Storage", "Cache"}
		source := sources[rand.Intn(len(sources))]
		log.Printf("[%s] Synced %d records from %s successfully", t.Name(), recordCount, source)
		
		// Simulate occasional sync issues
		if rand.Float32() < 0.1 {
			log.Printf("[%s] Warning: Some records failed to sync, will retry", t.Name())
		}
	}
}

// ReportGeneratorTask simulates generating reports
type ReportGeneratorTask struct{}

func (t *ReportGeneratorTask) Name() string {
	return "report-generator"
}

func (t *ReportGeneratorTask) Run() error {
	log.Printf("[%s] Starting task...", t.Name())
	
	for {
		// Simulate generating reports
		reportTypes := []string{"Daily Summary", "Weekly Analytics", "Monthly Report", "Quarterly Review"}
		reportType := reportTypes[rand.Intn(len(reportTypes))]
		
		log.Printf("[%s] Generating %s...", t.Name(), reportType)
		
		time.Sleep(time.Duration(rand.Intn(10)+8) * time.Second)
		
		// Simulate report completion
		pages := rand.Intn(50) + 10
		log.Printf("[%s] %s generated successfully (%d pages)", t.Name(), reportType, pages)
		
		// Simulate different output formats
		formats := []string{"PDF", "Excel", "CSV", "JSON"}
		format := formats[rand.Intn(len(formats))]
		log.Printf("[%s] Exported to %s format", t.Name(), format)
	}
}

func main() {
	// Set random seed
	rand.Seed(time.Now().UnixNano())
	
	// Parse command-line flags
	taskName := flag.String("task", "", "Task name to run (email-processor, data-sync, report-generator)")
	flag.Parse()
	
	if *taskName == "" {
		log.Fatal("Error: --task flag is required. Available tasks: email-processor, data-sync, report-generator")
	}
	
	// Create task based on name
	var task Task
	switch *taskName {
	case "email-processor":
		task = &EmailProcessorTask{}
	case "data-sync":
		task = &DataSyncTask{}
	case "report-generator":
		task = &ReportGeneratorTask{}
	default:
		log.Fatalf("Error: Unknown task '%s'. Available tasks: email-processor, data-sync, report-generator", *taskName)
	}
	
	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	
	// Run task in goroutine
	errChan := make(chan error, 1)
	go func() {
		errChan <- task.Run()
	}()
	
	// Wait for shutdown signal or error
	select {
	case <-sigChan:
		log.Printf("[%s] Received shutdown signal, exiting gracefully...", task.Name())
	case err := <-errChan:
		if err != nil {
			log.Fatalf("[%s] Task failed: %v", task.Name(), err)
		}
	}
	
	fmt.Printf("[%s] Task stopped\n", task.Name())
}

