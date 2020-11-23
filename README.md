# kafka_testing

kafka_test.sh is a simple shell script that works together with https://github.com/openshift/svt/blob/master/openshift_scalability/content/logtest/ocp_logtest-README.md

It will templatize the config file and start the test, by default for 30 minutes. 
After that time (+5 minutes to let things settle) it will clean up the created projects and pods and also annotate dittybopper dashboards. 

The call to the script looks like this:
```
./kafka_test -p <number of projects> -r <number of replicas> -l <lograte> -t runtime
```

The defaults are set to 10 projects, 10 pods / project (this is the number of replicas), a lograte of 15000 messages / sec and a runtime of 30 minutes. 
