## RSC Instrumentation POC

This is just the beginning.

To see the app in action, checkout: http://colorado.rstudio.com:3939/content/1560/

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


To explore:

1) We'll want to switch out the "pull all data from DB every 5 minutes" with a more refined model that potentially pushes down some of our filtering to the API where possible. 

2) This app shows everything to everyone. It'd be interesting to customize the app based on the viewing user (either from a permissions standpoint or just UX). For example, it'd be really simple to set the default selected user based on the visitor.

2) I want to add a period filter to the dashboard (last 30, 90, 365 days). Ideally this filter would go to the API to set 
bounds on the data I pull in.

3) This app is slow. We should look at the performance profile and consider switching away from RMD, caching plots, and other areas of improvements. Async might make sense here. Perhaps our client wrapper should be async? (or have that option). We could use RSC's min process option.


4) WHAT THE HECK is going on with our server?? I don't even beleive this data... 

5) What visuals or metrics would be helpful? Review with SE team.

6) We can make the plots interactive really easily.

7) Given this setup, would a RMD make more sense?

API headaches:

1) The anonymous user made things tricky

2) What happens to deleted content?

3) If and when we can search users, it'd be nice to setup an examlpe of doing so in parallel or searching for ids in batch

4) We should think about how the API can be helpful in terms of the "leaderboard" use case ... e.g. a query that sorts the results and returns a limited set, all on the RSC side. Though this is easy in R.

5) What happens to this app if the API performance is slow? 

6) It'd be interesting to see how our APIs could play with
shiny's reactivePoll instead of my dumb caching. Could we somehow 
only pull in new records? At a min. we could be smarter about what triggers
a change, rather than hard coding a cache flush every 5 mins.

What was easy....

1) Ordering, computing unique users, computing summaries, handling time

2) Medium Easy: Doing "joins". (I may have done this the hard way, it would be worth revisiting tbe code to see 
if we could actually leverage a join without our own lookup funcions we had to map over)

3) Graphing and app building 

... More to come!!
