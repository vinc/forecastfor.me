class BulletinsController < ApplicationController
  expose(:gfs) do
    params[:run_id] ? GFS.new(params[:run_id]) : GFS.last
  end

  expose(:longitude) do
    params[:longitude].try(:to_f) || request.location.longitude
  end

  expose(:latitude) do
    params[:latitude].try(:to_f) || request.location.latitude
  end

  expose(:bulletin) do
    Bulletin.new(
      gfs: gfs,
      longitude: longitude,
      latitude: latitude
    )
  end

  def show
    respond_with(bulletin)
  end
end
