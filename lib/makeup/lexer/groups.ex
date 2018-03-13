defmodule Makeup.Lexer.Groups do
  defp make_match([] = _patterns, _varnames, rest_of_tokens_varname) do
    quote do
      unquote(Macro.var(rest_of_tokens_varname, __MODULE__))
    end
  end

  defp make_match([pattern | patterns], [varname | varnames], rest_of_tokens_varname) do
    var = Macro.var(varname, __MODULE__)
    quote do
      [unquote(pattern) = unquote(var) | unquote(make_match(patterns, varnames, rest_of_tokens_varname))]
    end
  end

  defp put_group_ids([], _group_id_varname) do
    quote(do: [])
  end

  defp put_group_ids(tokens, group_id_varname) do
    group_id = Macro.var(group_id_varname, __MODULE__)

    for {ttype_varname, attr_varname, text_varname} <- tokens do
      ttype = Macro.var(ttype_varname, __MODULE__)
      attr = Macro.var(attr_varname, __MODULE__)
      text = Macro.var(text_varname, __MODULE__)

      quote do
        {
          unquote(ttype),
          Map.put(
            unquote(attr),
            # The Map key (an atom)
            unquote(group_id_varname),
            # The variable holding the value
            unquote(group_id)
          ),
          unquote(text)
        }
      end
    end
  end

  defp open_branch(stack_name, pattern, group_prefix_varname, group_nr_varname) do
    group_nr = Macro.var(group_nr_varname, __MODULE__)
    group_prefix = Macro.var(group_prefix_varname, __MODULE__)
    group_id = Macro.var(:group_id, __MODULE__)
    rest_of_tokens = Macro.var(:rest_of_tokens, __MODULE__)

    n = length pattern

    token_varnames = for i <- 1..n, do: String.to_atom "token__#{i}"
    ttype_varnames = for i <- 1..n, do: String.to_atom "ttype__#{i}"
    attr_varnames = for i <- 1..n, do: String.to_atom "attr__#{i}"
    text_varnames = for i <- 1..n, do: String.to_atom "text__#{i}"
    tokens_data = List.zip([token_varnames, ttype_varnames, attr_varnames, text_varnames])

    pattern_matches =
      for {token_varname, ttype_varname, attr_varname, text_varname} <- tokens_data  do
        token = Macro.var(token_varname, __MODULE__)
        ttype = Macro.var(ttype_varname, __MODULE__)
        attr = Macro.var(attr_varname, __MODULE__)
        text = Macro.var(text_varname, __MODULE__)

        quote do
          {unquote(ttype), unquote(attr), unquote(text)} = unquote(token)
        end
      end

    tokens_pattern = make_match(pattern, token_varnames, :rest_of_tokens)

    tokens_for_result = List.zip([ttype_varnames, attr_varnames, text_varnames])
    head_tokens = put_group_ids(tokens_for_result, :group_id)

    quote do
      {stack, unquote(tokens_pattern)} ->
        new_group_nr = unquote(group_nr) + 1
        unquote(group_id) = unquote(group_prefix) <> "-" <> to_string(new_group_nr)
        unquote_splicing(pattern_matches)
        head_tokens = unquote(head_tokens)
        head_of_stack = {unquote(stack_name), new_group_nr}
        new_stack = [head_of_stack | stack]
        {new_stack, new_group_nr, head_tokens, unquote(rest_of_tokens)}
    end
  end

  defp close_branch(stack_name, pattern, group_prefix_varname, group_nr_varname) do
    group_nr = Macro.var(group_nr_varname, __MODULE__)
    group_prefix = Macro.var(group_prefix_varname, __MODULE__)
    group_id = Macro.var(:group_id, __MODULE__)
    rest_of_stack = Macro.var(:rest_of_stack, __MODULE__)
    rest_of_tokens = Macro.var(:rest_of_tokens, __MODULE__)

    n = length pattern

    token_varnames = for i <- 1..n, do: String.to_atom "token__#{i}"
    ttype_varnames = for i <- 1..n, do: String.to_atom "ttype__#{i}"
    attr_varnames = for i <- 1..n, do: String.to_atom "attr__#{i}"
    text_varnames = for i <- 1..n, do: String.to_atom "text__#{i}"
    tokens_data = List.zip([token_varnames, ttype_varnames, attr_varnames, text_varnames])

    pattern_matches =
      for {token_varname, ttype_varname, attr_varname, text_varname} <- tokens_data  do
        token = Macro.var(token_varname, __MODULE__)
        ttype = Macro.var(ttype_varname, __MODULE__)
        attr = Macro.var(attr_varname, __MODULE__)
        text = Macro.var(text_varname, __MODULE__)

        quote do
          {unquote(ttype), unquote(attr), unquote(text)} = unquote(token)
        end
      end

    stack_pattern =
      quote do
        [{unquote(stack_name), current_group_nr} | unquote(rest_of_stack)]
      end
    tokens_pattern = make_match(pattern, token_varnames, :rest_of_tokens)

    tokens_for_result = List.zip([ttype_varnames, attr_varnames, text_varnames])
    head_tokens = put_group_ids(tokens_for_result, :group_id)

    quote do
      {unquote(stack_pattern), unquote(tokens_pattern)} ->
        unquote(group_id) = unquote(group_prefix) <> "-" <> to_string(current_group_nr)
        unquote_splicing(pattern_matches)
        head_tokens = unquote(head_tokens)
        {unquote(rest_of_stack), unquote(group_nr), head_tokens, unquote(rest_of_tokens)}
    end
  end

  defp middle_branch(stack_name, pattern, group_prefix_varname, group_nr_varname) do
    group_nr = Macro.var(group_nr_varname, __MODULE__)

    group_prefix = Macro.var(group_prefix_varname, __MODULE__)
    group_id = Macro.var(:group_id, __MODULE__)
    rest_of_stack = Macro.var(:rest_of_stack, __MODULE__)
    rest_of_tokens = Macro.var(:rest_of_tokens, __MODULE__)

    n = length pattern

    token_varnames = for i <- 1..n, do: String.to_atom "token__#{i}"
    ttype_varnames = for i <- 1..n, do: String.to_atom "ttype__#{i}"
    attr_varnames = for i <- 1..n, do: String.to_atom "attr__#{i}"
    text_varnames = for i <- 1..n, do: String.to_atom "text__#{i}"
    tokens_data = List.zip([token_varnames, ttype_varnames, attr_varnames, text_varnames])

    pattern_matches =
      for {token_varname, ttype_varname, attr_varname, text_varname} <- tokens_data  do
        token = Macro.var(token_varname, __MODULE__)
        ttype = Macro.var(ttype_varname, __MODULE__)
        attr = Macro.var(attr_varname, __MODULE__)
        text = Macro.var(text_varname, __MODULE__)

        quote do
          {unquote(ttype), unquote(attr), unquote(text)} = unquote(token)
        end
      end

    stack_pattern =
      quote do
        [{unquote(stack_name), current_group_nr} | unquote(rest_of_stack)]
      end
    tokens_pattern = make_match(pattern, token_varnames, :rest_of_tokens)

    tokens_for_result = List.zip([ttype_varnames, attr_varnames, text_varnames])
    head_tokens = put_group_ids(tokens_for_result, :group_id)

    quote do
      {unquote(stack_pattern) = stack, unquote(tokens_pattern)} ->
        unquote(group_id) = unquote(group_prefix) <> "-" <> to_string(current_group_nr)
        unquote_splicing(pattern_matches)
        head_tokens = unquote(head_tokens)
        {stack, unquote(group_nr), head_tokens, unquote(rest_of_tokens)}
    end
  end

  defp branches_for_stack({stack_name, parts}) do
    open_patterns = Keyword.fetch!(parts, :open)
    middle_patterns = Keyword.get(parts, :middle, [])
    close_patterns = Keyword.fetch!(parts, :close)

    open_branches_ast = Enum.map(open_patterns,
      fn pattern -> open_branch(stack_name, pattern, :group_prefix, :group_nr)
    end)

    middle_branches_ast = Enum.map(middle_patterns,
      fn pattern -> middle_branch(stack_name, pattern, :group_prefix, :group_nr)
    end)

    close_branches_ast = Enum.map(close_patterns,
      fn pattern -> close_branch(stack_name, pattern, :group_prefix, :group_nr)
    end)

    open_branches_ast ++ middle_branches_ast ++ close_branches_ast
  end

  defmacro defgroupmatcher(name, stacks, opts \\ []) do
    name_helper =
      name
      |> Atom.to_string
      |> Kernel.<>("__helper")
      |> String.to_atom

    branches =
      stacks
      |> Enum.map(&branches_for_stack/1)
      |> List.flatten

    group_nr = Macro.var(:group_nr, __MODULE__)

    unmatched_token_branch =
      quote do
        {old_stack, [token | toks]} ->
          {old_stack, unquote(group_nr), [token], toks}
      end

    no_more_tokens_branch =
      quote do
        {old_stack, []} ->
          {old_stack, unquote(group_nr), [], []}
      end

    all_branches = branches ++ unmatched_token_branch ++ no_more_tokens_branch

    expr = quote do
      defp unquote(name_helper)(stack, tokens, group_prefix, group_nr) do
        {new_stack, new_group_nr, head_tokens, rest_of_tokens} =
          case {stack, tokens} do
            unquote(all_branches)
          end

        case head_tokens do
          [] ->
            []

          _ ->
            head_tokens ++ unquote(name_helper)(new_stack, rest_of_tokens, group_prefix, new_group_nr)
        end
      end

      @doc false
      def unquote(name)(tokens, group_prefix \\ "group") do
        unquote(name_helper)([], tokens, group_prefix, 0)
      end
    end

    if Keyword.get(opts, :debug) do
      expr
      |> Macro.to_string
      |> Code.format_string!
      |> IO.puts
    end

    expr
  end

  def random_prefix(n), do: Enum.map(1..n, fn _ -> Enum.random(?0..?9) end) |> to_string
end
