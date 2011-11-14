require 'bigdecimal'
require 'bigdecimal/util'

class Product
  attr_reader :name, :price, :promotion
  
  def initialize name, price
    Checker.new.product_check(name, price)
    @name, @price = name, price.to_d
  end
  
  def add_promotion promotion
    @promotion = case promotion.keys.first
      when :get_one_free then GetOneFree.new(promotion)
	    when :package then Package.new(promotion)
	    when :threshold then Threshold.new(promotion)
	    else NoPromotion.new
	  end
  end

end

class NoPromotion
  
  def discount num_prods, each_price
    '0'.to_d
  end
  
  def description
    ""
  end
  
end

class GetOneFree
  
  def initialize prom_hash
    @num_free = prom_hash.values.first.to_s.to_d
  end
  
  def discount num_prods, each_price
    (num_prods / @num_free).floor * each_price
  end
  
  def description
    "(buy #{@num_free.to_i - 1}, get 1 free)"
  end
  
end

class Package
  def initialize prom_hash
    @pack_num = prom_hash.values.first.keys.first.to_s.to_d
	  @pack_perc = prom_hash.values.first.values.first.to_s.to_d
  end
  
  def discount num_prods, each_price
    pack_discount = (@pack_num * each_price) * '0.01'.to_d * @pack_perc
	  (num_prods / @pack_num).floor * pack_discount
  end
  
  def description
	  "(get #{@pack_perc.to_i}% off for every #{@pack_num.to_i})"
  end
  
end

class Threshold
  
  def initialize prom_hash
    @thresh_num = prom_hash.values.first.keys.first
	  @thresh_perc = prom_hash.values.first.values.first
  end
  
  def discount num_prods, each_price
    each_disc = each_price * '0.01'.to_d * @thresh_perc
	  num_prods < @thresh_num ? 0 : (num_prods - @thresh_num) * each_disc
  end
  
  def description
	prom_n_str = case @thresh_num.to_i
		when 1 then "1st"
		when 2 then "2nd"
		when 3 then "3rd"
			else "#{@thresh_num.to_i}th"
	end
	"(#{@thresh_perc.to_i}% off of every after the #{prom_n_str})"
  end
  
end

class NoCoupon

  def discount total
    '0'.to_d
  end
  
  def description
    ""
  end
  
end

class PercentCoupon

  def initialize name, type
    @name, @perc = name, type.values.first
  end
  
  def discount total
    total * '0.01'.to_d * @perc
  end
  
  def description
    "Coupon #{@name} - #{@perc.to_i}% off"
  end

end

class AmountCoupon

  def initialize name, type
    @name, @amount = name, type.values.first.to_s.to_d
  end
  
  def discount total
    total < @amount ? total : @amount
  end
  
  def description
	  "Coupon #{@name} - #{"%.2f" % @amount} off"
  end

end

class Checker
   
  def product_check name, price
    if name.length > 40
	    raise "Product name too long. Only 40 symbols allowed."
	  end
	  if price.to_f > 999.99 or price.to_f < 0.01
	    raise "Product price must be between 0.01 and 999.99."
	  end
  end
  
  def cart_check name, qty, products
    unless products.has_key? name
	    raise "Product not available in inventory."
	  end
	  check_qty = qty.to_s.to_d
	  if check_qty > 99 or check_qty < 0
	    raise "Product cannot be added less than 0 or more than 99 times."
	  end
  end
  
end

class Inventory
  
  attr_reader :products, :coupons
  
  def initialize
    @products, @coupons = {}, {}
  end
  
  def register name, price, promotion = {}
    if @products.has_key? name
	    raise "Product already in stock."
	  end
	  @products[name] = Product.new(name, price)
	  @products[name].add_promotion(promotion)
  end
  
  def register_coupon name, type
    if @coupons[name] != nil
	    raise "Coupon already registered."
	  end
    @coupons[name] = case type.keys.first
	    when :percent then PercentCoupon.new(name, type)
	    when :amount then AmountCoupon.new(name, type)
	  end
  end
  
  def new_cart
    Cart.new(self)
  end

end

class Cart

  attr_reader :qtities, :coupon, :inv_reff

  def initialize inventory
    @inv_reff, @qtities, @coupon = inventory, {}, NoCoupon.new
  end
  
  def add name, qty = 1
	  if @qtities[name] == nil
	    @qtities[name] = '0'.to_d
	  end
	  Checker.new.cart_check(name, @qtities[name] + qty, @inv_reff.products)
	  @qtities[name] += qty.to_s.to_d
  end
  
  def use name
    unless @inv_reff.coupons.has_key? name
	    raise "No such coupon available in inventory."
	  end
	  @coupon = @inv_reff.coupons[name]
  end
  
  def prod_discount name, qty, price
	  @inv_reff.products[name].promotion.discount(qty, price)
  end
  
  def each_total name
    @qtities[name] * @inv_reff.products[name].price
  end
  
  def without_coupon
    sum = '0'.to_d
	  @qtities.each do |name, count|
	    price = @inv_reff.products[name].price
	    sum += each_total(name) - prod_discount(name, count, price)
    end
	  sum
  end
  
  def total
    without_coupon - @coupon.discount(without_coupon)
  end
  
  def invoice
    inv = Printer.new(self)
	  inv.invoice_string
  end

end

class Printer
  
  def initialize cart
    @cart_reff = cart
  end
  
  def invoice_string
    Top + products_inf + coupon_inf + bottom
  end
  
  private
  
  Border = "+#{'-' * 48}+#{'-' * 10}+\n"
  Top = Border + "| Name#{' ' * 39}qty |#{' '* 4 }price |\n" + Border
  
  def products_inf
    str = ""
	  @cart_reff.qtities.each do |name, qty|
	  str += single_prod_inf(name, qty)
	  cond = (@cart_reff.inv_reff.products[name].promotion.description == "")
	  str += single_prod_promotion(name, qty)
	  end
	  str
  end
  
  def single_prod_inf name, qty
    str = "| #{name + ' ' * (42 - name.length)}"
	  str += "#{' ' * (4 - qty.to_i.to_s.length)}#{qty.to_i} | "
	  prod_price = "%.2f" % @cart_reff.each_total(name)
	  str += "#{' ' * (8 - prod_price.length)}#{prod_price} |\n"
  end
  
  def single_prod_promotion name, qty
    desc = @cart_reff.inv_reff.products[name].promotion.description
	  prod_price = @cart_reff.inv_reff.products[name].price
      discount = @cart_reff.prod_discount(name, qty, prod_price)
	  disc_val = "%.2f" % -discount
    str = "|   #{desc}#{' ' * (45 - desc.length)}|"
	  str += "#{' ' * (9 - disc_val.length)}#{disc_val} |\n"
	  desc == "" ? "" : str
  end
  
  def coupon_inf
    descr = @cart_reff.coupon.description
	  if descr == ""
	    return ""
	  end
    str = "| #{descr}#{' ' * (47 - descr.length)}|"
	  dsc = "%.2f" % (@cart_reff.total - @cart_reff.without_coupon)
	  str += "#{' ' * (9 - dsc.length)}#{dsc} |\n"
  end
  
  def bottom
	  str = Border + "| TOTAL#{' ' * 42}|" 
	  tot = "%.2f" % @cart_reff.total
	  str += "#{' ' * (9 - tot.length)}#{tot} |\n" + Border
  end
  
end