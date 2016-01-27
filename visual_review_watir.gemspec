Gem::Specification.new do |s|
  s.name        = 'visual_review_watir'
  s.version     = '0.0.0'
  s.date        = '2015-12-17'
  s.summary     = 'Visual Review + Watir WebDriver'
  s.description = 'A gem to make easy integrate Visual Review with Watir-WebDri
  ver'
  s.authors     = ['Gustavo Kath']
  s.email       = 'gustavokath@icloud.com'
  s.files       = ['lib/visual_review_watir.rb']
  s.homepage    = 'http://rubygems.org/gems/hola'
  s.license     = 'MIT'

  s.add_runtime_dependency 'multipart_body', '~> 0.2', '>= 0.2.1'
  s.add_runtime_dependency 'watir-webdriver', '~> 0.9', '>= 0.9.1'

  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'simplecov', '~> 0'
end
