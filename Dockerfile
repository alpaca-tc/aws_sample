FROM ruby:2.5.0-alpine

ENV SECRET_KEY_BASE de0ec9f23e46070ff1cd2bb35c29fe6f23edfde4c5fffa23ded1f04bb59d13611bd6dbf02b7e04461000a20fa0b8f565f28f600006a7c1002f2cef555cfcb699
ENV RAILS_ENV production
ENV LANG C.UTF-8
ENV BIN_DIR /usr/bin
ENV APP_DIR /app
ENV DISABLE_DATABASE_ENVIRONMENT_CHECK 1
ENV PATH $PATH:$BIN_DIR

RUN addgroup -S app
RUN adduser -S -g app app
RUN mkdir -p $APP_DIR $BIN_DIR
RUN chown app:app $APP_DIR $BIN_DIR

EXPOSE 3000
WORKDIR $APP_DIR

RUN apk --update --no-cache add mysql-dev nodejs tzdata openssl bash build-base
RUN apk --update --no-cache add sqlite-dev
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
RUN rm /usr/lib/libmysqld*

USER app:app

COPY --chown=app:app . $APP_DIR

RUN echo 'gem: --no-document' > ~/.gemrc
RUN bundle install --path .bundle

CMD /app/bin/rails server --port 3000 --binding 0.0.0.0
