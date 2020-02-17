

#' @title Plot the tuner results with plotly
#'
#' @description Plot the search space results
#' 
#' @param tuner A tuner object
#' @param height height of the plot
#' @param width width of the plot
#' @importFrom rjson fromJSON
#' @importFrom RJSONIO toJSON
#' @importFrom data.table rbindlist
#' @importFrom plotly add_trace
#' @importFrom plotly plot_ly
#' @importFrom tidyjson spread_all
#' @importFrom dplyr select
#' @importFrom dplyr contains
#' @importFrom dplyr %>%
#' @export
plot_tuner <- function(tuner, height = NULL, width = NULL) {
  
  proj_name = gsub(tuner$project_dir, replacement = '/',pattern = '\\',fixed=T)
  
  proj_dirs = list.dirs(proj_name)
  
  files = list.files(proj_dirs, 'trial.json', full.names = T)
  
  dataset = list()
  
  for (j in 1:length(files)) {
    
    result <- rjson::fromJSON(file =files[j])
    data_1 <- RJSONIO::toJSON(result) %>% spread_all
    dataset[[j]] = data_1
    rm(data_1, result)
  }
  
  dataset = rbindlist(dataset, fill = T) 
  
  colnames(dataset) = gsub(colnames(dataset), replacement = '_', pattern = '\\.') 
  colnames(dataset) = gsub(colnames(dataset), replacement = '', pattern = 'hyperparameters_values_') 
  colnames(dataset) = gsub(colnames(dataset), replacement = '', pattern = 'metrics_metrics_')
  
  
  cols = dataset %>% select(-c(1:5),-contains('direction'),'best_step','learning_rate','score') %>% as.data.frame()
  
  list_plot = list()
  
  for (i in 1:ncol(cols)) {
    
    if(is.numeric(cols[[i]]) | is.integer(cols[[i]])) {
      max_value = cols[[i]] %>% max(na.rm = T)
      list_plot[[i]] = list(range = c(min(cols[[i]],na.rm = T), max(cols[[i]],na.rm = T)),
                            tickwidth=3,
                            label = paste(colnames(cols[i])), values = cols[[i]])
    }
    if(is.character(cols[[i]])) {
      
      list_plot[[i]] = list(tickvals = 1:max(as.numeric(as.factor(cols[[i]])),na.rm = T),
                            ticktext = levels(as.factor(cols[[i]])),
                            tickwidth=3,
                            label = paste(colnames(cols[i])), values = as.numeric(as.factor(cols[[i]])))
    }
  }
  
  
  max_val = dataset %>% select(contains('unit')) %>% as.matrix() %>% max(na.rm = T)
  min_val = dataset %>% select(contains('unit')) %>% as.matrix() %>% min(na.rm = T)
  
  if (is.null(width) | is.null(height)) {
    
    p = cols %>%
      plot_ly() %>%
      add_trace(type = 'parcoords',
                line = list(color = cols[[2]],
                            colorscale = 'Bluered',
                            showscale = TRUE,
                            reversescale = T,
                            cmin = min_val,
                            cmax = max_val),
                dimensions = list_plot)
    
  } else {
    p = cols %>%
      plot_ly(width = width, height = height) %>%
      add_trace(type = 'parcoords',
                line = list(color = cols[[2]],
                            colorscale = 'Bluered',
                            showscale = TRUE,
                            reversescale = T,
                            cmin = min_val,
                            cmax = max_val),
                dimensions = list_plot)
  }
  
  
  rm(list_plot, max_val, min_val, dataset)
  
  return(list(p,cols))
}

