---
description: >-
  This is probably one of the most common questions for anyone who is new to
  Cadence. The answer should be very clear, as workflow and activity are
  fundamentally different.
---

# What code should be written in a workflow or an activity in Cadence, and how

## The Problem

Imagine a use case: we want move some data from one database system\(Database-X\) to another\(Database-Y\), with some data filtering and transformation. Let's assume the dataset is fitting in the memory so that you don't have to optimize it for now. Without using Cadence, we might use a naive implementation like the below code. 

```go
func MigrateData() error{
    // Step 1: first read all the data from DB-X
    connX, err := ConnectToDBX()
    defer connX.Close()
    if err != nil { return err)
    
    queryResult, err := connX.SendQuery("some query")
    if err != nil { return err)
    
    dataStep1 := []RowDefX{}
    for ;queryResult.HasNext();{
       row := queryResult.Next()
       dataStep1 = append(dataStep1, row)
    }
    
    // Step 2: then do some filtering    
    dataStep2 := []RowDefX{}    
    for _, row:= range dataStep1{
       if row.COLA == SOME_CONSTANT {
          dataStep2 = append(dataStep2, row)
       }
    }
    
    // Step 3: then do some complex transformation
    dataStep3 := []RowDefY{}    
    id := 0
    for _, rowX:= range dataStep1{
        rowY.ID = id ++
        rowY.COLA = transformA(rowX.COLA)
        rowY.COLB = transformB(rowX.COLB)
        rowY.COLC = transformC(rowX.COLC)
    }
    
    // Step 4: finally write into DB-Y
    connY, err := ConnectToDBY()
    defer connY.Close()  
    if err != nil { return err)
 
    for ;rowY:=range dataStep3 {
       err := connY.WriteToDBY(rowY)
       if err != nil { return err)
    }  
}
```

An experienced engineer already knows there are problems in this naive implementation, even it's fitting into memory. For example, if reading/writing into Databases are very slow, any host restart during the writing could cause the whole process failed, and we have to restart the process from very beginning. 

Cadence can help improve this application to be resilient. But what is the best way to write and organize in Cadence?

## All into Workflow code

What if we write all the code in [`workflow`](https://cadenceworkflow.io/docs/concepts/workflows/) only? Without any  [`activity`](https://cadenceworkflow.io/docs/concepts/activities/).

```go
func MigrateDataWorkflow(ctx workflow.Context) error{
    // Everything in this method is exactly the same as the naive implementation
    //
}
```

Would this work? The answer is NO. 

It could be worse than the naive implementation. Because this implementation will try to do everything in one workflow task\(aka decision task\), it might work in the same way as the naive implementation, if the whole process is fast enough. But by default a workflow task timeout is a few seconds. Hence in our scenario it's more likely that workers will keep on executing workflow tasks, but never be able to finish it. 

## All in one single Activity

Activity is something to help. 

### Recommendation \#1

> **Any resource consuming code should be in activities**

Let start with putting everything into one single activity.

```go
func MigrateDataWorkflow(ctx workflow.Context) error{
  ao := workflow.ActivityOptions{
		ScheduleToStartTimeout: time.Minute,
		StartToCloseTimeout:    time.Hour,
		RetryPolicy :&RetryPolicy{
						InitialInterval:    time.Minute,
						BackoffCoefficient: 1,
						MaximumInterval:    time.Minute,
						ExpirationInterval: 24*time.Hour,		
		}
	}
	ctx = workflow.WithActivityOptions(ctx, ao)
	
  return workflow.ExecuteActivity(ctx, MigrateDataActivity).Get(ctx, nil)
}

func MigrateDataActivity(ctx context.Context) error{
		// Everything in this method is exactly the same as the naive implementation
		//...
}
```

This implementation is better. Manipulating the activity StartToCloseTimeout let it at least do the same thing as the naive implementation. RetryPolicy will retry the whole activity, which is better than the implementation. During retrying, the activity task can be dispatched to a different worker host. This will make the application more resilient to some host specific issues.

## Two Activities

One drawback of the previous implementation is that when writing to DatabaseY fails, it will restart from beginning, reading from DatabaseX again. This is not ideal.  

### Recommendation \#2

> **Use activities to add checkpoints to progress**

If there are two activities, one for reading and one for writing operation, the reading results can be saved as a checkpoint, so that the workflow doesn't need to read from database again when writing activity fails and do retry. 

```go
func MigrateDataWorkflow(ctx workflow.Context) error{
  ao := workflow.ActivityOptions{
		ScheduleToStartTimeout: time.Minute,
		StartToCloseTimeout:    time.Hour,
		RetryPolicy :&RetryPolicy{
						InitialInterval:    time.Minute,
						BackoffCoefficient: 2,
						MaximumInterval:    10*time.Minute,
						ExpirationInterval: 24*time.Hour,		
		}
	}
	ctx = workflow.WithActivityOptions(ctx, ao)
	
	//step 1
  dataStep1 := []RowDefX{}
  err := workflow.ExecuteActivity(ctx, ReadFromDbxActivity).Get(ctx, &dataStep1)
  
  // the code of step 2 in naive implementation
	//...

  // the code of step 3 in naive implementation
	//...		
	
	//step 4
  return workflow.ExecuteActivity(ctx, ReadFromDbxActivity, dataStep3).Get(ctx, nil)
  	
}

func ReadFromDbxActivity(ctx context.Context) ([]RowDefX, error){
		// the code of step 1 in naive implementation
		//...
		return dataStep1
}

func WriteDbyActivity(ctx context.Context, []RowDefY) (error){
		// the code of step 4 in naive implementation
		//...
}
```

## Workflow Determinism And Data Transportation

Even though the above implementation is better in terms of checkpointing, it may cause some other issues. It leaves the code of filtering and transforming in workflow code. This could cause unnecessary non-deterministic errors, if later on we want to change the logic. 

In addition, because of performance and limitation of the underlying persistence, Cadence service usually has certain size limits of transporting data within a workflow, eg., from one activity to another. 

### Recommendation \#**3**

> **Minimize workflow code to contain only code for orchestrating Cadence entities.**

### Recommendation \#4

> **Minimize data transportation within a workflow**

To follow recommendation \#1, consider moving the filtering code into reading activity, and the transforming into either reading or writing activity. 

For recommendation \#2, there are different ways to go:

* **Option 1** Passing a reference to the data instead. 
  * **Option 1.1** The data can be saved into local file system, and then a path to the data is passed. This requires the the two activities to be executed in the same host, otherwise the path is not valid. Because there are more than one hosts in a [Tasklist](https://cadenceworkflow.io/docs/concepts/task-lists/), a [Session](https://cadenceworkflow.io/docs/go-client/sessions/#basic-usage) is needed to ensure two activities are always running within the same host. 
  * **Option 1.2** The data can be saved into other blob storage, like S3 buckets. This won't require Session, but another dependency is required instead.
* **Option 2** Splitting the workload into small chucks for each activity. In this way, a loop will be implemented for read and write activities --- the read activity will return with some tracking point, whenever the data to return is near the limit, and then pass into the write  activity. After writing it will go to reading from the tracking point, again if there is more data to read. 

However, Option 2 could cause  issues, if there are hundreds of thousands of chunks. 

### Recommendation \#5

> **Do NOT let workflow history grow infinitely**

**Option 2+:** Based on Option2, workflow will do continueAsNew when the number of chunks executed in current run has exceeded a certain number, say 1000. 

**Option 3**: If possible, that we can put read and write into a single activity\(they are not owned by different teams\), there is another way to improve the workflow using Activity [Heartbeat](https://cadenceworkflow.io/docs/go-client/activities/#overview). Heartbeat is an advanced feature in Cadence activity. It allows an activity to add checkpoints, and recovery from the latest one whenever the activity restarted, just like workflows using activity for checkpointing . Even thought it's also a single activity, differently from the implementation of "[All in one single Activity](what-should-be-in-a-workflow-or-an-activity-in-cadence.md#all-in-one-single-activity)", activity progress is periodically being sent to Cadence  service.

The trade off of Option 3 is some complexity involved when using Heartbeat feature. It also drops some debuggability compared to Option 2+, because we can't [query](https://cadenceworkflow.io/docs/go-client/queries/#consistent-query) internal states of an activity like like a workflow. 

But it's worthy when you need this optimization. In fact, it's commonly used in Cadence server, to implement  system workflows like [Batch operation](https://github.com/uber/cadence/blob/fb076fb6a74b9ccd94a177eda296abce043addb0/service/worker/batcher/workflow.go#L182), Scanners etc. 

Here is a sample code of Option 3. If you need to refer to some production ready code,  [Batch operation](https://github.com/uber/cadence/blob/fb076fb6a74b9ccd94a177eda296abce043addb0/service/worker/batcher/workflow.go#L182) is a good example.

```go
func MigrateDataWorkflow(ctx workflow.Context) error{
  ao := workflow.ActivityOptions{
    // This is the only difference in ActivityOptions compared to "All in one single Activity"
    // It should be the maximum time we expect between two "RecoardHeartbeat()"
    HeartbeatTimeout:       time.Minute,
  
		ScheduleToStartTimeout: time.Minute,
		StartToCloseTimeout:    time.Hour,
		RetryPolicy :&RetryPolicy{
						InitialInterval:    time.Minute,
						BackoffCoefficient: 2,
						MaximumInterval:    10*time.Minute,
						ExpirationInterval: 24*time.Hour,		
		}
	}
	ctx = workflow.WithActivityOptions(ctx, ao)
	
  return workflow.ExecuteActivity(ctx, MigrateDataActivity).Get(ctx, nil)
}

func MigrateDataActivity(ctx context.Context) error{
  connX, err := ConnectToDBX()
  defer connX.Close()
  if err != nil { return err)
  
  connY, err := ConnectToDBY()
  defer connY.Close()  
  if err != nil { return err)
  
  // Step 0: get last HeartbeatDetails in case of recovering from last execution
  currentPage = BEGINNING
  if activity.HasHeartbeatDetails(ctx) {
  		activity.GetHeartbeatDetails(ctx, &currentPage);
  }


  for{
      // Step 1: first read all the data from DB-X
      queryResult, err := connX.SendQuery("some query with pagination parameter", currentPage)
      if err != nil { return err)
      currentPage = queryResult.GetNextPageCursor()
      
      dataStep1 := []RowDefX{}
      for ;queryResult.HasNext();{
         row := queryResult.Next()
         dataStep1 = append(dataStep1, row)
      }
      
      // the code of step 2 in naive implementation
      	 //...
      
      // the code of step 3 in naive implementation
      //...	
      
      // Step 4: finally write into DB-Y
      for ;rowY:=range dataStep3 {
         err := connY.WriteToDBY(rowY)
         if err != nil { return err)
      }
      
      // Here is the trick to upload the checkpoint.
      // Note that calling RecordHeartbeat here doesn't always send the checkpoint to Cadence immedieatlly.
      // There is some magic in Cadence SDK to control the timing to actually do it. So you don't need to optimize the performace for Cadence.
      if currentPage != nil{
         activity.RecordHeartbeat(ctx, currentPage)
      }else{
         break
      }           
  }
  
  return nil
}
```

