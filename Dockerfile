FROM golang:1.14.9-alpine
LABEL maintainer="junboxu@gmail.com"
RUN mkdir /go-web-hello-world
ADD go-web-hello-world/demo /go-web-hello-world
WORKDIR /go-web-hello-world
#RUN the GO WEB app
CMD ["./demo"]
#expose the port to 28082
EXPOSE 28082
