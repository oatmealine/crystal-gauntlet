include CrystalGauntlet

module CrystalGauntlet::Songs
  extend self

  def is_custom_song(id)
    id >= 50
  end

  def is_reuploaded_song(id)
    # todo: make configurable
    id >= 5000000
  end
end
