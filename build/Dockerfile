FROM ubuntu:16.04

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y vim tmux curl tcpdump jq
RUN apt-get install -y iputils-ping iproute2

ADD ./entry.sh /entry.sh
RUN chmod 0755 /entry.sh
ENTRYPOINT ["/entry.sh"]
