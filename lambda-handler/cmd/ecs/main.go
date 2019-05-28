package main

import (
	"github.com/level25de/ecs-spot-nodes/lambda-handler/pkg/aws"
	a "github.com/aws/aws-sdk-go/aws"
	"flag"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/golang/glog"
	"os"
	"encoding/json"
)

type MyResponse struct {
	Message string `json:"data:"`
	Asg     string `json:"asg:"`
}

func countECSInstances(arn string) (int) {
	sess := aws.InitECSAwsSession(os.Getenv("AWS_REGION"))

	input := &ecs.ListContainerInstancesInput{
		Cluster: a.String(arn),
	}
	instances, _ := sess.ListContainerInstances(input)

	instanceData, _ := sess.DescribeContainerInstances(&ecs.DescribeContainerInstancesInput{
		Cluster: a.String(arn),
		ContainerInstances: instances.ContainerInstanceArns,
	})

	instanceCount := 0

	for _, details := range instanceData.ContainerInstances {
		glog.Infof("Status: %s", *details.Status)
		if *details.Status == "ACTIVE" { 
			instanceCount++
		}
	}

	return instanceCount
}

func HandleLambdaEvent(event events.CloudWatchEvent) (MyResponse, error) {
	var clusterArn string
	{
		var dat map[string]interface{}
		_ = json.Unmarshal(event.Detail, &dat)
		
		clusterArn = string(dat["clusterArn"].(string))
	}

	instances := countECSInstances(clusterArn)

	sess := aws.InitASGAwsSession(os.Getenv("AWS_REGION"))
	_, spot_requested := aws.CheckASG(sess, os.Getenv("ASG_SPOT"))

	if instances != spot_requested {
		glog.Infof("Difference between instance counts detected. Correcting with ondemand")

		cap := int64(spot_requested - instances)
		if cap < 0 {
			cap = 0
		}

		_, err := aws.UpdateASGInstanceCount(sess, os.Getenv("ASG_ONDEMAND"), cap)

		if err != nil {
			return MyResponse{}, err
		}
	}
	
	return MyResponse{
		Asg:     os.Getenv("ASG_ONDEMAND"),
		Message: string("success"),
	}, nil
}

func main() {
	flag.Set("logtostderr", os.Getenv("LOGTOSTDERR"))
	flag.Set("v", os.Getenv("VERBOSITY"))
	flag.Parse()
	lambda.Start(HandleLambdaEvent)
	glog.Flush()
}
