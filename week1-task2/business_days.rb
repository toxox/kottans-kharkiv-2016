require 'date'
require 'holidays'

class BusinessDays
  include Enumerable

  def initialize(args)
    @start = args[:start]
    @region = args[:region]

    @business_days = business_days(@start, @region)
  end

  def each(&block)
    @business_days.each(&block)
    self
  end

  def business_days(start, region)
    result = []
    start_date = Date.civil(start.year, start.month, start.day)
    end_date = Date.today

    while start_date <= end_date
      unless start_date.wday == 6 || start_date.wday == 0
        result << start_date if Holidays.on(start_date, region).empty?
      end
      start_date += 1
    end

    result
  end
end

p BusinessDays.new(start: Date.parse('2016-05-01'), region: :fr).reject { |d| d.wday == 5 }.take(5)
