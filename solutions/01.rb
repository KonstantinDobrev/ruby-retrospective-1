class Array
  
def to_hash
  hash = {}
  self.cycle(1) { |elem| hash[elem[0]] = elem[1] }
  hash
end
	
def index_by
  hash = {}
  self.cycle(1) { |elem| hash[yield(elem)] = elem }
  hash
end
	
def subarray_count array
  self.each_cons(array.length).count(array)
end
	
def occurences_count
  hash = Hash.new(0)
  self.cycle(1) { |elem| hash[elem] = self.count(elem) }
  hash
end
	
end