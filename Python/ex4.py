print "";

#number of cars
cars = 100
#number of passengers per car
space_in_a_car = 4.0
#number of drivers
drivers = 30
#number of total passengers
passengers = 90
#cars without drivers
cars_not_driven = cars - drivers
#cars with drivers
cars_driven = drivers
#number of seats in all cars with drivers
carpool_capacity = cars_driven * space_in_a_car
#supposed number of passengers per car
average_passengers_per_car = passengers / cars_driven


print "There are", cars, "cars available."
print "There are only", drivers, "drivers available."
print "There will be", cars_not_driven, "empty cars today."
print "We can transport", carpool_capacity, "people today."
print "We have", passengers, "to carpool today."
print "We need to put about", average_passengers_per_car, "in each car."

print "";
