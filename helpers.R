library(magrittr)

# helper function to hit the user listing API
lookup_user <- function(id, type = "guid") {
  stopifnot(type %in% c("guid", "username"))
  
  # this will need to be updated based on the results returned by the usage API
  if (is.null(id)) {
    return("anonymous-guid")
  }
  
  
  # this will get better when the user API supports search
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
                       guid = vector("character"))
  
  # and step through the pages, printing out the results (if any)
  while(length(payload$result) > 0) {
    
    # process payload
    result <- rbind(result, purrr::map_df(payload$results, ~data.frame(username = .x$username, guid = .x$guid)))
    
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
                                            user_guid = .x$user_guid,
                                            ended = .x$ended)))
  
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
                                              ended = .x$ended)))
  }
  
  result  
}

# fake implementation
# get_shiny_usage <- function(content_guid = NA) {
#   con <- odbc::dbConnect(RSQLite::SQLite(), "connect-instrumentation.db")
#   on.exit(dbDisconnect(con))
#   usage_data <- dbReadTable(con, "shiny_app_usage")
#   if (!is.na(content_guid)) {
#     usage_data <- usage_data[which(usage_data$app_id == content_guid),]
#   }
#   add_user_guid_to_usage(usage_data)
# }
# 
# # the instrumentation db has user ids... but the api has user guids. sigh
# # temporary patch
# add_user_guid_to_usage <- function(usage_data) {
#   id_table <- readr::read_csv("guid-id-map.csv")
#   usage_data <- usage_data %>% 
#     dplyr::left_join(id_table, by = c("user_id" = "id"))
#   usage_data$username <- ifelse(usage_data$user_id==0 , "anonymous", usage_data$username)
#   
#   usage_data$user_guid <- purrr::map_chr(usage_data$username, ~lookup_user(.x, "username"))
#   
#   # now no cheating!
#   usage_data$username <- NULL
#   usage_data
# }
# 
#   
