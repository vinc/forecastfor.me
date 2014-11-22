class BulletinsController < ApplicationController
  expose(:longitude) do
    params[:longitude].try(:to_f) || request.location.longitude
  end

  expose(:latitude) do
    params[:latitude].try(:to_f) || request.location.latitude
  end

  expose(:date) do
    latlon = [latitude, longitude]
    Time.zone = Timezone::Zone.new(latlon: latlon).zone
    Chronic.time_class = Time.zone
    Chronic.parse(params[:date]).try(:to_date) || Time.zone.today
  end

  expose(:bulletin) do
    Bulletin.new(date, longitude: longitude, latitude: latitude)
  end

  def show
    str = date.in_time_zone.to_s
    key = [str, longitude, latitude].join(':')
    if Redis.current.exists(key)
      respond_with(bulletin)
    else
      BulletinWorker.perform_async(str, longitude, latitude)
      render(template: 'bulletins/busy', status: :accepted)
    end
  end
end
