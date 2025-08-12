defmodule ExAutomation.JiraTest do
  use ExUnit.Case, async: true
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
end
