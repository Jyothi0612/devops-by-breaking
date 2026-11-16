FROM busybox:1.37
LABEL dbb.lab=sec-01
WORKDIR /app
COPY . /app
RUN rm -f /app/.env
CMD ["sh", "/app/app.sh"]
