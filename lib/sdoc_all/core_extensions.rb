class Array
  def sort_by!(&block)
    replace(sort_by(&block))
  end
end

class Pathname
  def write(s)
    open('w') do |f|
      f.write(s)
    end
  end

  def hidden?
    basename.to_s =~ /^\./
  end

  def visible?
    !hidden?
  end
end

class String
  def shrink(max_length)
    if length > max_length
      "#{self[0, max_length - 1]}…"
    else
      self
    end
  end
end
