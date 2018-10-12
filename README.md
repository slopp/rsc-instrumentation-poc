## RSC Instrumentation POC

This is just the beginning.

To see the app in action, checkout: 

To replicate for a different server:

1) Copy the instrumentation DB. I used a server built on 1.6.8. 

2) Because my instrumentation DB doesn't have user guids, but I wanted to use
the actual user list API, I had to create a csv file that contains a map of usernames to user ids.
This csv is used to add user guids to the instrumenmtation DB data, so that it more closely resembles the 
data the actual API will return.

3) You need to create a file called `.Renviron` that contains:

```bash
RSTUDIO_CONNECT_SERVER="your_server_url"
RSTUDIO_CONNECT_API_KEY="your_admin_api_key"
```

3) With #1 and #2 in hand, you should be able to run the app. If you use a
newer server where the instrumentation db contains user guids instead of ids you
could make the code a bit simpler.


A few notes:

1) This app runs against a version of RSC w/out a user search API, just user list. Therefore, a local copy of the user list is cached every 10 minutes and then used for any queries that translate user guids to usernames.

2) The `helpers.R` file contains all of the functions that would need to be modified to use the actual
instrumentation API, as well as an example of hitting the user list API.




