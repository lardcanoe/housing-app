defmodule HousingApp.Util.FilterTests do
  @moduledoc false

  use HousingApp.DataCase

  describe "Utils.Filters.ash_filter_to_react_query" do
    test "One filter" do
      query = HousingApp.Utils.Filters.ash_filter_to_react_query(%{"and" => %{"major" => "EE"}})
      assert %{rules: [%{value: "EE", operator: "=", field: "major"}], combinator: "and"} == query
    end

    test "Nested filter" do
      query = HousingApp.Utils.Filters.ash_filter_to_react_query(%{"and" => %{"location" => %{"city" => "Tallinn"}}})

      assert %{
               rules: [%{value: "Tallinn", operator: "=", field: "location.city"}],
               combinator: "and"
             } == query
    end

    test "Overlapped Nested filters" do
      query =
        HousingApp.Utils.Filters.ash_filter_to_react_query(%{
          "and" => %{
            "major" => "EE",
            "location" => %{"city" => "Tallinn", "state" => "MA", "phone" => %{"cell" => "222-333-4444"}}
          }
        })

      assert %{
               rules: [
                 %{value: "Tallinn", operator: "=", field: "location.city"},
                 %{value: "222-333-4444", operator: "=", field: "location.phone.cell"},
                 %{value: "MA", operator: "=", field: "location.state"},
                 %{value: "EE", operator: "=", field: "major"}
               ],
               combinator: "and"
             } == query
    end
  end

  describe "Utils.Filters.react_query_to_ash_filter Profile" do
    test "One filter" do
      filter =
        HousingApp.Utils.Filters.react_query_to_ash_filter(
          "profile",
          %{
            "rules" => [%{"value" => "EE", "operator" => "=", "field" => "major"}],
            "combinator" => "and"
          }
        )

      assert %{"and" => %{"major" => "EE"}} == filter
    end

    test "Two filters" do
      filter =
        HousingApp.Utils.Filters.react_query_to_ash_filter(
          "profile",
          %{
            "rules" => [
              %{"value" => "EE", "operator" => "=", "field" => "major"},
              %{"value" => 42, "operator" => "=", "field" => "age"}
            ],
            "combinator" => "or"
          }
        )

      assert %{"or" => %{"age" => 42, "major" => "EE"}} == filter
    end
  end

  describe "Utils.Filters.react_query_to_ash_filter Booking" do
    test "One filter" do
      filter =
        HousingApp.Utils.Filters.react_query_to_ash_filter(
          "booking",
          %{
            "rules" => [%{"value" => "EE", "operator" => "=", "field" => "major"}],
            "combinator" => "and"
          }
        )

      assert %{"and" => %{"major" => "EE"}} == filter
    end

    test "Two filters" do
      filter =
        HousingApp.Utils.Filters.react_query_to_ash_filter(
          "booking",
          %{
            "rules" => [
              %{"value" => "EE", "operator" => "=", "field" => "major"},
              %{"value" => 42, "operator" => "=", "field" => "age"}
            ],
            "combinator" => "or"
          }
        )

      assert %{"or" => %{"age" => 42, "major" => "EE"}} == filter
    end

    test "Nested filters" do
      filter =
        HousingApp.Utils.Filters.react_query_to_ash_filter(
          "booking",
          %{
            "rules" => [
              %{"value" => "Boston", "operator" => "=", "field" => "location.city"},
              %{"value" => "222-333-4444", "operator" => "=", "field" => "location.phone.cell"},
              %{"value" => 42, "operator" => "=", "field" => "age"}
            ],
            "combinator" => "and"
          }
        )

      assert %{
               "and" => %{
                 "age" => 42,
                 "location" => %{"city" => "Boston", "phone" => %{"cell" => "222-333-4444"}}
               }
             } == filter
    end
  end
end
