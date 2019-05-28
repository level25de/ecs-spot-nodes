package aws

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/golang/glog"
)

func InitASGAwsSession(region string) *autoscaling.AutoScaling {
	glog.Infof("Establishing AWS ASG API session with region: %s", region)
	return autoscaling.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	})))
}

func InitECSAwsSession(region string) *ecs.ECS {
	glog.Infof("Establishing AWS ECS API session with region: %s", region)
	return ecs.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	})))
}

func GetASGData(asg *autoscaling.AutoScaling, group string) (*autoscaling.Group, error) {
	glog.Infof("Fetching information for ASG: %s", group)
	data, err := asg.DescribeAutoScalingGroups(&autoscaling.DescribeAutoScalingGroupsInput{
		AutoScalingGroupNames: []*string{
			aws.String(group),
		},
	})

	if err != nil {
		return nil, err
	}

	return data.AutoScalingGroups[0], nil
}

func UpdateASGInstanceCount(sess *autoscaling.AutoScaling, asg string, desired int64) (bool, error) {
	input := &autoscaling.UpdateAutoScalingGroupInput{
		AutoScalingGroupName: aws.String(asg),
		DesiredCapacity:      aws.Int64(desired),
	}

	_, err := sess.UpdateAutoScalingGroup(input)

	if err != nil {
		return false, err
	}

	return true, nil
}

func CheckASG(sess *autoscaling.AutoScaling, group string) (int, int) {
	data, _ := GetASGData(sess, group)
	count := 0
	for _, instance := range data.Instances {
		if *instance.LifecycleState == "InService" {
			count++
		}
	}
	glog.Infof("ARN: %s", *data.AutoScalingGroupARN)
	glog.Infof("Running: %d/%d (%d-%d)", count, *data.DesiredCapacity, *data.MinSize, *data.MaxSize)

	return int(count), int(*data.DesiredCapacity)
}