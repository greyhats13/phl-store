# Use alpine image as base image
FROM alpine:3.20.0

RUN apk --no-cache add tzdata

# Set working directory inside container
WORKDIR /build

# Copy binary dari host ke container
COPY ./app /build/app

# Run binary
CMD ["/build/app"]