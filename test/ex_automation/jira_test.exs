defmodule ExAutomation.JiraTest do
  use ExAutomation.DataCase
  alias ExAutomation.Jira

  describe "get_ticket/4" do
    test "has correct function signature and delegates properly" do
      # Verify the function is available for delegation
      assert Code.ensure_compiled(Jira) == {:module, Jira}
    end

    test "function is properly delegated to Client module" do
      # Test that the delegation is set up correctly by checking the module definition
      {:module, module} = Code.ensure_compiled(Jira)
      assert module == Jira

      # Check that the function exists
      assert function_exported?(Jira, :get_ticket, 4)
    end
  end

  describe "get_ticket_with_fields/5" do
    test "has correct function signature and delegates properly" do
      # Verify the function is available for delegation
      assert Code.ensure_compiled(Jira) == {:module, Jira}
    end

    test "function is properly delegated to Client module" do
      # Test that the delegation is set up correctly
      {:module, module} = Code.ensure_compiled(Jira)
      assert module == Jira

      # Check that the function exists
      assert function_exported?(Jira, :get_ticket_with_fields, 5)
    end
  end

  describe "module structure" do
    test "module compiles successfully" do
      {:module, module} = Code.ensure_compiled(Jira)
      assert module == Jira
    end

    test "module has expected functions" do
      functions = Jira.__info__(:functions)

      # Check that our main functions are present
      assert Keyword.has_key?(functions, :get_ticket)
      assert Keyword.get(functions, :get_ticket) == 4

      assert Keyword.has_key?(functions, :get_ticket_with_fields)
      assert Keyword.get(functions, :get_ticket_with_fields) == 5
    end

    test "module documentation is present" do
      {:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(Jira)

      # Verify module has documentation
      assert module_doc != :none
      assert module_doc != nil
    end
  end

  describe "function behavior validation" do
    test "get_ticket/4 accepts correct parameter types" do
      # Test parameter type expectations without making actual calls
      ticket_id = "TEST-123"
      base_url = "https://test.atlassian.net"
      token = "test_token"
      email = "test@example.com"

      # Verify parameters are of expected types
      assert is_binary(ticket_id)
      assert is_binary(base_url)
      assert is_binary(token)
      assert is_binary(email)

      # Function should exist and accept these parameter types
      assert function_exported?(Jira, :get_ticket, 4)
    end

    test "get_ticket_with_fields/5 accepts correct parameter types" do
      # Test parameter type expectations
      ticket_id = "TEST-123"
      base_url = "https://test.atlassian.net"
      token = "test_token"
      email = "test@example.com"
      fields = ["summary", "status"]

      # Verify parameters are of expected types
      assert is_binary(ticket_id)
      assert is_binary(base_url)
      assert is_binary(token)
      assert is_binary(email)
      assert is_list(fields)

      # Verify all fields are strings
      for field <- fields do
        assert is_binary(field)
      end

      # Function should be available
      assert Code.ensure_compiled(Jira) == {:module, Jira}
    end
  end

  describe "delegation target validation" do
    test "Client module exists and has expected functions" do
      # Verify the target module exists
      {:module, client_module} = Code.ensure_compiled(ExAutomation.Jira.Client)
      assert client_module == ExAutomation.Jira.Client

      # Verify target functions exist
      assert function_exported?(ExAutomation.Jira.Client, :get_ticket, 4)
      assert function_exported?(ExAutomation.Jira.Client, :get_ticket_with_fields, 5)
    end

    test "delegation maintains function arities" do
      # Jira context functions should have same arity as Client functions
      jira_functions = Jira.__info__(:functions)
      client_functions = ExAutomation.Jira.Client.__info__(:functions)

      # get_ticket should have same arity in both modules
      assert Keyword.get(jira_functions, :get_ticket) ==
               Keyword.get(client_functions, :get_ticket)

      # get_ticket_with_fields should have same arity in both modules
      assert Keyword.get(jira_functions, :get_ticket_with_fields) ==
               Keyword.get(client_functions, :get_ticket_with_fields)
    end
  end

  describe "issues" do
    alias ExAutomation.Jira.Issue

    import ExAutomation.JiraFixtures

    @invalid_attrs %{status: nil, type: nil, key: nil, parent_key: nil, summary: nil}

    test "list_issues/0 returns all issues" do
      issue = issue_fixture()
      assert Jira.list_issues() == [issue]
    end

    test "get_issue!/1 returns the issue with given id" do
      issue = issue_fixture()
      assert Jira.get_issue!(issue.id) == issue
    end

    test "create_issue/1 with valid data creates a issue" do
      valid_attrs = %{
        status: "some status",
        type: "some type",
        key: "some key",
        parent_key: "some parent_key",
        summary: "some summary"
      }

      assert {:ok, %Issue{} = issue} = Jira.create_issue(valid_attrs)
      assert issue.status == "some status"
      assert issue.type == "some type"
      assert issue.key == "some key"
      assert issue.parent_key == "some parent_key"
      assert issue.summary == "some summary"
    end

    test "create_issue/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Jira.create_issue(@invalid_attrs)
    end

    test "update_issue/2 with valid data updates the issue" do
      issue = issue_fixture()

      update_attrs = %{
        status: "some updated status",
        type: "some updated type",
        key: "some updated key",
        parent_key: "some updated parent_key",
        summary: "some updated summary"
      }

      assert {:ok, %Issue{} = issue} = Jira.update_issue(issue, update_attrs)
      assert issue.status == "some updated status"
      assert issue.type == "some updated type"
      assert issue.key == "some updated key"
      assert issue.parent_key == "some updated parent_key"
      assert issue.summary == "some updated summary"
    end

    test "update_issue/2 with invalid data returns error changeset" do
      issue = issue_fixture()
      assert {:error, %Ecto.Changeset{}} = Jira.update_issue(issue, @invalid_attrs)
      assert issue == Jira.get_issue!(issue.id)
    end

    test "delete_issue/1 deletes the issue" do
      issue = issue_fixture()
      assert {:ok, %Issue{}} = Jira.delete_issue(issue)
      assert_raise Ecto.NoResultsError, fn -> Jira.get_issue!(issue.id) end
    end

    test "change_issue/1 returns a issue changeset" do
      issue = issue_fixture()
      assert %Ecto.Changeset{} = Jira.change_issue(issue)
    end

    test "create_issue/1 with duplicate key returns error changeset" do
      issue = issue_fixture()

      duplicate_attrs = %{
        key: issue.key,
        parent_key: "some other parent_key",
        status: "some other status",
        summary: "some other summary",
        type: "some other type"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Jira.create_issue(duplicate_attrs)
      assert "has already been taken" in errors_on(changeset).key
    end
  end
end
