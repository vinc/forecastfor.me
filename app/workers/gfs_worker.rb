class GFSWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly.minute_of_hour(0) }

  def perform
    last_run_time = Bulletin.run_time(Time.now)
    yyyymmddhh = last_run_time.strftime('%Y%m%d%H')
    GFS.find_or_create(yyyymmddhh)
  end
end
