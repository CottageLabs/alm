@javascript
Feature: See responses from sources
  In order to make sure that we collect metrics correctly
  An admin user
  Should be able to see the responses from the last 24 hours and 30 days

  Background:
    Given I am logged in as "admin"
    And the source "Citeulike" exists
    And that we have 5 articles

    @not-teamcity
    Scenario: Responses from last 24 hours in source view
      When I go to the "Summary" tab of source "CiteULike"
      Then the table "SummaryTable" should be:
        |                                             | Pending              | Working    |
        | Jobs                                        | 0                    | 0          |
        |                                             | Responses            | Errors     |
        | Responses in the last 24 Hours              | 0                    | 0          |
        |                                             | Average              | Maximum    |
        | Response duration in the last 24 Hours (ms) | 0                    | 0          |
        |                                             | Articles with Events | All Events |
        | Events                                      | 5                    | 250        |

    Scenario Outline: I should see the charts in the summary view
      When I go to the "Summary" tab of source "CiteULike"
      Then I should see a row of "<Charts>"

      Examples:
        | Charts |
        | status |
        | day    |
        | month  |