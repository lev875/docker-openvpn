FROM alpine/git as BUILD_STAGE

ARG VERSION_TAG=v2.4.9
ARG MAKE_OPTS="-j4"
ARG BUILD_ARGS="\
    --prefix=/openvpn/build \
    --disable-lzo \
    --enable-iproute2 \
    --enable-selinux"
ARG BUILD_DEPENDANCIES="\
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

RUN apk add ${BUILD_DEPENDANCIES}
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
            nftables

RUN mkdir /openvpn
COPY --from=BUILD_STAGE /openvpn/build /openvpn
RUN mkdir /var/log/openvpn
COPY server.conf /openvpn/etc/
COPY nftables.conf /etc/nftables.conf
RUN mkdir -p /openvpn/etc/pki

EXPOSE 1194/udp
EXPOSE 1194/tcp

VOLUME [ "/openvpn/etc/pki" ]

WORKDIR /openvpn/etc

COPY ./start_openvpn.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start_openvpn.sh
ENTRYPOINT ["/usr/local/bin/start_openvpn.sh"]
CMD [ "--config", "/openvpn/etc/server.conf" ]

# docker run -i --device /dev/net/tun:/dev/net/tun -v `pwd`:/openvpn/etc -v /var/log/openvpn:/var/log/openvpn --entrypoint /bin/ash --cap-add NET_ADMIN -p 42272:1194/udp -t llnpce/openvpn:0.2