#!/bin/bash

# configurable options

NUM_PROJ=10     # number of projects
NUM_POD=10      # number of pods per project
LOGRATE=15000   # combined rate of msgs/sec of all logging pods
RUNTIME=30 # runtime in minutes
SLEEPTIME=$(( $RUNTIME*60 + 3 ))

# static options - no need to change these
UUID=$(uuidgen)
HOSTNAME=$(oc get route -n dittybopper | grep -v NAME | awk '{print $2}')

function templatize {
        echo Templatizing the config file
        LOG_PER_POD=$(( $LOGRATE / $(( $NUM_PROJ * $NUM_POD)) )) # per second
        LOG_PER_POD_MIN=$(( $LOG_PER_POD * 60 )) # per minute
        LOG_LINES=$(( $LOG_PER_POD_MIN * $RUNTIME ))

        cp ./template ./ocp_logtest.yaml
        sed -i "s/__PROJECTS__/$NUM_PROJ/g" ./ocp_logtest.yaml
        sed -i "s/__REPLICAS__/$NUM_POD/g" ./ocp_logtest.yaml
        sed -i "s/__NUM_LINES__/$LOG_LINES/g" ./ocp_logtest.yaml
        sed -i "s/__RATE__/$LOG_PER_POD_MIN/g" ./ocp_logtest.yaml
}

function cleanup {
        # after the run clean up and delete the logtest* projects
        echo Cleaning up the logtest projects
        projects=$(oc get projects | grep logtest | awk '{print $1}')
        for project in $projects
        do
                        echo Deleting project $project
                                oc delete project $project
                        done
}

# parse arguments
while getopts :p:l:r:t: option
do
case "${option}"
in
p) NUM_PROJ=${OPTARG};;
r) NUM_PODS=${OPTARG};;
l) LOGRATE=${OPTARG};;
t) RUNTIME=${OPTARG}};;
esac
done

# modify the template with the requested settings
templatize

# the actual run
echo Starting the test
starttime=$(date +%s%N | cut -b1-13)
#~/svt/openshift_scalability/cluster-loader.py -f ~/svt/openshift_scalability/config/ocp-logtest.yaml --kubeconfig=/home/kni/clusterconfigs/auth/kubeconfig
cd ~/svt/openshift_scalability
./cluster-loader.py -f /tmp/ocp_logtest.yaml --kubeconfig=/home/kni/clusterconfigs/auth/kubeconfig
sleep $SLEEPTIME
endtime=$(date +%s%N | cut -b1-13)

# after the run, add the annotations to the dashboards
echo Annotating the dashboards
for i in $(seq 1 7)
do
        curl -H "Content-Type: application/json" -X POST -d "{\"dashboardId\":$i,\"time\":$starttime,\"isRegion\":\"true\",\"timeEnd\":$endtime,\"tags\":[\"kafka load test\", \"uuid: $UUID\"],\"text\":\"30 minutes, $NUM_PROJ projects, $NUM_POD pods, msgs / sec total: $LOGRATE \"}" http://admin:admin@$HOSTNAME/api/annotations
done

# cleanup 
cleanup

