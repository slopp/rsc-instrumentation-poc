library(magrittr)

# helper function to return character instead of NULL 
null_char <- function(x, default) {
 if (is.null(x))
   return(default)
 x
}

# helper function to hit the user listing API
lookup_user <- function(id, type = "guid") {
  stopifnot(type %in% c("guid", "username"))
  
  # special case for anonymous
  if (id == "anonymous")
    return("anonymous-guid")
  
  
  # this will get better when the user API supports search by guid
  # for now, we cache the user list for 10 minutes
  # TODO: This does not recover well if get_all_users fails
  if (!exists('user_cache') || (Sys.time() - user_cache$mtime > 600)) {
    user_cache <<- list(
      users  = get_all_users(),
      mtime = Sys.time()
    )
  }
  
  switch(type,
    "guid" = user_cache$users$username[which(user_cache$users$guid == id)],
    "username" = user_cache$users$guid[which(user_cache$users$username == id)],
    NULL
  )
  
}

# vectorize
lookup_users <- function(ids, type = "guid") {
  purrr::map_chr(ids, ~lookup_user(.x, type))
}

# helper function to return a data frame of all users
get_all_users <- function(){
  connectServer <- Sys.getenv("RSTUDIO_CONNECT_SERVER")
  apiKey <- Sys.getenv("RSTUDIO_CONNECT_API_KEY")
  
  # get user's list
  authHeader <- httr::add_headers(Authorization = paste("Key", apiKey))
  apiPrefix <- "__api__/v1/users?page_size=25"
  resp <- httr::GET(
    paste0(connectServer, apiPrefix),
    authHeader
  )
  
  # get the first page
  payload <- httr::content(resp)
  
  #init result set
  result <- data.frame(username = vector("character"), 
                       guid = vector("character"), stringsAsFactors = FALSE)
  
  while(length(payload$result) > 0) {
    
    # process payload
    result <- rbind(result, purrr::map_df(payload$results, ~data.frame(username = .x$username,
                                                                       guid = .x$guid,
                                                                       stringsAsFactors = FALSE)))
    
    # get the next page
    nextPage <- payload$current_page + 1
    resp <- httr::GET(
      paste0(connectServer, apiPrefix, "&page_number=", nextPage),
      authHeader
    )
    payload <- httr::content(resp)
  }
  result
}

# get usage data for an app, optionally filtering by content GUID
get_shiny_usage <- function(content_guid = NA) {
  connectServer <- Sys.getenv("RSTUDIO_CONNECT_SERVER")
  apiKey <- Sys.getenv("RSTUDIO_CONNECT_API_KEY")
  
  
  # get first page
  authHeader <- httr::add_headers(Authorization = paste("Key", apiKey))
  endpoint <- paste0(connectServer, "__api__/v1/instrumentation/shiny/usage")
  if (!is.na(content_guid)) {
    endpoint <- paste0(endpoint, '?content_guid=', content_guid)
  }
  resp <- httr::GET(
    endpoint,
    authHeader
  )
  payload <- httr::content(resp)
  
  #init result set
  result <- data.frame(started = vector("character"), 
                       content_guid = vector("character"),
                       user_guid = vector("character"), 
                       ended = vector("character"))
  
  # process first page
  result <- rbind(result, 
                  purrr::map_df(payload$results, 
                                ~data.frame(started = .x$started,
                                            content_guid = .x$content_guid,
                                            user_guid = null_char(.x$user_guid,"anonymous"),
                                            ended = null_char(.x$ended, as.character(Sys.time())),
                                            stringsAsFactors = FALSE
                                            )
                                )
  )
  
  # now step through the remaining pages
  while (!is.null(payload$paging[["next"]])) {
    resp <- httr::GET(payload$paging[["next"]], authHeader)
    payload <- httr::content(resp)
    
    # process this page 
    result <- rbind(result, 
                    purrr::map_df(payload$results, 
                                  ~data.frame(started = .x$started,
                                              content_guid = .x$content_guid,
                                              user_guid = .x$user_guid,
                                              ended = .x$ended,
                                              stringsAsFactors = FALSE)))
  }
  
  result  
}

