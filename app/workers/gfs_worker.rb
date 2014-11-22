class GFSWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly }

  def perform
    last_run_time = Bulletin.run_time(Time.now)
    yyyymmddhh = last_run_time.strftime('%Y%m%d%H')
    GFS.find_or_create(yyyymmddhh)
  end
end
