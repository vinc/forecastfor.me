class BulletinWorker
  include Sidekiq::Worker

  def perform(str, longitude, latitude)
    key = [str, longitude, latitude].join(':')
    date = Time.zone.parse(str).to_date
    bulletin = Bulletin.new(date, longitude: longitude, latitude: latitude)
    %w(weather temperature wind).each { |method| bulletin.send(method) }
    Redis.current.setex(key, 1.hour, 'ok')
  end
end
