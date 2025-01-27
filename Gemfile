source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.1'
gem 'pg'
gem 'puma', '~> 3.7'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'

source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
end

group :development, :test do
  
  gem 'pry-rails', '~> 0.3.6'
  gem 'pry-byebug', '~> 3.4'
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'rspec-rails', '~> 3.6'
  gem 'rails-controller-testing', '~> 1.0', '>= 1.0.2'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :production do
  gem 'rails_12factor'
end

# Added by me
gem 'jquery-rails'
gem 'google-analytics-rails', '~> 1.1'
gem "font-awesome-rails"
gem 'bootstrap', '~> 4.0.0.beta'
gem 'dotenv-rails', groups: [:development, :test]
gem 'seb_view_tool', '~> 0.1.0'
gem 'sendgrid', '~> 1.2', '>= 1.2.4'
gem 'sweetalert2', '~> 4.0', '>= 4.0.11'
gem 'client_side_validations', '~> 10.0', '>= 10.0.1', git: 'https://github.com/DavyJonesLocker/client_side_validations'
gem 'carrierwave', '~> 1.0'
gem 'devise', '~> 4.3'
gem 'jquery_file_download-rails', '~> 0.0.2'
gem 'mini_magick', '~> 4.8'
gem 'petergate', '~> 1.8'
gem 'carrierwave-aws', '~> 1.3'