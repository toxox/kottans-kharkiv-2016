module Ebuberable
  def map(&block)
    return to_enum(:each) unless block_given?

    result = []
    each do |element|
      result << block.call(element)
    end
    result
  end

  def select(&block)
    return to_enum(:each) unless block_given?

    result = []
    each do |element|
      result << element if block.call(element)
    end
    result
  end

  def reject(&block)
    return to_enum(:each) unless block_given?

    result = []
    each do |element|
      result << element unless block.call(element)
    end
    result
  end

  def grep(pattern, &block)
    #WIP
  end

  def all?(&block)
    return to_enum(:each) unless block_given?

    result = true
    each do |element|
      if block.call(element)
        next
      else
        result = false
        break
      end
      #result = false element unless block.call(element)
    end
    result
  end

  def reduce(accumulator = 0, &block)
    return to_enum(:each) unless block_given?

    each do |element|
      accumulator = block.call(accumulator, element)
    end

    accumulator
  end
end

class MyArray
  include Ebuberable

  def initialize(*items)
    @items = items.flatten
  end

  def each(&block)
    @items.each(&block)
    self
  end
end

test = MyArray.new(1,2,3,4,5)

puts "Map"
p test.map {|item| item * 2}

puts "Select"
p test.select {|item| item.even?}

puts "Reject"
p reject_test = test.reject {|item| item.even?}

puts "All"
all_test = test.all? {|item| item < 6}
p all_test

puts "Reduce"
p test.reduce(0 ){|sum, item| sum += item}
