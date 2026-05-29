# Photo management functions

#' Save uploaded photo
save_player_photo <- function(file_path, player_id, destination_dir = "www/photos") {

  # Create directory if it doesn't exist
  if (!dir.exists(destination_dir)) {
    dir.create(destination_dir, recursive = TRUE)
  }

  # Copy file to destination with player ID as filename
  file_ext <- tools::file_ext(file_path)
  dest_file <- file.path(destination_dir, paste0(player_id, ".", file_ext))
  file.copy(file_path, dest_file, overwrite = TRUE)

  return(dest_file)
}

#' Save flag images
save_country_flag <- function(country_name, image_path, destination_dir = "www/flags") {

  # Create directory if it doesn't exist
  if (!dir.exists(destination_dir)) {
    dir.create(destination_dir, recursive = TRUE)
  }

  # Create filename from country name
  file_name <- paste0(tolower(gsub(" ", "_", country_name)), ".png")
  dest_file <- file.path(destination_dir, file_name)

  # Copy flag image
  file.copy(image_path, dest_file, overwrite = TRUE)
  return(dest_file)
}

#' Check if photo exists
photo_exists <- function(player_id, photo_dir = "www/photos") {
  # Check for jpg or png
  jpg_file <- file.path(photo_dir, paste0(player_id, ".jpg"))
  png_file <- file.path(photo_dir, paste0(player_id, ".png"))

  return(file.exists(jpg_file) || file.exists(png_file))
}

#' Get photo path for player
get_photo_path <- function(player_id, photo_dir = "www/photos") {
  jpg_file <- file.path(photo_dir, paste0(player_id, ".jpg"))
  png_file <- file.path(photo_dir, paste0(player_id, ".png"))

  if (file.exists(jpg_file)) return(jpg_file)
  if (file.exists(png_file)) return(png_file)
  return(NULL)
}

#' Get flag path for country
get_flag_path <- function(country_name, flag_dir = "www/flags") {
  flag_file <- file.path(flag_dir, paste0(tolower(gsub(" ", "_", country_name)), ".png"))

  if (file.exists(flag_file)) {
    return(flag_file)
  }
  return(NULL)
}

#' List all uploaded photos
list_uploaded_photos <- function(photo_dir = "www/photos") {
  if (!dir.exists(photo_dir)) {
    return(data.frame())
  }

  files <- list.files(photo_dir, pattern = "\\.(jpg|jpeg|png)$", ignore.case = TRUE)
  return(data.frame(
    file = files,
    player_id = sub("\\.[^.]+$", "", files),
    stringsAsFactors = FALSE
  ))
}
