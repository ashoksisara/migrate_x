FROM dart:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.yaml
RUN dart pub get

COPY . .
RUN dart pub get --offline

RUN dart compile exe bin/server.dart -o bin/server

FROM scratch

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/.env.example /app/.env

EXPOSE 8080

ENTRYPOINT ["/app/bin/server"]
