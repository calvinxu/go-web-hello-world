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

#RUN the GO WEB app
CMD ["./demo"]
