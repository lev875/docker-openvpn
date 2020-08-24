FROM alpine/git as BUILD_STAGE

ARG VERSION_TAG=v2.4.9
ARG MAKE_OPTS="-j4"
ARG BUILD_ARGS="\
                --prefix=/openvpn/build \
                --disable-lzo \
                --enable-iproute2 \
                --enable-selinux"
ARG DEPENDANCIES="\
                    linux-headers \
                    g++ \
                    make \
                    libtool \
                    automake \
                    autoconf \
                    openssl-dev \
                    lz4-dev \
                    linux-pam-dev \
                    libselinux-dev"

RUN apk add ${DEPENDANCIES}
RUN mkdir /openvpn/{src,build} -p
WORKDIR /openvpn/src
RUN git clone https://github.com/OpenVPN/openvpn.git --branch ${VERSION_TAG} --depth 1 .
RUN autoreconf -i -v -f
RUN ./configure ${BUILD_ARGS}
RUN make ${MAKE_OPTS}
RUN make install

FROM alpine

RUN apk add \
            openssl \
            lz4-dev \
            linux-pam \
            libselinux \
            awall \
            openrc

RUN mkdir /openvpn
RUN mkdir /var/log/openvpn
COPY --from=BUILD_STAGE /openvpn/build /openvpn
COPY awall /etc/awall
RUN awall enable openvpn
RUN awall enable main
RUN awall translate
RUN rc-update add iptables
RUN rc-update add ipset 
EXPOSE 1194/udp
EXPOSE 1194/tcp
VOLUME [ "/openvpn/etc/" ]
WORKDIR /openvpn/etc
ENTRYPOINT [ "/openvpn/sbin/openvpn" ]

# docker run -i --device /dev/net/tun:/dev/net/tun -v `pwd`:/openvpn/etc -v /var/log/openvpn:/var/log/openvpn --entrypoint /bin/ash --cap-add NET_ADMIN -p 42272:1194/udp -t llnpce/openvpn:0.2