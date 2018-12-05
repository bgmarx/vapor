defmodule Vapor.Config.File do
  @moduledoc """
    Module for loading supported file format configs
    Supported file formats: .json, .toml, .yaml
  """

  defstruct path: nil, format: nil

  @type t :: %__MODULE__{
          path: binary(),
          format: format
        }

  @type format :: :json | :toml | :yaml

  @spec with_name(String.t()) :: t
  def with_name(name) do
    %__MODULE__{path: name, format: format(name)}
  end

  @spec format(String.t()) :: atom
  defp format(path) do
    case Path.extname(path) do
      "" ->
        raise Vapor.FileFormatNotFoundError, path

      ".json" ->
        :json

      ".toml" ->
        :toml

      ".yaml" ->
        :yaml
    end
  end

  defimpl Vapor.Provider do
    @spec load(map) :: {:error, String.t()} | {:ok, %{binary() => map}}
    def load(%{path: path, format: format}) do
      case File.read(path) do
        {:ok, str} ->
          case format do
            :json ->
              Jason.decode(str)

            :toml ->
              Toml.decode(str)

            :yaml ->
              YamlElixir.read_from_string(str)
          end

        {:error, _} ->
          raise Vapor.FileNotFoundError, path
      end
    end
  end
end
