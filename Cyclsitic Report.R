# The data has been made available by Motivate International Inc. under this license (https://www.divvybikes.com/data-license-agreement)

#start_station_id and end_Station_id had 2 different types: chr & dbl which made merging the databases impossible
#  Found error only related to 092020 and 102020
#  Mutated start_station_id to chr for these
  
cyclistic_102020 <- mutate(cyclistic_102020, start_station_id = as.character(start_station_id))
cyclistic_102020 <- mutate(cyclistic_102020, end_station_id = as.character(end_station_id))
cyclistic_092020 <- mutate(cyclistic_092020, end_station_id = as.character(end_station_id))
cyclistic_092020 <- mutate(cyclistic_092020, start_station_id = as.character(start_station_id))
str(cyclistic_092020)

#Checked all_trips summary and saw some NA's in ended_lat & ended_lng. Saw that variables with characters don't have an NA report so used sum(is.na(all_trips$variable))
#to check all variables with characters for NA's
#Checked for N/A in the all_trips based on  database and realised that there's around 10% NA's for start_station_id; start_station_name; end_station_id; end_station_name
#This data is not relevant for our question so I won't exclude it but might work with a cleaned data frame for a new analysis
#Checked for Member/Casual as per instructions using unique(all_trips$member_casual) as per instructions but this is no longer an issue with the last 12 months data set.
#added month/week/year/day for all trips

#add dates
#created new database with all rides  all_trips_v2 <- all_trips[!(all_trips$ride_length<0),]
all_trips_v2 <- all_trips[!(all_trips$ride_length<0),]

#order dates 
all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week, levels=c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))

#Created an occurence column because the sum function takes up less resources than an n_distinct function for ride id's, this should speed up our analysis and 
#plotting process.



#check the min/max/mean/median between casual and members split by days of the week / months
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = mean)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = median)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = max)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = min)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week, FUN = mean)




#create a new column ride_length that calculates the ride length for people
all_trips$ride_length <- difftime(all_trips$ended_at,all_trips$started_at)

#created new database with all rides  all_trips_v2 <- all_trips[!(all_trips$ride_length<0),]
all_trips_v2 <- all_trips[!(all_trips$ride_length<0),]

#create occurrence series
all_trips_v2 <- all_trips_v2 %>% 
  mutate(occurence = row_number(1))




# We're interested in the hypothesis that members tend to use their membership for their daily commute
# in order to create cluster of 7 to 9:59 am for the morning commute / between 10 and 16:59 for a day ride, between 17:00 and 18:59 for the evening commute 
#between 19 and 23.59 for an evening ride and finally between midnight and 6 am for a night ride.
all_trips_v2 <- all_trips_v2 %>% 
  mutate(is_commute = case_when(
    hour(ended_at) %in% 07:09.59 ~ "morning commute",
    hour(ended_at) %in% 10:16.59 ~ "day ride",
    hour(ended_at) %in% 17:18.59 ~ "evening commute",
    hour(ended_at) %in% 19:23.59 ~ "evening ride",
    hour(ended_at) %in% 00:06.59 ~ "night ride"
  ))

#Furthermore, we'll have to create a cluster for weekend and weekday to be able to isolate work commutes from weekend rides 
#create cluster for weekend / non weekend
all_trips_v2 <- all_trips_v2 %>% 
  mutate(is_weekend = case_when(
    wday(date) %in% 2:6 ~ "weekday",
    wday(date) == 1 | wday(date) == 7 ~"weekend"
  ))

#Now that we have the database set up properly, we'll look into comparing the two user groups.

#find out the total number of rides by group
all_trips_v2 %>% 
  group_by(member_casual) %>% 
  summarise(count = sum(occurence))
#We can see that there's a higher number of members than casual users, around 20% higher, which means that although members use the service more, there's
#still a lot of potential from the casual users.
# we can use the aggregatve function as well, but it's slower:
aggregate(all_trips_v2$occurence ~ all_trips_v2$member_casual, FUN = sum)


#analyze trends based on weekend vs weekday - total rides
all_trips_v2 %>% 
  group_by(member_casual, is_weekend) %>% 
  summarise(rides = sum(occurence))
# we can also use the aggregate function although it's a bit slower
aggregate(all_trips_v2$occurence ~ all_trips_v2$member_casual + all_trips_v2$is_weekend, FUN = sum)
#we can see that there's considerably more casuals during weekends whilst weekdays see considerably more members
#however the difference is not considerably higher


#analyze trends based on weekend vs weekday - mean ride length
all_trips_v2 %>% 
  group_by(member_casual, is_weekend) %>% 
  summarise(average_ride_length = mean(ride_length))
# we can also use the aggregate function although it's a bit slower
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$is_weekend, FUN = mean)
#Casuals tend to use the service for longer periods than casuals both during weekend and weekdays, this might be because they're mostly using the bikes for 
#long rides whilst members use it for convenience to get faster from one point to another.



#Now let's look at the commute numbers with the weekend filtered out.

all_trips_v2 %>% 
  filter(is_weekend == "weekday") %>% 
  group_by(is_commute, member_casual) %>% 
  summarise(rides = sum(occurence))
#almost 3 times more members morning commuters than casual morning commuters, evening commute back is only 40% higher which might be explained
#by people staying with friends for food/drinks and taking public transportation home later. This is the most meaningful difference up until now.


#Let's also look at the average ride length for this
all_trips_v2 %>% 
  filter(is_weekend == "weekday") %>% 
  group_by(is_commute, member_casual) %>% 
  summarise(rides_length = mean(ride_length))
#it looks like even during commute hours casuals tend to use the service for longer than members, with the commutes for casuals being twice as long.
#this could be explained by members using the service to travel towards the closest public transportation station, leaving them and taking another
#close to work whilst casuals use it to get to work entirely.




#What if within the group of casuals there's a subset that behaves exactly like the members? Usually targeting a "lookalike" audience should have a higher 
#conversion since they use the product similarly and could benefit more from the membership.
#In order to compare them let's create a subset of riders with the ride length lower than 1000 seconds (17 minutes) and see how big this audience is.

all_trips_v2 %>% 
  filter(ride_length < 1000) %>% 
  group_by(member_casual) %>% 
  summarise(trips = sum(occurence))

all_trips_v2 %>% 
  group_by(member_casual) %>% 
  summarise(trips = sum(occurence))
#We can see that there's around 1 million rides (50%) from casual users that would have a behavior consistent with paying members.
all_trips_v2 %>% 
  filter(ride_length < 1000) %>% 
  filter(is_weekend == "weekday") %>% 
  group_by(is_commute, member_casual) %>% 
  summarise(trips = sum(occurence))

all_trips_v2 %>% 
  group_by(is_commute, member_casual) %>% 
  filter(is_weekend == "weekday") %>% 
  summarise(trips = sum(occurence))
#unfortunately the 3x difference between casuals and members during commute rides sticks but the subset should still be the most relevant for a lookalike.

#Now let's create the subset as an actual column so that we can plot it properly.
all_trips_v2 <- all_trips_v2 %>% 
  mutate(lookalike = case_when(
    ride_length < 1400 ~ "lookalike",
    ride_length > 1400 ~ "generic"
  ))


#GG Plot 2

#Now let's export a visual that shows the difference between lookalike and generic within casual users
all_trips_v2 %>% 
  filter(member_casual == "casual") %>% 
  group_by(lookalike) %>% 
  summarise(count_rides = sum(occurence)) %>% 
  ggplot(mapping = aes(x = lookalike, y = count_rides, fill = lookalike))+
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6))
#There's almost just as many generic users as lookalikes
all_trips_v2 %>% 
  group_by(member_casual, lookalike) %>% 
  summarise(count_rides = sum(occurence)) %>% 
  ggplot(mapping = aes(fill = lookalike, y = count_rides, x = member_casual))+
  geom_bar(position="dodge",stat="identity")+
  scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6))


all_trips_v2 %>% 
  filter(is_weekend == "weekday") %>% 
  group_by(member_casual, lookalike) %>% 
  summarise(count_rides = sum(occurence)) %>% 
  ggplot(mapping = aes(fill = lookalike, y = count_rides, x = member_casual))+
  geom_bar(position="dodge",stat="identity")+
  scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6))
#Just to be sure that the logic actually applies to most members, we'll look at the criteria across memebrs and casuals for weekdays.
#as we can see, the criteria applies for almost 75% of members and close to 45% of casuals, thus the hypothesis is correct.
#Now we know that the casual group that's most likely to convert to a paid membership is the lookalike subsection within the filtered members_casual == casual group.
#Furthermore, this group's use cases seem consistent with a significant majority within the members group and is large enough (around half of the weekday casual commutes)
#to warrant a marketing campaign targeting them.

#Less to no relevancy now ---- Let's move further to analysing this difference based on weekdays only
all_trips_v2 %>% 
  filter(member_casual == "casual") %>% 
  filter(is_weekend == "weekday") %>% 
  group_by(is_commute, lookalike) %>% 
  summarise(count_rides = sum(occurence)) %>% 
  ggplot(mapping = aes(fill = lookalike, y = count_rides, x = is_commute))+
  geom_bar(position="dodge",stat="identity")+
  scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6))

#Now let's see the same difference between weekdays and weekends
all_trips_v2 %>% 
  filter(member_casual == "casual") %>% 
  group_by(is_weekend, lookalike) %>% 
  summarise(count_rides = sum(occurence)) %>% 
  ggplot(mapping = aes(fill = lookalike, y = count_rides, x = is_weekend))+
  geom_bar(position="dodge",stat="identity")+
  scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6))
#as expected there are more lookalikes than generic users during the weekday but this changes during the weekend when you have the casual long distance riders.

#check casuals vs members by months - hypothesis that considerably more casuals will buy in spring/summer months
all_trips_v2 %>% 
  group_by(member_casual) %>% 
  summarise(mean(ride_length))


all_trips_v2_sample <- head(all_trips_v2, 1000)


all_trips_v2 %>% 
  group_by(ride_id, member_casual) %>% 
  summarise(count_rides = n_distinct(ride_id)) %>% 
  ggplot(mapping = aes(x = member_casual, y = count_rides, fill = member_casual))+
  geom_bar(stat = "identity") + coord_polar("y", start = 0)

all_trips_v2 %>% 
  group_by(ride_id, member_casual) %>% 
  summarise(rides = ride_id, ride_length = ride_length) %>% 
  ggplot(mapping = aes(x = rides, y = ride_length))+
  geom_point(size=2, shape=2)

