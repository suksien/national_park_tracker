# A National Park tracker that keeps track of your visitation and displays basic park information.

The application is built using Ruby 3.2.2 and uses PostgreSQL (16.3) as the backend RDBMS. It uses Bundler (v2.5.7) for dependency management. It has been tested on Chrome (version 129.0.6668.58) and Safari (version 17.6) on a laptop (Mac OS).

Ruby, Bundler, and PostgreSQL are required to run the application:
1. How to install Ruby: https://launchschool.com/books/ruby/read/preparations#installingruby
2. How to install PostgreSQL:
  > on MacOS: https://launchschool.medium.com/how-to-install-postgresql-for-mac-os-x-61623df41f59
  > on Linux: https://launchschool.medium.com/how-to-install-postgres-for-ubuntu-linux-fa06a162348
3. Install `bundler` (after installing Ruby): `$ gem install bundler`

# How to run the application:
1. Navigate to the project directory. 
2. On your terminal, run `bundle install` to fetch all the dependencies. 
3. Set up the database via `psql < schema.sql` on your terminal. 
4. Run the application by typing `ruby app.rb` on your terminal. In case of errors, try using the `bundle exec ruby app.rb` command.
5. Open up a browser and type `localhost:4567/`

# Description:
The application requires user authentication for all operations. You can use the provided user with username "ta" and password "letmein". 

The homepage features a table that displays all the national parks in your tracker, sorted according to the park names. The table includes the park name, state where the park is located, date the park is established, area of the park, and whether or not you have visited it. 

To add a new park, click on `Add a park` link, which will bring up a form. All fields of the form are required. Checking for a unique park entry is done via a case-insensitive comparison of the park name, i.e. `Park` is the same as `park` or `pARk`. For `state` and `description`, the application simply checks that at least one character is entered. For `area` validation, the application checks that the entered value is a number greater than zero. The application does check for a valid date, i.e. 2022-02-31 is not a valid date, neither is 2022-06-31. 

Going back to the homepage, one can scroll through the parks via the links provided on the bottom, above the `Sign Out` button.
* To scroll to the first/last page, click on `First`/`Last`
* To scroll through subsquent pages, click on `Previous` or `Next`

To delete a park, simply click on the trash can icon. Please consider carefully if you want to delete a park since no warning will be issued. 

To view a park and your visit history, click on the park name. The resultant page will display a short description of the park and one's visits to the part, if any. This page also allows one to edit the park's info and add/edit/delete a visit. The page will display a maximum of three visits at any time, ordered according to date visited. If there are more than three visits, simply click on the `Previous` and `Next` buttons to scroll through the visits. 

For adding a new visit, only a date input is required. The application checks for unique visits based on the entered date. 

The database behind this application hosts three tables, where `park_info` and `visits` are the main tables in a 1:M relationship. The third table, `user`, stores the user login information and exists independently. The user password is first encrypted using BCrypt before being stored here. 

# Future improvements:
Some extra features that are nice:
1. Add a `visited` and `not yet visited` links.
2. Add a `sign up` link.
3. Add ability to sort parks by state, area, and established dates. 
4. Add a stock image for each park page. Maybe even allow users to upload their own photos from their visits.  

# Credits:
1. Sample seed data in `data/mini_df.csv` are obtained and adapted from Kaggle (https://www.kaggle.com/datasets/thedevastator/the-united-states-national-parks)
2. I got the idea for this application based on the Notion template for a NP tracker: https://www.notion.so/templates/national-park-tracker
