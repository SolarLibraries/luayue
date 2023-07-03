FROM akorn/luarocks:lua5.4-alpine
ENV LUA_VERSION=5.4

WORKDIR /tmp

RUN apk add gtk+3.0 webkit2gtk-dev curl unzip libatomic readline-dev gcompat

WORKDIR /app

COPY . .

RUN luarocks --verbose init
RUN ./luarocks make

ENV LUA_PATH="lua_modules/share/lua/${LUA_VERSION}/?.lua;lua_modules/share/lua/${LUA_VERSION}/?/init.lua"
ENV LUA_CPATH="lua_modules/lib/lua/${LUA_VERSION}/?.so"

CMD [ "lua", "test.lua" ]
