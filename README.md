## A tracker app to record visits and notes to US national parks
Inspired by the [US national parks passport](https://www.nps.gov/olym/planyourvisit/national-parks-passport-program.htm), this application is built in Ruby using [Sinatra](https://sinatrarb.com) and communicates to the client via [PUMA](https://puma.io). All data are stored in a backend DB using PostgreSQL. User credentials information are first encrypted before being stored in the DB.

Still in search of another free web server to host the application as Heroku is no longer free. 

<a href="url"><figure><img src="https://github.com/suksien/national_park_tracker/blob/main/sign_in.png" align="center" height="157" width="590" ><figcaption>Figure 1: User is prompted to sign in as a first step.</figcaption><figure></a>

<a href="url"><figure><img src="https://github.com/suksien/national_park_tracker/blob/main/main.png" align="center" height="352" width="629" ><figcaption>Figure 2: Main page shows a list of all parks the user has entered.</figcaption></figure></a>  

<a href="url"><figure><img src="https://github.com/suksien/national_park_tracker/blob/main/acadia.png" align="center" height="623" width="703" ><figcaption>Figure 3: Detailed page of a single park where the user can add / edit / delete information.</figcaption></figure></a>
