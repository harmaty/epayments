Gem::Specification.new do |s|
  s.name        = 'epayments'
  s.version     = '0.0.3'
  s.date        = '2014-06-09'
  s.summary     = "Ruby wrapper for Epayments"
  s.description = "Allows to transfer funds between epayments users"
  s.authors     = ["Stanislav Mekhonoshin"]
  s.email       = 'ejabberd@gmail.com'
  s.files       = ["lib/epayments/exception.rb"]
  s.homepage    = 'https://github.com/Mehonoshin/epayments'
  s.add_runtime_dependency 'mechanize'
end
