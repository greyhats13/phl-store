# Gunakan base image ARM64 dengan sistem operasi ringan seperti Alpine untuk target ARM64
FROM alpine:3.20.0

RUN apk --no-cache add tzdata

# Set working directory di dalam container
WORKDIR /build

# Salin binary app ke /build/app
COPY ./app /build/app

# Set binary sebagai entrypoint
CMD ["/build/app"]