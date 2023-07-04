# FROM akorn/luarocks:lua5.4-alpine
FROM debian:latest
ENV LUA_VERSION=5.4
ENV LUA_VERSION_MINOR=6

ARG GITHUB_API_KEY

WORKDIR /tmp

# RUN apk add build-base gtk+3.0 webkit2gtk-dev curl unzip libatomic readline-dev gcompat git bsd-compat-headers
RUN apt update && apt install -y build-essential libgtk-3-dev libwebkit2gtk-4.0-dev curl unzip libatomic1 libreadline-dev git

#lua
RUN curl -fLO http://www.lua.org/ftp/lua-${LUA_VERSION}.${LUA_VERSION_MINOR}.tar.gz && \
    tar -zxf lua-${LUA_VERSION}.${LUA_VERSION_MINOR}.tar.gz && \
    cd lua-${LUA_VERSION}.${LUA_VERSION_MINOR} && \
    make linux test && \
    make install && \
    cd .. && \
    rm -rf lua-${LUA_VERSION}.${LUA_VERSION_MINOR}*

#luarocks
RUN curl -fLO https://luarocks.org/releases/luarocks-3.9.2.tar.gz && \
    tar -zxf luarocks-3.9.2.tar.gz && \
    cd luarocks-3.9.2 && \
    ./configure && \
    make build && \
    make install && \
    cd .. && \
    rm -rf luarocks-3.9.2*

WORKDIR /module

COPY . .

RUN luarocks init
RUN ./luarocks make MAKE="make -j"

CMD [ "lua" ]
