# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create!(
	name: 'Sebastian Valdez',
	phone: '4152994331',
	email: 'seb@test.com',
	password: 'asdfasdf',
	password_confirmation: 'asdfasdf',
	role: 'admin'
)
puts "admin created!\n"

User.create!(
	name: 'Joe Shmoe',
	phone: '5552224343',
	email: 'user@test.com',
	password: 'asdfasdf',
	password_confirmation: 'asdfasdf'
)

puts "user created"