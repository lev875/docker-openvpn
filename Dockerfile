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
            libselinux

RUN mkdir /openvpn
RUN mkdir /var/log/openvpn
COPY --from=BUILD_STAGE /openvpn/build /openvpn
EXPOSE 1194/udp
VOLUME [ "/openvpn/etc/" ]
WORKDIR /openvpn/etc
ENTRYPOINT [ "/openvpn/sbin/openvpn" ]

# docker run --rm  -p 1190 -v `pwd`:/openvpn/etc --cap-add=NET_ADMIN --device /dev/net/tun:/dev/net/tun -t llnpce/openvpn:0.2  server.conf