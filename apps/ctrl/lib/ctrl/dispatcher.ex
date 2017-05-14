defmodule Ctrl.Dispatcher do
  @moduledoc """
  A Register based dispatcher for samples.
  """

  @registry SampleNotification

  def start_link() do
    GenEvent.start_link([name: @registry])
  end

  @doc """
  Listen to events generated by the controller and expose them as a stream of events.
  A `{id, sample}` tuple is returned.
  """
  def stream do
    GenEvent.stream(@registry)
  end

  def notify(sample) do
    GenEvent.notify(@registry, sample)
  end

end
