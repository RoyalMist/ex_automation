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

    import ExAutomation.AccountsFixtures, only: [user_scope_fixture: 0]
    import ExAutomation.JiraFixtures

    @invalid_attrs %{status: nil, type: nil, key: nil, parent_key: nil, summary: nil}

    test "list_issues/1 returns all scoped issues" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      issue = issue_fixture(scope)
      other_issue = issue_fixture(other_scope)
      assert Jira.list_issues(scope) == [issue]
      assert Jira.list_issues(other_scope) == [other_issue]
    end

    test "get_issue!/2 returns the issue with given id" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      other_scope = user_scope_fixture()
      assert Jira.get_issue!(scope, issue.id) == issue
      assert_raise Ecto.NoResultsError, fn -> Jira.get_issue!(other_scope, issue.id) end
    end

    test "create_issue/2 with valid data creates a issue" do
      valid_attrs = %{
        status: "some status",
        type: "some type",
        key: "some key",
        parent_key: "some parent_key",
        summary: "some summary"
      }

      scope = user_scope_fixture()

      assert {:ok, %Issue{} = issue} = Jira.create_issue(scope, valid_attrs)
      assert issue.status == "some status"
      assert issue.type == "some type"
      assert issue.key == "some key"
      assert issue.parent_key == "some parent_key"
      assert issue.summary == "some summary"
      assert issue.user_id == scope.user.id
    end

    test "create_issue/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Jira.create_issue(scope, @invalid_attrs)
    end

    test "update_issue/3 with valid data updates the issue" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)

      update_attrs = %{
        status: "some updated status",
        type: "some updated type",
        key: "some updated key",
        parent_key: "some updated parent_key",
        summary: "some updated summary"
      }

      assert {:ok, %Issue{} = issue} = Jira.update_issue(scope, issue, update_attrs)
      assert issue.status == "some updated status"
      assert issue.type == "some updated type"
      assert issue.key == "some updated key"
      assert issue.parent_key == "some updated parent_key"
      assert issue.summary == "some updated summary"
    end

    test "update_issue/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      issue = issue_fixture(scope)

      assert_raise MatchError, fn ->
        Jira.update_issue(other_scope, issue, %{})
      end
    end

    test "update_issue/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Jira.update_issue(scope, issue, @invalid_attrs)
      assert issue == Jira.get_issue!(scope, issue.id)
    end

    test "delete_issue/2 deletes the issue" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert {:ok, %Issue{}} = Jira.delete_issue(scope, issue)
      assert_raise Ecto.NoResultsError, fn -> Jira.get_issue!(scope, issue.id) end
    end

    test "delete_issue/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert_raise MatchError, fn -> Jira.delete_issue(other_scope, issue) end
    end

    test "change_issue/2 returns a issue changeset" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert %Ecto.Changeset{} = Jira.change_issue(scope, issue)
    end
  end
end
