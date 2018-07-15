#
#  Created by Boyd Multerer April 30, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# convenience functions for adding basic components to a graph.
# this module should be updated as new base components are added

defmodule Scenic.Components do
  alias Scenic.Component
  alias Scenic.Graph

  # import IEx

  @moduledoc """
  A set of helper functions to make it easy to add, or modify, components
  to a graph.


  In general, each helper function is of the form
      def name_of_component( graph, data, opts \\\\ [] )

  Unlike primitives, components are scenes in themselves. Each component
  is is run by a GenServer and adding a basic component does two things.

    1) A new component GenServer is started and supervised by the owning
    scene's dynamic scene supervisor.
    2) A reference to the new scene is added to the graph.

  This doesn't happen all at once. These helper functions simply add
  a reference to a to-be-started component to your graph. When you call
  push_graph/1 to send this graph to be rendered, these components are
  picked up, mapped to the host scene and started.

  You can also supervise components yourself, but then you should add
  the scene_ref yourself via the scene_ref/3 function, which is in the
  Scenice.Primitives module.

  When adding components to a graph, each helper function accepts a
  graph as the first parameter and returns the transformed graph. This
  makes is very easy to buid a complex graph by piping helper functions
  together.

      @graph Graph.build()
      |> button( {"Press Me", :btn_pressed}, id: :btn_id )

  When modifying a graph, you can again use the helpers by passing
  in the component to be modified. The transformed component will
  be returned.

      Graph.modify(graph, :btn_id, fn(p) ->
        button(p, {"Continue", :btn_pressed})
      end)

      # or, more compactly...

      Graph.modify(graph, :btn_id, &button(&1, {"Continue", :btn_pressed}) )

  In each case, the second parameter is a data term that is specific
  to the component being acted on. See the documentation below. If you
  pass in invalid data for the second parameter an error will be 
  thrown along with some explanation of what it expected.

  The third parameter is a keyword list of options that are to be
  applied to the component. This includes setting the id, styles,
  transforms and such.

      @graph Graph.build()
      |> button( {"Press Me", :btn_pressed}, id: :btn_id, rotate: 0.4)


  ### Event messages

  Most basic or input components exist to collect data and/or send
  messages to the host scene that references.

  For example, when a button scene decides that it has been "clicked",
  the generic button component doesn't know how to do anything with that
  information. So it sends a `{:click, button_id}` to the host scene
  that referenced it.

  That scene can intercept the message, act on it, transform it, and/or
  send it up to the host scene that references it. (Components can be
  nested many layers deep)

  To do this, the **host scene** should implement the `filter_event` callback.

  examples:

        def filter_event( {:click, :example_id}, _, state ) do
          {:stop, state }
        end

        def filter_event( {:click, :example_id}, _, state ) do
          {:continue, {:click, :transformed}, state }
        end

  Inside a filter_event callback you can modify a graph, change state,
  send messages, transform the event, stop the event, and much more.


  ### Style options

  Because components are seperate scenes, they generally do not inherit
  the styles set by the host scene that references them. This makes sense
  as most components should have a consistent look and feel regardless
  of the font style or fill set by the host.

  If you want to stylize a component, check the docs for that module.
  Most of them have options allowing you to do that as appropriate.

  ### Transform options

  Transform options set on the host do affect any components they refernce.

  These options affect the size, position and rotation of elements in the
  graph. Any transform you can express as a 4x4 matrix of floats, you can apply
  to any component in the graph, including groups and scene_refs.

  This is done mathematically as a "stack" of transforms. As the renderer
  traverses up and down the graph, transforms are pushed and popped from the
  matrix stack as appropriate. Transform inheritence does cross SceneRef
  boundaries.

  ## Draw Order
  
  Primitives will be drawn in the order you add them to the graph.
  For example, the graph below draws a buttonon top of a filled rectangle.
  If the order of the text and rectangle were reversed, they would both
  still be rendered, but the buuton would not be visible because the
  rectangle would cover it up.

      @graph Graph.build( font: {:roboto, 20} )
      |> rect( {100, 200}, color: :blue )
      |> button( {"Press Me", :btn_pressed})
  """


  #--------------------------------------------------------
  @doc """
  Add a button to a graph

  A button is a small scene that is pretty much just some text
  drawn over a rounded rectangle. The button scene contains logic to detect
  when the button is pressed, tracks it as the pointer moves around, and
  when it is released.

  Data:

      {text, id, options \\\\ []}

  * `text` must be a bitstring
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `options` should be a list of options (see below). It is not required.

  ### Messages

  If a button press is successful, it sends an event message to the host
  scene in the form of:

      {:click, id}

  Where the button id is the term you specified when you created
  the button. The id doesn't need to be an atom. It can be any
  term you want to send. Even something complicated.


  ### Options

  Buttons honor the following list of options.

  * `:type` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:primary`, `:secondary`, `:success`, `:danger`,
  `:warning`, `:info`, `:light`, `:dark`, `:text` or it can be a completly custom
  scheme like this: `{text_color, button_color, pressed_color}`.
  * `:width` - pass in a number to set the width of the button.
  * `:height` - pass in a number to set the height of the button.
  * `:radius` - pass in a number to set the radius of the button's rounded rectangle.
  * `:align` - set the aligment of the text inside the button. Can be one of
  `:left, :right, :center`. The default is `:center`.


  ### Styles

  Buttons honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a simple button and positions it on the screen.

      graph
      |> button( {"Example", :example_id}, translate: {20, 20} )

  The next example makes the same button as before, but colors it as a warning button. See
  the options list above for more details.

      graph
      |> button( {"Example", :example_id, type: :warning}, translate: {20, 20} )


  """
  def button( graph_or_primitive, data, opts \\ [] )

  def button( %Graph{} = g, data, opts ) do
    add_to_graph( g, Component.Button, data, opts )
  end

  #--------------------------------------------------------
  @doc """
  Add a checkbox to a graph

  Data:

      {text, id, checked?, options \\\\ []}

  * `text` must be a bitstring
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `checked?` must be a boolean and indicates if the checkbox is set.
  * `options` should be a list of options (see below). It is not required


  ### Messages

  When the state of the checkbox, it sends an event message to the host
  scene in the form of:

      {:value_changed, checkbox_id, checked?}

  Where the checkbox id is the term you specified when you created
  the button. The id doesn't need to be an atom. It can be any
  term you want to send. Even something complicated.


  ### Options

  Buttons honor the following list of options.

  * `:type` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completly custom
  scheme like this: `{text_color, box_background, border_color, pressed_color, checkmark_color}`.

  ### Styles

  Buttons honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a checkbox and positions it on the screen.

      graph
      |> checkbox( {"Example", :example_id, true}, translate: {20, 20} )

  """
  def checkbox( graph_or_primitive, data, opts \\ [] )

  def checkbox( %Graph{} = g, data, opts ) do
    add_to_graph( g, Component.Input.Checkbox, data, opts )
  end


  #--------------------------------------------------------
  @doc """
  Add a radio group to a graph

  Data:

      {items, group_id}

  * `items` must be a list of radio button data. See below.
  * `id` can be any term you want. It will be passed back to you during event messages.

  The `items` term must be a list of RadioButton init data.

  Radio button data:

      {text, button_id, checked? \\\\ false, options \\\\ []}

  * `text` must be a bitstring
  * `button_id` can be any term you want. It will be passed back to you as the group's value.
  * `checked?` must be a boolean and indicates if the button is selected. `checked?` is not
  required and will default to `false` if not supplied.
  * `options` should be a list of options (see below). It is not required


  ### Messages

  When the state of the radio group changes, it sends an event message to the host
  scene in the form of:

      {:value_changed, group_id, button_id}

  Where the `group_id` is the term you specified when you created
  the radio group and the `button_id` is the id of the button that is now selected


  ### Options

  Buttons honor the following list of options.

  * `:type` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completly custom
  scheme like this: `{text_color, box_background, border_color, pressed_color, checkmark_color}`.

  ### Styles

  Buttons honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a radio group and positions it on the screen.

      graph
      |> radio_group({[
          {"Radio A", :radio_a},
          {"Radio B", :radio_b, true},
          {"Radio C", :radio_c},
        ], :id },
        translate: {20, 20} )

  """
  def radio_group( graph_or_primitive, data, opts \\ [] )

  def radio_group( %Graph{} = g, data, opts ) do
    add_to_graph( g, Component.Input.RadioGroup, data, opts )
  end


  #--------------------------------------------------------
  @doc """
  Add a slider to a graph

  Data:

      { extents, initial_value, id, opts \\\\ [] }

  * `extents` gives the range of values. It can take several forms...
    * `{min,max}` If min and max are integers, then the slider value will be an integer.
    * `{min,max}` If min and max are floats, then the slider value will be an float.
    * `[a, b, c]` A list of terms. The value will be one of the terms
  * `initial_value` Sets the intial value (and position) of the slider. It must make
  sense with the extents you passed in.
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `options` should be a list of options (see below). It is not required

  ### Messages

  When the state of the slider changes, it sends an event message to the host
  scene in the form of:

      {:value_changed, id, value}


  ### Options

  Sliders honor the following list of options.

  * `:type` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completly custom
  scheme like this: `{line_color, thumb_color}`.

  ### Styles

  Sliders honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a numeric sliderand positions it on the screen.

      graph
      |> Component.Input.Slider.add_to_graph( {{0,100}, 0, :num_slider}, translate: {20,20} )

  The following example creates a list slider and positions it on the screen.

      graph
      |> Component.Input.Slider.add_to_graph( {[
          :white,
          :cornflower_blue,
          :green,
          :chartreuse
        ], :cornflower_blue, :list_slider}, translate: {20,20} )

  """
  def slider( graph_or_primitive, data, opts \\ [] )

  def slider( %Graph{} = g, data, opts ) do
    add_to_graph( g, Component.Input.Slider, data, opts )
  end


  #============================================================================
  # generic workhorse versions

  defp add_to_graph( %Graph{} = g, mod, data, opts ) do
    mod.verify!(data)
    mod.add_to_graph(g, data, opts)
  end

  # defp modify( %Primitive{module: mod} = p, data, opts ) do
  #   mod.verify!(data)
  #   p
  #   |> Primitive.put( data )
  #   |> Primitive.update_opts( opts )
  # end


end





