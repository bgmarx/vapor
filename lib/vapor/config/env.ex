defmodule Vapor.Config.Env do
  @moduledoc """
  The Env config module provides support for pulling configuration values
  from the environment. It can do this by either specifying a prefix or by
  specifying specific bindings from keys to environment variables.

  ## Loading configuration by prefix

  If a prefix is used then the variable will be normalized by removing the
  prefix, downcasing the text, and converting all underscores into nested keys

  ## Loading with bindings

  Specific bindings be also be specified. They are case sensitive
  """

  defstruct prefix: :none, bindings: []

  @type bindings :: Keyword.t(String.t())

  @type t :: %__MODULE__{
          prefix: :none | String.t(),
          bindings: bindings
        }

  @spec with_prefix(String.t()) :: t
  def with_prefix(prefix) when is_binary(prefix) do
    %__MODULE__{prefix: build_prefix(prefix)}
  end

  @doc """
  Creates a configuration plan with explicit bindings.

  Env.with_bindings([foo: "FOO", bar: "BAR"])
  """
  @spec with_bindings(bindings()) :: t
  def with_bindings(opts) when is_list(opts) do
    %__MODULE__{
      prefix: :none,
      bindings: opts
    }
  end

  @spec build_prefix(String.t()) :: String.t()
  defp build_prefix(prefix), do: "#{prefix}_"

  defimpl Vapor.Provider do
    @spec load(map) :: {:error, String.t()} | {:ok, %{}}
    def load(%{prefix: :none, bindings: bindings}) do
      envs = System.get_env()

      bound_envs =
        bindings
        |> Enum.map(fn {key, env} -> {Atom.to_string(key), Map.get(envs, env, :missing)} end)
        |> Enum.into(%{})

      missing =
        bound_envs
        |> Enum.filter(fn {_, v} -> v == :missing end)

      if Enum.any?(missing) do
        {:error, missing}
      else
        {:ok, bound_envs}
      end
    end

    def load(%{prefix: prefix}) do
      env = System.get_env()

      prefixed_envs =
        env
        |> Enum.filter(&matches_prefix?(&1, prefix))
        |> Enum.map(fn {k, v} -> {normalize(k, prefix), v} end)
        |> Enum.into(%{})

      {:ok, prefixed_envs}
    end

    @spec normalize(String.t(), String.t()) :: String.t()
    defp normalize(str, prefix) do
      str
      |> String.replace_leading(prefix, "")
      |> String.downcase()
    end

    @spec matches_prefix?(tuple, String.t()) :: boolean()
    defp matches_prefix?({k, _v}, prefix) do
      String.starts_with?(k, prefix)
    end
  end
end
