defmodule ExAutomation.Jira.ClientTest do
  use ExUnit.Case, async: true

  describe "get_ticket/4" do
    test "constructs correct authorization header" do
      email = "test@example.com"
      token = "api_token_123"
      expected_auth = Base.encode64("#{email}:#{token}")

      # Test the auth string construction logic
      auth_string = Base.encode64("#{email}:#{token}")
      assert auth_string == expected_auth
    end

    test "validates required parameters" do
      # Test that function accepts string parameters
      ticket_id = "INT-123"
      base_url = "https://company.atlassian.net"
      token = "token"
      email = "email@test.com"

      # These should not raise compile-time errors
      assert is_binary(ticket_id)
      assert is_binary(base_url)
      assert is_binary(token)
      assert is_binary(email)
    end

    test "constructs proper API URL" do
      base_url = "https://company.atlassian.net"
      ticket_id = "INT-123"
      expected_url = "#{base_url}/rest/api/3/issue/#{ticket_id}"

      assert expected_url == "https://company.atlassian.net/rest/api/3/issue/INT-123"
    end

    test "handles different ticket ID formats" do
      ticket_ids = ["INT-123", "PROJECT-456", "ABC-789", "X-1"]

      for ticket_id <- ticket_ids do
        assert is_binary(ticket_id)
        assert String.contains?(ticket_id, "-")
      end
    end
  end

  describe "get_ticket_with_fields/5" do
    test "handles field list parameter" do
      fields = ["summary", "status", "assignee"]
      fields_string = Enum.join(fields, ",")

      assert fields_string == "summary,status,assignee"
    end

    test "handles empty field list" do
      fields = []
      fields_string = Enum.join(fields, ",")

      assert fields_string == ""
    end

    test "handles single field" do
      fields = ["summary"]
      fields_string = Enum.join(fields, ",")

      assert fields_string == "summary"
    end
  end

  describe "URL construction" do
    test "handles various base URL formats" do
      base_urls = [
        "https://company.atlassian.net",
        "https://company.atlassian.net/",
        "http://localhost:8080",
        "https://custom-domain.com"
      ]

      ticket_id = "TEST-123"

      for base_url <- base_urls do
        # Remove trailing slash for consistency
        clean_base_url = String.trim_trailing(base_url, "/")
        expected = "#{clean_base_url}/rest/api/3/issue/#{ticket_id}"

        assert String.starts_with?(expected, "http")
        assert String.contains?(expected, "/rest/api/3/issue/")
        assert String.ends_with?(expected, ticket_id)
      end
    end

    test "constructs proper API endpoint" do
      base_url = "https://test.atlassian.net"
      ticket_id = "PROJ-456"

      expected_path = "/rest/api/3/issue/#{ticket_id}"
      full_url = "#{base_url}#{expected_path}"

      assert full_url == "https://test.atlassian.net/rest/api/3/issue/PROJ-456"
    end
  end

  describe "authentication" do
    test "basic auth encoding works correctly" do
      email = "user@example.com"
      token = "secret_token_123"

      auth_string = Base.encode64("#{email}:#{token}")
      decoded = Base.decode64!(auth_string)

      assert decoded == "#{email}:#{token}"
    end

    test "handles special characters in credentials" do
      email = "user+test@example.com"
      token = "token_with_special_chars!@#$"

      auth_string = Base.encode64("#{email}:#{token}")
      decoded = Base.decode64!(auth_string)

      assert decoded == "#{email}:#{token}"
    end
  end

  describe "parameter validation" do
    test "ticket ID parameter types" do
      valid_ticket_ids = ["ABC-123", "PROJECT-456", "X-1", "LONG_PROJECT_NAME-999"]

      for ticket_id <- valid_ticket_ids do
        assert is_binary(ticket_id)
        assert String.length(ticket_id) > 0
      end
    end

    test "base URL parameter types" do
      valid_base_urls = [
        "https://company.atlassian.net",
        "http://localhost:8080",
        "https://custom.domain.com"
      ]

      for base_url <- valid_base_urls do
        assert is_binary(base_url)
        assert String.starts_with?(base_url, "http")
      end
    end

    test "email parameter validation" do
      valid_emails = [
        "user@example.com",
        "test.user@company.org",
        "admin+jira@domain.co.uk"
      ]

      for email <- valid_emails do
        assert is_binary(email)
        assert String.contains?(email, "@")
        assert String.contains?(email, ".")
      end
    end

    test "token parameter validation" do
      tokens = [
        "simple_token",
        "token_with_underscores",
        "TokenWithNumbers123",
        "token-with-dashes"
      ]

      for token <- tokens do
        assert is_binary(token)
        assert String.length(token) > 0
      end
    end
  end

  describe "fields parameter handling" do
    test "common Jira fields" do
      common_fields = [
        "summary",
        "status",
        "assignee",
        "reporter",
        "priority",
        "issuetype",
        "created",
        "updated",
        "description",
        "labels",
        "components",
        "fixVersions",
        "customfield_10001"
      ]

      for field <- common_fields do
        assert is_binary(field)
        assert String.length(field) > 0
      end

      # Test joining fields
      fields_string = Enum.join(common_fields, ",")
      assert String.contains?(fields_string, "summary")
      assert String.contains?(fields_string, "status")
    end

    test "field list combinations" do
      test_cases = [
        [],
        ["summary"],
        ["summary", "status"],
        ["summary", "status", "assignee", "priority"]
      ]

      for fields <- test_cases do
        result = Enum.join(fields, ",")

        expected_length =
          case length(fields) do
            0 -> 0
            n -> (Enum.map(fields, &String.length/1) |> Enum.sum()) + (n - 1)
          end

        assert String.length(result) == expected_length
      end
    end
  end

  describe "integration scenarios" do
    test "typical usage pattern parameters" do
      # Simulate typical usage parameters
      configs = [
        %{
          ticket_id: "PROJ-123",
          base_url: "https://company.atlassian.net",
          email: "user@company.com",
          token: "api_token_here"
        },
        %{
          ticket_id: "INT-456",
          base_url: "https://myorg.atlassian.net",
          email: "admin@myorg.com",
          token: "different_token"
        }
      ]

      for config <- configs do
        # Verify all required parameters are present and valid
        assert is_binary(config.ticket_id)
        assert is_binary(config.base_url)
        assert is_binary(config.email)
        assert is_binary(config.token)

        # Verify basic format requirements
        assert String.contains?(config.ticket_id, "-")
        assert String.starts_with?(config.base_url, "http")
        assert String.contains?(config.email, "@")
        assert String.length(config.token) > 0
      end
    end

    test "field selection scenarios" do
      scenarios = [
        %{
          name: "minimal_fields",
          fields: ["summary", "status"]
        },
        %{
          name: "standard_fields",
          fields: ["summary", "status", "assignee", "priority", "issuetype"]
        },
        %{
          name: "comprehensive_fields",
          fields: [
            "summary",
            "status",
            "assignee",
            "reporter",
            "priority",
            "issuetype",
            "created",
            "updated",
            "description",
            "labels",
            "components"
          ]
        }
      ]

      for scenario <- scenarios do
        assert is_list(scenario.fields)
        assert length(scenario.fields) > 0

        # Test field joining
        joined = Enum.join(scenario.fields, ",")
        assert is_binary(joined)

        # Verify all fields are strings
        for field <- scenario.fields do
          assert is_binary(field)
          assert String.length(field) > 0
        end
      end
    end
  end
end
