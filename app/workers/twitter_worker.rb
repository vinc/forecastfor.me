require 'sidekiq/api'

class TwitterWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  sidekiq_options queue: :twitter, retry: false

  recurrence { minutely }

  def queued?
    Sidekiq::Queue.new(:twitter).any? do |job|
      job.klass == 'TwitterWorker'
    end
  end

  def performing?
    Sidekiq::Workers.new.select do |_, _, work|
      work['payload']['class'] == 'TwitterWorker'
    end.size > 1
  end

  def perform
    unless self.queued? || self.performing?
      TwitterBot.new.listen
    end
  end
end
