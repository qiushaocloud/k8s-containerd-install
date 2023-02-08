MY_HOSTNAME=`hostname`

kubectl label node $MY_HOSTNAME ingress=true
