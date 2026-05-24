Feature: Lead management

  Scenario: Create a new lead
    Given I send a lead with name "Juan" from "whatsapp"
    Then the system should create the lead with status "new"

  Scenario: Qualify a lead
    Given I have an existing lead
    When I assign a score of 80
    Then the lead should be "qualified"

  Scenario: VIP lead
    Given I have an existing lead
    When I assign a score of 95
    Then the lead should be "vip"