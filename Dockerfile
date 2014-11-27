FROM phusion/passenger-full:0.9.14

# Set correct environment variables
ENV HOME /root

# Use baseimage-docker init process
CMD ["/sbin/my_init"]

RUN rm -f /etc/service/nginx/down
RUN rm -f /etc/service/redis/down

RUN mkdir /etc/service/sidekiq
ADD config/docker/sidekiq.sh /etc/service/sidekiq/run
RUN chmod +x /etc/service/sidekiq/run

ADD config/docker/nginx/env.conf /etc/nginx/main.d/env.conf
ADD config/docker/nginx/site.conf /etc/nginx/sites-available/default
RUN ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

ADD . /home/app/webapp
RUN chown app /home/app -R

WORKDIR /home/app/webapp
RUN su app -c "bundle install --without development:test --path vendor/bundle --deployment"
RUN su app -c "bin/rake assets:precompile RAILS_ENV=production"

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
