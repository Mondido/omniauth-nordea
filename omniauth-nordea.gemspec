Gem::Specification.new do |gem|
  gem.name          = "omniauth-nordea"
  gem.authors       = ["Robert Pohl"]
  gem.email         = ["robert@mondido.com"]
  gem.description   = "OmniAuth strategy for Nordea Open Banking."
  gem.summary       = "OmniAuth strategy for Nordea Open Banking."
  gem.homepage      = "https://github.com/mondido/omniauth-nordea"
  gem.license       = "MIT"

  gem.files         = Dir["README.md", "LICENSE", "lib/**/*"]
  gem.require_path  = "lib"
  gem.version       = "0.0.1"

  gem.add_dependency "omniauth", "~> 1.2"
  gem.add_dependency "omniauth-oauth2", "~> 1.2"
end
