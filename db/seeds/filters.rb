# encoding: UTF-8
# Load filters
article_not_updated_error = ArticleNotUpdatedError.find_or_create_by_name(
  :name => "ArticleNotUpdatedError",
  :display_name => "article not updated error",
  :description => "Raises an error if articles have not been updated within the specified interval in days.")
event_count_decreasing_error = EventCountDecreasingError.find_or_create_by_name(
  :name => "EventCountDecreasingError",
  :display_name => "decreasing event count error",
  :description => "Raises an error if event count decreases.")
event_count_increasing_too_fast_error = EventCountIncreasingTooFastError.find_or_create_by_name(
  :name => "EventCountIncreasingTooFastError",
  :display_name => "increasing event count error",
  :description => "Raises an error if the event count increases faster than the specified value per day.")
api_response_too_slow_error = ApiResponseTooSlowError.find_or_create_by_name(
  :name => "ApiResponseTooSlowError",
  :display_name => "API too slow error",
  :description => "Raises an error if an API response takes longer than the specified interval in seconds.")
source_not_updated_error = SourceNotUpdatedError.find_or_create_by_name(
  :name => "SourceNotUpdatedError",
  :display_name => "source not updated error",
  :description => "Raises an error if a source has not been updated in 24 hours.")
citation_milestone_alert = CitationMilestoneAlert.find_or_create_by_name(
  :name => "CitationMilestoneAlert",
  :display_name => "citation milestone alert",
  :description => "Creates an alert if an article has been cited the specified number of times.")