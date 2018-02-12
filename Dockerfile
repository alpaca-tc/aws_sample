FROM ruby:2.5.0-alpine

ENV LANG C.UTF-8
ENV BIN_DIR /usr/bin
ENV APP_DIR /app
ENV PATH $PATH:$BIN_DIR

EXPOSE 3000
WORKDIR $APP_DIR

RUN addgroup -S app
RUN adduser -S -g app app
RUN mkdir -p $APP_DIR $BIN_DIR
RUN chown app:app $APP_DIR $BIN_DIR

# Ruby/Rails
RUN apk --update --no-cache add mysql-dev tzdata openssl bash build-base
RUN rm /usr/lib/libmysqld*

RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

USER app:app

# Install ruby dependencies
COPY --chown=app:app Gemfile $APP_DIR
COPY --chown=app:app Gemfile.lock $APP_DIR

RUN echo 'gem: --no-document --no-ri' > ~/.gemrc
RUN cd $APP_DIR && bundle install --path .bundle --jobs 5

COPY --chown=app:app . $APP_DIR

CMD $APP_DIR/bin/rails server --port 3000 --binding 0.0.0.0
