# Run ECS on spot nodes

This is an implementation to run ECS entirely on AWS spot instances. It uses some of the ideas by AWS from here: 
https://github.com/awslabs/ec2-spot-labs/tree/master/ecs-ec2-spot-fleet

By hooking into CloudWatch Events and computing the size of two different autoscaling groups, this allows to run ECS very price efficient. 
