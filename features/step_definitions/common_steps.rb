# "Then I should see 5 articles"
Then /^I should see (\d+) (.+)$/ do |number, name|
  assert page.has_xpath?("//*[@class = '#{name.singularize}']", :count => number.to_i)
end
