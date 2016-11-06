require 'date'
require 'holidays'

class BusinessDays
  include Enumerable

  def initialize(args)
    @start = args[:start]
    @region = args[:region]

    business_days
  end

  def business_days
    date = Date.civil(@start.year, @start.month, @start.day)

    p Holidays.on(date, :fr)
  end
end

BusinessDays.new(start: Date.parse('2016-05-01'), region: :fr)
