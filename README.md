## Technical Procedure for Task 0 ~ Task 7
**Task 0**
1. The latest ubuntu image 18.04.6 is used in my project, as the 18.04.5 has been moved to achive release folders.
wget http://releases.ubuntu.com/18.04/ubuntu-18.04.6-live-server-amd64.iso
2. Used the vmware workstasion as the hypervisor
3. Created a new VM named ubuntu through vSphere client(VMware ESXi 5.5)
4. VM setup with 16G mem and 2 cores CPU processor with 60G disk space allocated.

**Task 1**
1. ssh to the VM through ssh user@localhost -p 22222;
2. Change the default apt repo to local:
>#cat /etc/apt/sources.list |egrep -v "#" |egrep -v "^$"

        deb http://mirrors.163.com/ubuntu bionic main restricted
        deb http://mirrors.163.com/ubuntu bionic-updates main restricted
        deb http://mirrors.163.com/ubuntu bionic universe
        deb http://mirrors.163.com/ubuntu bionic-updates universe
        deb http://mirrors.163.com/ubuntu bionic multiverse
        deb http://mirrors.163.com/ubuntu bionic-updates multiverse
        deb http://mirrors.163.com/ubuntu bionic-backports main restricted universe multiverse
        deb http://mirrors.163.com/ubuntu bionic-security main restricted
        deb http://mirrors.163.com/ubuntu bionic-security universe
        deb http://mirrors.163.com/ubuntu bionic-security multiverse
3. Upgrade the kernel to the 18.04 latest

>#sudo apt update
>#sudo apt upgrade

**Task 2: install gitlab-ce version in the host**
1. install dependency
	>#sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
2. download gitlab package and install
	>#wget https://omnibus.gitlab.cn/ubuntu/bionic/gitlab-jh_14.10.0-jh.0_amd64.deb
	>#sudo EXTERNAL_URL="https://127.0.0.1" dpkg -i gitlab-jh_14.10.0-jh.0_amd64.deb

3. check gitlab install successful and running

	>#sudo gitlab-ctl status

    <font color=green>run: alertmanager: (pid 20916) 111s; run: log: (pid 3969) 154261s
    run: gitaly: (pid 21001) 107s; run: log: (pid 3289) 154505s
    run: gitlab-exporter: (pid 21014) 106s; run: log: (pid 3882) 154282s
    run: gitlab-kas: (pid 21269) 101s; run: log: (pid 3571) 154483s
    run: gitlab-workhorse: (pid 21337) 98s; run: log: (pid 3802) 154302s
    run: grafana: (pid 21561) 94s; run: log: (pid 4298) 154158s
    run: logrotate: (pid 21667) 89s; run: log: (pid 3209) 154519s
    run: nginx: (pid 21689) 87s; run: log: (pid 3830) 154297s
    run: node-exporter: (pid 21773) 82s; run: log: (pid 3866) 154290s
    run: postgres-exporter: (pid 21794) 81s; run: log: (pid 3990) 154255s
    run: postgresql: (pid 21979) 77s; run: log: (pid 3427) 154493s
    run: prometheus: (pid 22036) 73s; run: log: (pid 3942) 154267s
    run: puma: (pid 22182) 65s; run: log: (pid 3692) 154317s
    run: redis: (pid 22265) 62s; run: log: (pid 3243) 154511s
    run: redis-exporter: (pid 22353) 61s; run: log: (pid 3910) 154273s
    run: sidekiq: (pid 22447) 53s; run: log: (pid 3714) 154310s</font>

	>#curl http://127.0.0.1

4. access from web UI at http://127.0.0.1:28080 using root with default password  /etc/gitlab/initial_root_password, 

**Task 3: create a demo group/project in gitlab**
1. create a demo group and go-web-hello-world project in gitlab
2. add a new user w22663(my test account) and grant access to the user for project go-web-hello-world
3. login webUI using w22663, and generate sshkey and setting sshkey
4. clone the project
>#git clone git@127.0.0.1:demo/go-web-hello-world.git
5. Download go binary package, install and setup build enviroment
**Task 4: build the app and expose ($ go run) the service to 28081 port**
1. Create demo.go and build a hello world web app (listen to 8081 port)
2. check-in code into go-web-hello-world project mainline

    >#git add demo.go

    >#git commit -m "Add source code for GO Web App"

    >#git push -u origin main

3. expose port to 28081
	>#curl http://127.0.0.1:28081
	
	Go Web Hello World!
    
**Task 5: install docker**
1. >#sudo apt-get update
2. >#sudo apt-get install ca-certificates curl gnupg lsb-release
3. Add docker's official GPG key
	>#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
4. Install Docker Engine
 >#sudo apt-get update
 
 >#sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
5. Use docker to run hello world to make sure docker installation is successful
 >#sudo docker run hello-world
6. Add a new docker group for normal user to run docker cmd
 >#sudo group add docker
 >#sudo usermod -aG docker $USER
7. Add mirror registry
 >#cat /etc/docker/daemon.json 
        {
          "registry-mirrors": ["https://hub-mirror.c.163.com"]
        }
>#sudo systemctl daemon-reload
>#sudo systemctl restart docker

**Task 6: run the app in container**
1. Run the app in container

	1. compose the Dockerfile
            FROM golang:1.17.8-alpine
            LABEL maintainer="junboxu@gmail.com"
            ENV GO111MODULE=on \
                CGO_ENABLED=0 \
                GOOS=linux \
                GOARCH=amd64
            WORKDIR /go-web-hello-world
            COPY . .
            RUN go build -o demo .
            #expose the port to 8081
            EXPOSE 8081
	2. Build the docker image based on the Dockerfile
		>#sudo docker build -t w22663/go-web-hello-world:v0.1 .
	3. RUN the GO WEB app in container and expose to port 28082
 	    >#sudo docker run -d -p 28082:8081--name goapp w22663/go-web-hello-world:v0.1
        >#curl http://127.0.0.1:28082
        
    Go Web Hello World!

2. check-in Dockefile to go-web-hello-world project, copy the Dockerfile into the the local git repo direcotry
    >#cd go-web-hello-world
    
    >#git add Dockerfile
    
    >#git commit -m "Add the Dockerfile for building the docker image of GO web app" 
    
    >#git push -u origin main
    
**Task 7: push image to dockerhub**

1. tag the image with w22663/go-web-hello-world:v0.1
	>#sudo docker build -t w22663/go-web-hello-world:v0.1 .
2. push to  docker hub
    >#sudo docker login -u w22663

    >#sudo docker push w22663/go-web-hello-world:v0.1

image available on 
https://hub.docker.com/repository/docker/w22663/go-web-hello-world

**Task8-9 detail in Trouble Shooting memo**

**Task 10**
Deploy the hello world container
1. Compose a pod yaml goapp.yaml
		apiVersion: v1
        kind: Pod
        metadata:
          name: goapp
          namespace: demo
          labels: 
            app: godemo
        spec:
          containers:
            - image: w22663/go-web-hello-world:v0.1
              name: goapp
              ports:
                - containerPort: 8081
                  name: http
                  protocol: TCP
          tolerations:
              - effect: NoSchedule
                key: app
                operator: Equal
                value: web
    Deploy the goapp pod
    >#kubectl apply -f goapp.yaml 
    
2.  Compose a service yaml gowebapp.yaml
        apiVersion: v1
        kind: Service
        metadata:
          name: gowebapp
          namespace: demo
        spec:
          selector:
            app: godemo
          ports:
          - nodePort: 31080
            port: 8081
            protocol: TCP
          type: NodePort
    Deploy the gowebapp service
    >#kubectl apply -f gowebappsvr.yaml 

3. check the serive is running
>#kubectl get svc gowebapp -n demo

        NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE

        gowebapp   NodePort   10.101.108.239   <none>        8081:31080/TCP   20m

4. access the service from port 31080 
>#curl http://127.0.0.1:31080

		Go Web Hello World!

5. Detail for the pods and services

>#kubectl get services -A

        NAMESPACE              NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
        default                kubernetes                  ClusterIP   10.96.0.1        <none>        443/TCP                  46h
        demo                   gowebapp                    NodePort    10.101.108.239   <none>        8081:31080/TCP           31m
        kube-system            kube-dns                    ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   46h
        kubernetes-dashboard   dashboard-metrics-scraper   ClusterIP   10.97.126.58     <none>        8000/TCP                 46h
        kubernetes-dashboard   kubernetes-dashboard        NodePort    10.98.240.252    <none>        443:31081/TCP            46h

	>#kubectl get pods -A

        NAMESPACE              NAME                                         READY   STATUS    RESTARTS          AGE
        demo                   goapp                                        1/1     Running   0                 14m
        kube-system            calico-kube-controllers-7c845d499-9tth8      1/1     Running   34 (5h33m ago)    42h
        kube-system            calico-node-5dmx8                            1/1     Running   40 (5h34m ago)    42h
        kube-system            coredns-6d8c4cb4d-8qwg9                      1/1     Running   6 (6h24m ago)     46h
        kube-system            coredns-6d8c4cb4d-kzslc                      1/1     Running   6 (6h24m ago)     46h
        kube-system            etcd-ubuntu                                  1/1     Running   104 (6h24m ago)   46h
        kube-system            kube-apiserver-ubuntu                        1/1     Running   12 (5h34m ago)    46h
        kube-system            kube-controller-manager-ubuntu               1/1     Running   0                 4h18m
        kube-system            kube-flannel-ds-v2t8q                        1/1     Running   0                 4h11m
        kube-system            kube-proxy-r78qz                             1/1     Running   6 (6h24m ago)     46h
        kube-system            kube-scheduler-ubuntu                        1/1     Running   60 (5h46m ago)    46h
        kubernetes-dashboard   dashboard-metrics-scraper-799d786dbf-9nvxw   1/1     Running   6 (6h24m ago)     44h
        kubernetes-dashboard   kubernetes-dashboard-546cbc58cd-m96bd        1/1     Running   17 (5h33m ago)    44h

 
 





