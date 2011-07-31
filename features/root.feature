Feature: Homepage
  In order to use collage
  A visitor
  Should be able to create a collage

  @javascript
  Scenario: I can create a collage from the homepage
    When I go to the homepage
    Then I should see "Create a Collaged"
    And I should see "Title"
