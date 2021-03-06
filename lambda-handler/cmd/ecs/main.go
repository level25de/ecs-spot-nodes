package main

import (
	"encoding/json"
	"flag"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	a "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/golang/glog"
	"github.com/level25de/ecs-spot-nodes/lambda-handler/pkg/aws"
	"os"
)

type MyResponse struct {
	Message string `json:"data:"`
	Asg     string `json:"asg:"`
}

func countECSInstances(arn string) (int, error) {
	sess := aws.InitECSAwsSession(os.Getenv("AWS_REGION"))

	input := &ecs.ListContainerInstancesInput{
		Cluster: a.String(arn),
	}
	instances, _ := sess.ListContainerInstances(input)

	instanceData, err := sess.DescribeContainerInstances(&ecs.DescribeContainerInstancesInput{
		Cluster:            a.String(arn),
		ContainerInstances: instances.ContainerInstanceArns,
	})

	if err != nil {
		return 0, err
	}

	instanceCount := 0

	for _, details := range instanceData.ContainerInstances {
		glog.Infof("Status: %s", *details.Status)
		if *details.Status == "ACTIVE" {
			instanceCount++
		}
	}

	return instanceCount, nil
}

func HandleLambdaEvent(event events.CloudWatchEvent) (MyResponse, error) {
	var clusterArn string
	{
		var dat map[string]interface{}
		_ = json.Unmarshal(event.Detail, &dat)

		clusterArn = string(dat["clusterArn"].(string))
	}

	instances, err := countECSInstances(clusterArn)

	if err != nil {
		return MyResponse{}, err
	}

	sess := aws.InitASGAwsSession(os.Getenv("AWS_REGION"))
	_, spot_requested := aws.CheckASG(sess, os.Getenv("ASG_SPOT"))

	if instances != spot_requested {
		cap := int64(spot_requested - instances)
		if cap < 0 {
			cap = 0
		}

		glog.Infof("Difference between instance counts detected. Correcting: %d (spot: %d / instances: %d)", cap, spot_requested, instances)

		err := aws.UpdateASGInstanceCount(sess, os.Getenv("ASG_ONDEMAND"), cap)

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
