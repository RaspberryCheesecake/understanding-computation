class Number < Struct.new(:value)
end

class Add < Struct.new(:left, :right)
end

class Multiply < Struct.new(:left, :right)
end

puts "Horrible struct-heavy looking thing\n\n"

my_expression = Add.new(
Multiply.new(Number.new(1), Number.new(2)),
Multiply.new(Number.new(3), Number.new(4))
   )
   
puts my_expression.inspect()

puts "Now I'm getting rid of the structs\n\n"

class Number
  def to_s
    value.to_s
  end

  def inspect
    "<<#{self}>>"
  end
  def reducible?
    false
  end
end

class Add
  def to_s
    "#{left} + #{right}"
  end
  def inspect
    "<<#{self}>>"
  end
  def reducible?
    true
  end 
end

class Multiply
  def to_s
    "#{left} * #{right}"
  end
  def inspect
    "<<#{self}>>"
  end
  def reducible?
    true
  end  
end

puts my_expression.inspect()
   
puts "Number should not be reducible, Add should be reducible..."

puts Number.new(5).reducible?
puts Add.new(5, 6).reducible?

puts "Now let's see if we can reduce the Multiply and Add expressions in order to evaluate them..."

class Add
   def reduce
    if left.reducible?
      Add.new(left.reduce, right)
    elsif right.reducible?
      Add.new(left, right.reduce)
    else
      Number.new(left.value + right.value)
    end
  end
end

class Multiply
  def reduce
    if left.reducible?
      Multiply.new(left.reduce, right)
    elsif right.reducible?
      Multiply.new(right, left.reduce)
    else
      Number.new(left.value * right.value)
    end
  end
end
 

puts my_expression.inspect()
puts my_expression.reducible?
my_expression = my_expression.reduce
puts my_expression
puts my_expression.reducible?

puts "Now let's make a machine that does this automatically!"

class Machine < Struct.new(:expression)
  def step
    self.expression = expression.reduce
  end
  
  def run
    while expression.reducible?
      puts expression
      step
    end
    puts expression
  end
end

Machine.new(my_expression).run

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end
  
  def inspect
    "<<#{self}>>"
  end
  
  def reducible?
    false
  end
end


class MoreThan < Struct.new(:left, :right)
  def to_s
    "#{left} > #{right}"
  end
  
  def inspect
    "<<#{self}>>"
  end
  
  def reducible?
    true
  end
  
  def reduce
    if left.reducible?
      MoreThan.new(left.reduce, right)
    elsif right.reducible?
      MoreThan.new(left, right.reduce)
    else
      Boolean.new(left.value > right.value)
    end
  end
end

puts "Now we've made some new functions, let's try them out in a machine"

puts Machine.new(MoreThan.new(Number.new(5), Add.new(Number.new(2), Number.new(2)))).run

puts "Let's add some variables! Need to alter reduce to use an 'environment' = a hash where we store variable:value"

class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end
  
  def inspect
    "<<#{self}>>"
  end
  
  def reducible?
    true
  end
  
  def reduce(environment)
    environment[name]
  end
end


class Add
  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right)
    elsif right.reducible?
      Add.new(left, right.reduce(environment))
    else
      Number.new(left.value + right.value)
    end
  end
end


class Multiply
  def reduce(environment)
    if left.reducible?
      Multiply.new(left.reduce(environment), right)
    elsif right.reducible?
      Multiply.new(left, right.reduce(environment))
    else
      Number.new(left.value * right.value)
    end
  end
end

class MoreThan
  def reduce(environment)
    if left.reducible?
      Multiply.new(left.reduce(environment), right)
    elsif right.reducible?
      Multiply.new(left, right.reduce(environment))
    else
      Boolean.new(left.value > right.value)
    end
  end
end

# Remove the old 'Machine' class, forget about it
Object.send(:remove_const, :Machine)

#Rewrite it!

class Machine < Struct.new(:expression, :environment)
  def step
    self.expression = expression.reduce(environment)
  end
  
  def run
    while expression.reducible?
      puts expression
      step
    end
    puts expression
  end
end

puts "OK, time to do something with our fancy new environment!"
var_expression = Add.new(Variable.new(:x), Variable.new(:y))
hash_assign = {x: Number.new(3), y: Number.new(4)}
Machine.new(var_expression, hash_assign).run

puts "We're now making an Assignment class..."

class DoNothing
  def to_s
    "does nothing"
  end
  
  def inspect
    "<<#{self}>>"
  end
  
  def ==(other_statement)
    other_statement.instance_of?(DoNothing)
  end
  
  def reducible?
    false
  end
end


class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end
  
  def inspect
    "<<#{self}>>"
  end
  
  def reducible?
    true
  end
  
  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
     else
       [DoNothing.new, environment.merge({ name => expression }) ]
     end
   end
end

statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)) )
environment = {x: Number.new(2) }

puts statement, environment
puts statement.reducible?

statement, environment = statement.reduce(environment)
puts statement, environment

statement, environment = statement.reduce(environment)
puts statement, environment

statement, environment = statement.reduce(environment)
puts statement, environment

puts "OK, now we'll do the statement reduction stuff automatically too! Redefine Machine again!"
Object.send(:remove_const, :Machine)

class Machine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end
  
  def run
    while statement.reducible?
      puts "#{statement}, #{environment}"
      step
    end
    puts "#{statement}, #{environment}"
  end
end


st = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)) )
env = {x: Number.new(2) }
Machine.new(st, env).run 



