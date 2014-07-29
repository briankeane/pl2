require 'timezone'
require 'csv'
require 'active_record'

module PL
  class TimezoneFinder
      
    def initialize
      Timezone::Configure.begin do |c|
        c.username = 'playola'
      end
    end

    def find_by_zip(zip)
      latitude = ''
      longitude = ''
      CSV.foreach('lib/docs/cityzip.csv') do |line|
        if line[2] == zip
          latitude = line[3]
          longitude = line[4]
          break
        end
      end

      # return nil if not found
      if latitude == ''
        return nil
      end

      timezone = Timezone::Zone.new :latlon => [latitude.to_i, longitude.to_i]

      return timezone.active_support_time_zone
    end
  end
end