# Remember to restart R session before running

library(pbapply)
base::load("./benchmark/packages_chunks.rda")

packages_times <- packages_chunks



eval_times_list <- pblapply(1L:nrow(packages_times), 
                            function(i) 
                              try({
                                local({
                                  eval(parse(text=packages_times[i, "pkg_setup"]))
                                  start_time <- Sys.time()
                                  eval(expr = parse(text=packages_times[i, "code_to_eval"]))
                                  end_time <- Sys.time()
                                  
                                  end_time - start_time
                                  
    })
  }, silent = TRUE)
)

non_error_id <- sapply(eval_times_list, class) != "try-error"

packages_times[non_error_id, "evaluation_time"] <- unlist(eval_times_list[non_error_id])

save(packages_times, file = "./benchmark/packages_times.rda")



