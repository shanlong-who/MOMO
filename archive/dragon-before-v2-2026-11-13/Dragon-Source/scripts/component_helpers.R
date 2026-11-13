label_components <- function(alpha, threshold = 0.1) {
  result <- .Call("label_components", alpha, as.numeric(threshold))
  result$components <- as.data.frame(result$components)
  names(result$components) <- c("id", "area", "xmin", "xmax", "ymin", "ymax", "cx", "cy")
  result
}
