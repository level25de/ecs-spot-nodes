package main

import (
	"flag"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/golang/glog"
	"github.com/level25de/ecs-spot-nodes/lambda-handler/pkg/aws"
	"os"
)

type MyResponse struct {
	Message string `json:"data:"`
	Asg     string `json:"asg:"`
}

func HandleLambdaEvent(event events.AutoScalingEvent) (MyResponse, error) {
	glog.Infof("Handling message: %s", event.Detail["StatusMessage"].(string))

	sess := aws.InitASGAwsSession(os.Getenv("AWS_REGION"))

	// get spot details
	spot_running, spot_requested := aws.CheckASG(sess, os.Getenv("ASG_SPOT"))
	delta := spot_requested - spot_running
	glog.Infof("Missing instances count: %d", delta)

	// get ondemand data
	_, ondemand_requested := aws.CheckASG(sess, os.Getenv("ASG_ONDEMAND"))
	overflow := delta - ondemand_requested
	glog.Infof("Missing instances count: %d", delta)
	glog.Infof("Overflow capacity: %d", overflow)

	// check if api request is required to update asg
	if overflow != 0 && ondemand_requested != delta {
		if overflow < 0 {
			delta = 0
		}

		glog.Infof("Updating ondemand ASG instance count to: %d", delta)
		err := aws.UpdateASGInstanceCount(sess, os.Getenv("ASG_ONDEMAND"), int64(delta))

		if err != nil {
			return MyResponse{}, err
		}
	} else {
		glog.Infof("Skipping instance count normalization")
	}

	return MyResponse{
		Asg:     os.Getenv("ASG_ONDEMAND"),
		Message: event.Detail["StatusMessage"].(string),
	}, nil
}

func main() {
	flag.Set("logtostderr", os.Getenv("LOGTOSTDERR"))
	flag.Set("v", os.Getenv("VERBOSITY"))
	flag.Parse()
	lambda.Start(HandleLambdaEvent)
	glog.Flush()
}
