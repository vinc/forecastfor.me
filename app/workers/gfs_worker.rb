class GFSWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly }

  def perform
    GFS.new.download!
  end
end
