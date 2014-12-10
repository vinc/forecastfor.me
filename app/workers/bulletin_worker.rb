class BulletinWorker
  include Sidekiq::Worker

  def perform(str, longitude, latitude)
    key = [str, longitude, latitude].join(':')

    # Acquire lock
    return false if Redis.current.exists("#{key}:lock")
    Redis.current.setex("#{key}:lock", 1.minute, 'busy')

    date = Time.zone.parse(str).to_date
    bulletin = Bulletin.new(date, longitude: longitude, latitude: latitude)
    bulletin.to_json # Build redis cache
    Redis.current.setex(key, 1.hour, 'done')
  end
end
