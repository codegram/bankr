Feature: Log to your account
  In order to retrieve my bank account information
  As a customer
  I want to enter my ID and password

  Scenario: Log in with user and password
    Given I visit LaCaixa website
    And I follow "Particulares"
    When I enter a valid ID and password
    Then I should see my name
