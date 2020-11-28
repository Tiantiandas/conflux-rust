FROM rust:1.47.0 as builder

ARG CMAKE_VERSION=3.19.1
RUN cd /usr/local/ && wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz -q -O- | tar zx 

COPY . /home/conflux-rust
RUN export PATH=/usr/local/cmake-${CMAKE_VERSION}-Linux-x86_64/bin:$PATH \
    && cd /home/conflux-rust \
    && cargo build --release

RUN mkdir -p /out/usr/lib/x86_64-linux-gnu /out/lib/x86_64-linux-gnu /out/lib64\
    && cd /usr/lib/x86_64-linux-gnu \
    && cp -H libssl.so.1.1 libcrypto.so.1.1 /out/usr/lib/x86_64-linux-gnu \
    && cd /lib/x86_64-linux-gnu \
    && cp -H libpthread.so.0 libdl.so.2 librt.so.1 libgcc_s.so.1 libc.so.6 libm.so.6 /out/lib/x86_64-linux-gnu \
    && cd /lib64 \
    && cp -H ld-linux-x86-64.so.2 /out/lib64/

FROM debian:stretch
MAINTAINER ZHE <me@zhegao.me>

WORKDIR /workspace
VOLUME /workspace
EXPOSE 12537/tcp
ENTRYPOINT ["/app/conflux"]

COPY --from=builder /out/usr/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /out/lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
COPY --from=builder /out/lib64/* /lib64/
COPY --from=builder /home/conflux-rust/run/* /workspace/
COPY --from=builder /home/conflux-rust/target/release/conflux /app/
