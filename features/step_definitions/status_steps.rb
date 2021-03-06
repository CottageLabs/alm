### GIVEN ###
Given /^that we have added (\d+) documents to CouchDB$/ do |number|
  number.to_i.times do |i|
    put_alm_data("#{CONFIG[:couchdb_url]}#{i}", data: { "name" => "Fred" })
 end
end

### THEN ###
Then /^I should see that the CouchDB size is "(.*?)"$/ do |size|
  page.has_css?('#couchdb_size', :text => size).should be_true
end

Then(/^I should see that we have (\d+) articles$/) do |number|
  page.has_css?('#articles_count', :text => number).should be_true
end

Then(/^I should see that we have (\d+) events$/) do |number|
  page.has_css?('#events_count', :text => number).should be_true
end

Then(/^I should see that we have (\d+) user$/) do |number|
  page.driver.render("tmp/capybara/CouchDB.png")
  page.has_css?('#users_count', :text => number).should be_true
end
