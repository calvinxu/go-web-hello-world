## Trouble Shooting Memo for Kubernetes ##

### Installation
**1. Swap**

The first step is to disable swap and setting on startup in /etc/fstab, if not kubelet may fail to startup
> #swapoff -a && sed -i ‘/ swap / s/^/#/’ /etc/fstab

Basically what we need to do this when running nodes with (traditional to-disk mode) swap, we might lose isolation properties that make sharing machines viable, in such case we have no predictability around performance or latency or IO.

But some disussion also mention to enable swap in future feature of Kubelet/Kubernetes. If really want swap to enabled, workaround can be used following by:
start kubelet with --fail-swap-on=false
add swap to  nodes containers which do not specify a memory requirement will then by default be able to use all of the machine memory, including swap.

**2.Cgroup driver**

If cgroupDriver field is not set under KubeletConfiguration, kubeadm will default it to be systemd, while at the same time if cgroupdriver is not set for docker, the kubelet start will be failed. And if the cgroupdriver setting are set to be "cgroupfs" for kebulet and docker, although docker and kubelet can be run, but docker will fail to run the container. Only when both cgroupdrive are set to "systemd", docker can run container succesfully and kubelet run normally.


when the cgroupdriver is mismatch between kubelet and docker, the kubelet process fail to startup. By checking the log of kubelet service 
>#systemctl status kubelet
>
and 
>#journalctl -xefu kubelet

it indicated that the mismatch of cgroup driver:

<font color=red>*Apr 29 01:32:04 ubuntu kubelet[28457]: E0429 01:32:04.437419   28457 server.go:302] "Failed to run kubelet" err="failed to run Kubelet: misconfiguration: 
kubelet cgroup driver: \"systemd\" is different from docker cgroup driver: \"cgroupfs\""
"exec-opts": ["native.cgroupdriver=systemd"],*</font>

so next we just need to set the cgroupdriver to systemd, this issue can be solved，setting docker cgroup driver to systemd
>#cat /etc/docker/daemon.json 
		
        {
        "exec-opts": ["native.cgroupdriver=systemd"],
        "log-driver": "json-file",
        "log-opts": {
        "max-size": "100m"
        },
        "storage-driver": "overlay2"
        }
        {
         "registry-mirrors": ["http://hub-mirror.c.163.com", "https://registry.docker-cn.com"]
        }

also, set the option "--cgroup-driver=systemd" to KUBELET_KUBEADM_ARGS in kubeadm-flags.env

        KUBELET_KUBEADM_ARGS="--cgroup-driver=systemd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.6"

>#sudo systemctl daemon-reload
>#sudo systemctl restart docker

>#systemctl status kubelet

        ?.kubelet.service - kubelet: The Kubernetes Node Agent
           Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
          Drop-In: /etc/systemd/system/kubelet.service.d
                   ?..10-kubeadm.conf
           Active: active (running) since Fri 2022-04-29 03:41:02 UTC; 4h 37min ago
             Docs: https://kubernetes.io/docs/home/
         Main PID: 14963 (kubelet)
            Tasks: 29 (limit: 4915)
           CGroup: /system.slice/kubelet.service
                   ?..14963 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=cgroupfs --config=/var/lib/kubelet/config.yaml --cgroup-dri

        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.995 [INFO][30696] ipam.go 1213: Successfully claimed IPs: [172.16.243.245/26] block=172.16.243.192/26 handle="k8s-pod-network.6bd864a22f064096b6c4ae179768bd
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.995 [INFO][30696] ipam.go 844: Auto-assigned 1 out of 1 IPv4s: [172.16.243.245/26] handle="k8s-pod-network.6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e
        Apr 29 07:44:00 ubuntu kubelet[14963]: time="2022-04-29T07:43:59Z" level=info msg="Released host-wide IPAM lock." source="ipam_plugin.go:377"
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.996 [INFO][30696] ipam_plugin.go 284: Calico CNI IPAM assigned addresses IPv4=[172.16.243.245/26] IPv6=[] ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd8
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.999 [INFO][30672] k8s.go 382: Populated endpoint ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="demo" Pod="goapp"
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.999 [INFO][30672] k8s.go 383: Calico CNI using IPs: [172.16.243.245/32] ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Names
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.999 [INFO][30672] dataplane_linux.go 68: Setting the host side veth name to calidc62b38edd0 ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:44:00.001 [INFO][30672] dataplane_linux.go 453: Disabling IPv4 forwarding ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:44:00.029 [INFO][30672] k8s.go 410: Added Mac, interface name, and active container ID to endpoint ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:44:00.080 [INFO][30672] k8s.go 484: Wrote updated endpoint to datastore ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="
        
>#journalctl -xefu kubelet 

        Apr 29 07:44:00 ubuntu kubelet[14963]: time="2022-04-29T07:43:59Z" level=info msg="Released host-wide IPAM lock." source="ipam_plugin.go:377"
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.996 [INFO][30696] ipam_plugin.go 284: Calico CNI IPAM assigned addresses IPv4=[172.16.243.245/26] IPv6=[] ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" HandleID="k8s-pod-network.6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Workload="ubuntu-k8s-goapp-eth0"
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.999 [INFO][30672] k8s.go 382: Populated endpoint ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="demo" Pod="goapp" WorkloadEndpoint="ubuntu-k8s-goapp-eth0" endpoint=&v3.WorkloadEndpoint{TypeMeta:v1.TypeMeta{Kind:"WorkloadEndpoint", APIVersion:"projectcalico.org/v3"}, ObjectMeta:v1.ObjectMeta{Name:"ubuntu-k8s-goapp-eth0", GenerateName:"", Namespace:"demo", SelfLink:"", UID:"a176721c-5546-4ac2-9fda-be7c477b1e23", ResourceVersion:"188703", Generation:0, CreationTimestamp:time.Date(2022, time.April, 29, 7, 43, 58, 0, time.Local), DeletionTimestamp:<nil>, DeletionGracePeriodSeconds:(*int64)(nil), Labels:map[string]string{"app":"godemo", "projectcalico.org/namespace":"demo", "projectcalico.org/orchestrator":"k8s", "projectcalico.org/serviceaccount":"default"}, Annotations:map[string]string(nil), OwnerReferences:[]v1.OwnerReference(nil), Finalizers:[]string(nil), ClusterName:"", ManagedFields:[]v1.ManagedFieldsEntry(nil)}, Spec:v3.WorkloadEndpointSpec{Orchestrator:"k8s", Workload:"", Node:"ubuntu", ContainerID:"", Pod:"goapp", Endpoint:"eth0", ServiceAccountName:"default", IPNetworks:[]string{"172.16.243.245/32"}, IPNATs:[]v3.IPNAT(nil), IPv4Gateway:"", IPv6Gateway:"", Profiles:[]string{"kns.demo", "ksa.demo.default"}, InterfaceName:"calidc62b38edd0", MAC:"", Ports:[]v3.WorkloadEndpointPort{v3.WorkloadEndpointPort{Name:"http", Protocol:numorstring.Protocol{Type:1, NumVal:0x0, StrVal:"TCP"}, Port:0x1f91, HostPort:0x0, HostIP:""}}}}
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.999 [INFO][30672] k8s.go 383: Calico CNI using IPs: [172.16.243.245/32] ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="demo" Pod="goapp" WorkloadEndpoint="ubuntu-k8s-goapp-eth0"
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:43:59.999 [INFO][30672] dataplane_linux.go 68: Setting the host side veth name to calidc62b38edd0 ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="demo" Pod="goapp" WorkloadEndpoint="ubuntu-k8s-goapp-eth0"
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:44:00.001 [INFO][30672] dataplane_linux.go 453: Disabling IPv4 forwarding ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="demo" Pod="goapp" WorkloadEndpoint="ubuntu-k8s-goapp-eth0"
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:44:00.029 [INFO][30672] k8s.go 410: Added Mac, interface name, and active container ID to endpoint ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="demo" Pod="goapp" WorkloadEndpoint="ubuntu-k8s-goapp-eth0" endpoint=&v3.WorkloadEndpoint{TypeMeta:v1.TypeMeta{Kind:"WorkloadEndpoint", APIVersion:"projectcalico.org/v3"}, ObjectMeta:v1.ObjectMeta{Name:"ubuntu-k8s-goapp-eth0", GenerateName:"", Namespace:"demo", SelfLink:"", UID:"a176721c-5546-4ac2-9fda-be7c477b1e23", ResourceVersion:"188703", Generation:0, CreationTimestamp:time.Date(2022, time.April, 29, 7, 43, 58, 0, time.Local), DeletionTimestamp:<nil>, DeletionGracePeriodSeconds:(*int64)(nil), Labels:map[string]string{"app":"godemo", "projectcalico.org/namespace":"demo", "projectcalico.org/orchestrator":"k8s", "projectcalico.org/serviceaccount":"default"}, Annotations:map[string]string(nil), OwnerReferences:[]v1.OwnerReference(nil), Finalizers:[]string(nil), ClusterName:"", ManagedFields:[]v1.ManagedFieldsEntry(nil)}, Spec:v3.WorkloadEndpointSpec{Orchestrator:"k8s", Workload:"", Node:"ubuntu", ContainerID:"6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632", Pod:"goapp", Endpoint:"eth0", ServiceAccountName:"default", IPNetworks:[]string{"172.16.243.245/32"}, IPNATs:[]v3.IPNAT(nil), IPv4Gateway:"", IPv6Gateway:"", Profiles:[]string{"kns.demo", "ksa.demo.default"}, InterfaceName:"calidc62b38edd0", MAC:"16:c7:b9:52:64:25", Ports:[]v3.WorkloadEndpointPort{v3.WorkloadEndpointPort{Name:"http", Protocol:numorstring.Protocol{Type:1, NumVal:0x0, StrVal:"TCP"}, Port:0x1f91, HostPort:0x0, HostIP:""}}}}
        Apr 29 07:44:00 ubuntu kubelet[14963]: 2022-04-29 07:44:00.080 [INFO][30672] k8s.go 484: Wrote updated endpoint to datastore ContainerID="6bd864a22f064096b6c4ae179768bdfa74fd87bdcefe3568e6e9b761e03e0632" Namespace="demo" Pod="goapp" WorkloadEndpoint="ubuntu-k8s-goapp-eth0"

**3. dashoboard export nodeport **

Inorder to access the dashoboard UI from other host, need to change from ClusterIP to Nodeport, and expose the necessary port 31081
  
>#kubectl edit service/kubernetes-dashboard -n kubernetes-dashboard
>
    ports:
      - nodePort: 31081
        port: 443
        protocol: TCP
        targetPort: 8443
      selector:
        k8s-app: kubernetes-dashboard
      sessionAffinity: None
      type: NodePort

once service re-loaded, we can access the dashboard UI through the port 31081 exposed

	>#kubectl get svc kubernetes-dashboard -n kubernetes-dashboard

        *NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE*

        *kubernetes-dashboard   NodePort   10.98.240.252   <none>        443:31081/TCP   44h*

### Pod status issue
**4. Taint issue**

When deploy the GO WEB pod to cluster, it always failed to run and pending on "Containercreating" status, after  checking the log by 
	>#kubectl describe pod goapp -n demo
below erro logs can be seen

*Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  <font color=red>Warning  FailedScheduling  75s (x3 over 2m31s)  default-scheduler  0/1 nodes are available: 1 node(s) had taint {node.kubernetes.io/unreachable: }, that the pod didn't tolerate.*</font>
  
In such case, I found the this related to the single cluster node set, and the master node(in my case the only one single node) is already tainted by the Kubernetes installation so that no user pods land on them until intentionally configured by the user to be placed on master nodes by adding tolerations for the taints, and this can be done by adding  tolerations for in the pod. It is by default cluster will not schedule Pods on the control-plane node for security reasons. If want to be able to schedule Pods on the control-plane node, for example for a single-machine Kubernetes cluster for development, run:
>#kubectl taint nodes --all node-role.kubernetes.io/master-

>#kubectl taint nodes ubuntu app=web:NoSchedule

This will remove the node-role.kubernetes.io/master taint from any nodes that have it, including the control-plane node, meaning that the scheduler will then be able to schedule Pods everywhere.

Add also need to add one tolerations field to the Pod yaml.

		tolerations:
              - effect: NoSchedule
                key: app
                operator: Equal
                value: web

>#kubectl get nodes -o=custom-columns=NodeName:.metadata.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect

        *NodeName   TaintKey   TaintValue   TaintEffect
        ubuntu     app        web          NoSchedule*


**5. Pod with CreateContainerConfigError status**

sometimes it is observed one pod with CreateContainerConfigError status, need to check the pod with 
>#kubectl describe pod calico-node-5dmx8  -n kube-system
>#kubectl logs calico-node-5dmx8  -n kube-system

and eventually it restarted automatically with normal running status.

<font color=green>*2022-04-29 02:33:48.773 [INFO][109] monitor-addresses/autodetection_methods.go 103: Using autodetected IPv4 address on interface ens160: 192.168.1.101/24
2022-04-29 02:34:16.831 [INFO][103] felix/summary.go 100: Summarising 7 dataplane reconciliation loops over 1m2.9s: avg=3ms longest=5ms (resync-ipsets-v4)
2022-04-29 02:34:48.775 [INFO][109] monitor-addresses/autodetection_methods.go 103: Using autodetected IPv4 address on interface ens160: 192.168.1.101/24
2022-04-29 02:35:17.647 [INFO][103] felix/summary.go 100: Summarising 8 dataplane reconciliation loops over 1m0.8s: avg=5ms longest=13ms (resync-mangle-v4,resync-nat-v4,resync-raw-v4)
2022-04-29 02:35:48.778 [INFO][109] monitor-addresses/autodetection_methods.go 103: Using autodetected IPv4 address on interface ens160: 192.168.1.101/24
2022-04-29 02:36:24.166 [INFO][103] felix/summary.go 100: Summarising 10 dataplane reconciliation loops over 1m6.5s: avg=5ms longest=14ms (resync-mangle-v4,resync-nat-v4)
2022-04-29 02:36:48.780 [INFO][109] monitor-addresses/autodetection_methods.go 103: Using autodetected IPv4 address on interface ens160: 192.168.1.101/24
2022-04-29 02:37:27.290 [INFO][103] felix/summary.go 100: Summarising 10 dataplane reconciliation loops over 1m3.1s: avg=5ms longest=11ms (resync-mangle-v4,resync-nat-v4)
2022-04-29 02:37:48.781 [INFO][109] monitor-addresses/autodetection_methods.go 103: Using autodetected IPv4 address on interface ens160: 192.168.1.101/24
2022-04-29 02:38:30.442 [INFO][103] felix/summary.go 100: Summarising 6 dataplane reconciliation loops over 1m3.2s: avg=3ms longest=3ms (resync-ipsets-v4)
2022-04-29 02:38:48.783 [INFO][109] monitor-addresses/autodetection_methods.go 103: Using autodetected IPv4 address on interface ens160: 192.168.1.101/24*</font>

while in the pod describe logs, the liveness and ready check with some warning message as below

>#kubectl describe pod calico-node-5dmx8  -n kube-system |grep failed
  
<font color=red>  *Warning  Unhealthy  50m (x6 over 53m)   kubelet  Liveness probe failed: command "/bin/calico-node -felix-live -bird-live" timed out
  Warning  Unhealthy  25m (x41 over 53m)  kubelet  Readiness probe failed: command "/bin/calico-node -felix-ready -bird-ready" timed out
  Warning  Unhealthy  17m (x21 over 39m)  kubelet  (combined from similar events): Liveness probe failed: command "/bin/calico-node -felix-live -bird-live" timed out*</font>
 
A side note, just to add here when the CrashLoopBackOff status of flannel pod issue resolved, the above issue was also gone.

**6.Pod with CrashLoopBackOff status**

The CrashLoopBackOff error can be caused by a variety of issues, including:
1. Insufficient resources—lack of resources prevents the container from loading
2. Locked file—a file was already locked by another container
3. Locked database—the database is being used and locked by other pods
4. Failed reference—reference to scripts or binaries that are not present on the container
5. Setup error—an issue with the init-container setup in Kubernetes
6. Config loading error—a server cannot load the configuration file
7. Misconfigurations—a general file system misconfiguration
8. Connection issues—DNS or kube-DNS is not able to connect to a third-party service
9. Deploying failed services—an attempt to deploy services/applications that have already failed (e.g. due to a lack of access to other services)

basically, the Diagnosis method used are 
1. Check for “Back Off Restarting Failed Container”
2. Check Logs From Previous Container Instance
3. Check Deployment Logs
4. Bashing Into CrashLoop Container

in this case, I used the first two methods and get the issue resolved evntually:

With the flnner network plugin, the pod is always in CrashLoopBackOff status, by checking the event and 
log

> #kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'

        NAMESPACE     LAST SEEN   TYPE      REASON                    OBJECT                               MESSAGE

        kube-system   60m         Warning   BackOff                   pod/kube-flannel-ds-9dngv            Back-off restarting failed container

        kube-system   60m         Normal    Scheduled                 pod/kube-flannel-ds-57lm6            Successfully assigned kube-system/kube-flannel-ds-57lm6 to ubuntu

        kube-system   60m         Normal    SuccessfulCreate          daemonset/kube-flannel-ds            Created pod: kube-flannel-ds-57lm6

        kube-system   60m         Normal    Pulled                    pod/kube-flannel-ds-57lm6            Container image "rancher/mirrored-flannelcni-flannel-cni-plugin:v1.0.1" already present on machine

        kube-system   60m         Normal    Created                   pod/kube-flannel-ds-57lm6            Created container install-cni-plugin

        kube-system   60m         Normal    Started                   pod/kube-flannel-ds-57lm6            Started container install-cni-plugin

        kube-system   60m         Normal    Created                   pod/kube-flannel-ds-57lm6            Created container install-cni

        kube-system   60m         Normal    Pulled                    pod/kube-flannel-ds-57lm6            Container image "rancher/mirrored-flannelcni-flannel:v0.17.0" already present on machine

        kube-system   58m         Normal    Pulled                    pod/kube-flannel-ds-57lm6            Container image "rancher/mirrored-flannelcni-flannel:v0.17.0" already present on machine

        kube-system   60m         Normal    Started                   pod/kube-flannel-ds-57lm6            Started container install-cni

        kube-system   59m         Normal    Started                   pod/kube-flannel-ds-57lm6            Started container kube-flannel

        kube-system   59m         Normal    Created                   pod/kube-flannel-ds-57lm6            Created container kube-flannel

        kube-system   35m         Warning   BackOff                   pod/kube-flannel-ds-57lm6            Back-off restarting failed container


>#kubectl logs kube-flannel-ds-57lm6    -n kube-system 

*I0429 03:19:34.304252       1 main.go:205] CLI flags config: {etcdEndpoints:http://127.0.0.1:4001,http://127.0.0.1:2379 etcdPrefix:/coreos.com/network etcdKeyfile: etcdCertfile: etcdCAFile: etcdUsername: etcdPassword: version:false kubeSubnetMgr:true kubeApiUrl: kubeAnnotationPrefix:flannel.alpha.coreos.com kubeConfigFile: iface:[] ifaceRegex:[] ipMasq:true subnetFile:/run/flannel/subnet.env publicIP: publicIPv6: subnetLeaseRenewMargin:60 healthzIP:0.0.0.0 healthzPort:0 iptablesResyncSeconds:5 iptablesForwardRules:true netConfPath:/etc/kube-flannel/net-conf.json setNodeNetworkUnavailable:true}
W0429 03:19:34.304392       1 client_config.go:614] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0429 03:19:34.603692       1 kube.go:120] Waiting 10m0s for node controller to sync
I0429 03:19:34.603833       1 kube.go:378] Starting kube subnet manager
I0429 03:19:35.603951       1 kube.go:127] Node controller sync successful
I0429 03:19:35.604011       1 main.go:225] Created subnet manager: Kubernetes Subnet Manager - ubuntu
I0429 03:19:35.604023       1 main.go:228] Installing signal handlers
I0429 03:19:35.604245       1 main.go:454] Found network config - Backend type: vxlan
I0429 03:19:35.604307       1 match.go:189] Determining IP address of default interface
I0429 03:19:35.605138       1 match.go:242] Using interface with name ens160 and address 192.168.1.101
I0429 03:19:35.605191       1 match.go:264] Defaulting external address to interface address (192.168.1.101)
I0429 03:19:35.605347       1 vxlan.go:138] VXLAN config: VNI=1 Port=0 GBP=false Learning=false DirectRouting=false
<font color=red>E0429 03:19:35.605875       1 main.go:317] Error registering network: failed to acquire lease: node "ubuntu" pod cidr not assigned
I0429 03:19:35.605958       1 main.go:434] Stopping shutdownHandler* </font>

It is indicated in the kubeadm docs:There are pod network implementations where the master also plays a role in allocating a set of network address space for each node. When using flannel as the pod network (described in step 3), specify --pod-network-cidr=10.244.0.0/16. This is not required for any other networks besides Flannel.

>so with following action steps:

>edit /etc/kubernetes/manifests/kube-controller-manager.yaml, at command ,add

        --allocate-node-cidrs=true
        --cluster-cidr=10.244.0.0/16
then,reload kubelet
    >#sudo systemctl restart kubelet

    >#kubectl get pods -A

        NAMESPACE              NAME                                         READY   STATUS    RESTARTS         AGE

        demo                   goapp                                        1/1     Running   6 (135m ago)     24h

        kube-system            calico-kube-controllers-7c845d499-9tth8      1/1     Running   34 (84m ago)     38h

        kube-system            calico-node-5dmx8                            1/1     Running   40 (85m ago)     38h

        kube-system            coredns-6d8c4cb4d-8qwg9                      1/1     Running   6 (135m ago)     42h

        kube-system            coredns-6d8c4cb4d-kzslc                      1/1     Running   6 (135m ago)     42h

        kube-system            etcd-ubuntu                                  1/1     Running   104 (135m ago)   42h

        kube-system            kube-apiserver-ubuntu                        1/1     Running   12 (84m ago)     42h

        kube-system            kube-controller-manager-ubuntu               1/1     Running   0                9m18s

        kube-system            kube-flannel-ds-v2t8q                        1/1     Running   0                2m30s

        kube-system            kube-proxy-r78qz                             1/1     Running   6 (135m ago)     42h

        kube-system            kube-scheduler-ubuntu                        1/1     Running   60 (96m ago)     42h

        kubernetes-dashboard   dashboard-metrics-scraper-799d786dbf-9nvxw   1/1     Running   6 (135m ago)     40h

        kubernetes-dashboard   kubernetes-dashboard-546cbc58cd-m96bd        1/1     Running   17 (84m ago)     40h





