# Add workday and weekday concepts to the Time class
class Time
  class << self

    # Gives the time at the end of the workday, assuming that this time falls on a
    # workday.
    # Note: It pretends that this day is a workday whether or not it really is a
    # workday.
    def end_of_workday(day)
      format = "%B %d %Y #{BusinessTime::Config.end_of_workday(day)}"
      Time.zone ? Time.zone.parse(day.strftime(format)) :
          Time.parse(day.strftime(format))
    end

    # Gives the time at the beginning of the workday, assuming that this time
    # falls on a workday.
    # Note: It pretends that this day is a workday whether or not it really is a
    # workday.
    def beginning_of_workday(day)
      format = "%B %d %Y #{BusinessTime::Config.beginning_of_workday(day)}"
      Time.zone ? Time.zone.parse(day.strftime(format)) :
          Time.parse(day.strftime(format))
    end

    # True if this time is on a workday (between 00:00:00 and 23:59:59), even if
    # this time falls outside of normal business hours.
    def workday?(day)
      Time.weekday?(day) &&
          !BusinessTime::Config.holidays.include?(day.to_date)
    end

    # True if this time falls on a weekday.
    def weekday?(day)
      BusinessTime::Config.weekdays.include? day.wday
    end

    def before_business_hours?(time)
      time < beginning_of_workday(time)
    end

    def after_business_hours?(time)
      time > end_of_workday(time)
    end

    # Rolls forward to the next beginning_of_workday
    # when the time is outside of business hours
    def roll_forward(time)

      if (Time.before_business_hours?(time) || !Time.workday?(time))
        next_business_time = Time.beginning_of_workday(time)
      elsif Time.after_business_hours?(time)
        next_business_time = Time.beginning_of_workday(time + 1.day)
      else
        next_business_time = time.clone
      end

      while !Time.workday?(next_business_time)
        next_business_time = Time.beginning_of_workday(next_business_time + 1.day)
      end

      next_business_time
    end

  end
end

class Time

  def business_time_until(to_time)

    # Make sure that we will calculate time from A to B "clockwise"
    direction = 1
    if self < to_time
      time_a = self
      time_b = to_time
    else
      time_a = to_time
      time_b = self
      direction = -1
    end
    
    # Align both times to the closest business hours
    time_a = Time::roll_forward(time_a)
    time_b = Time::roll_forward(time_b)
    
    # If same date, then calculate difference straight forward
    if time_a.to_date == time_b.to_date
      result = time_b - time_a
      return result *= direction
    end
    
    # number of each day type between the 2 dates
    monday_count = 0
    tuesday_count = 0
    wednesday_count = 0
    thursday_count = 0
    friday_count = 0
    saturday_count = 0
    sunday_count = 0
    time_a.to_date.upto(time_b.to_date-1) do |day|
      if day.wday == 1
        monday_count += 1
      elsif day.wday == 2
        tuesday_count += 1
      elsif day.wday == 3
        wednesday_count += 1
      elsif day.wday == 4
        thursday_count += 1
      elsif day.wday == 5
        friday_count += 1
      elsif day.wday == 6
        saturday_count += 1
      elsif day.wday == 7  
        sunday_count += 1
      end
    end
    
    # work hours for each day
    monday_work_hours    = Time.parse(BusinessTime::Config.end_of_workday(Time.now.beginning_of_week))       - Time.parse(BusinessTime::Config.beginning_of_workday(Time.now.beginning_of_week))
    tuesday_work_hours   = Time.parse(BusinessTime::Config.end_of_workday(Time.now.beginning_of_week+1.day)) - Time.parse(BusinessTime::Config.beginning_of_workday(Time.now.beginning_of_week+1.day))
    wednesday_work_hours = Time.parse(BusinessTime::Config.end_of_workday(Time.now.beginning_of_week+2.day)) - Time.parse(BusinessTime::Config.beginning_of_workday(Time.now.beginning_of_week+2.day))
    thursday_work_hours  = Time.parse(BusinessTime::Config.end_of_workday(Time.now.beginning_of_week+3.day)) - Time.parse(BusinessTime::Config.beginning_of_workday(Time.now.beginning_of_week+3.day))
    friday_work_hours    = Time.parse(BusinessTime::Config.end_of_workday(Time.now.beginning_of_week+4.day)) - Time.parse(BusinessTime::Config.beginning_of_workday(Time.now.beginning_of_week+4.day))
    saturday_work_hours  = Time.parse(BusinessTime::Config.end_of_workday(Time.now.beginning_of_week+5.day)) - Time.parse(BusinessTime::Config.beginning_of_workday(Time.now.beginning_of_week+5.day))
    sunday_work_hours    = Time.parse(BusinessTime::Config.end_of_workday(Time.now.beginning_of_week+6.day)) - Time.parse(BusinessTime::Config.beginning_of_workday(Time.now.beginning_of_week+6.day))
    
    # work hours between the 2 dates
    result = (monday_count * monday_work_hours) + 
              (tuesday_count * tuesday_work_hours) +
              (wednesday_count * wednesday_work_hours) +
              (thursday_count * thursday_work_hours) +
              (friday_count * friday_work_hours) +
              (saturday_count * saturday_work_hours) +
              (sunday_count * sunday_work_hours)
              
    # Make sure that sign is correct
    result *= direction
  end

end