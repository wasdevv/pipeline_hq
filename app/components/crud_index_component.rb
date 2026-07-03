# frozen_string_literal: true

class CrudIndexComponent < ViewComponent::Base
  Column = Data.define(:label, :value, :align)

  def initialize(
    title:,
    subtitle: nil,
    records:,
    columns:,
    new_path:,
    new_label:,
    show_path:,
    edit_path:,
    delete_label: "Apagar",
    delete_confirm: "Apagar este registro?",
    empty_icon: :inbox,
    empty_title: "Nada por aqui ainda",
    empty_description: nil,
    empty_action_label: nil
  )
    @title = title
    @subtitle = subtitle
    @records = records
    @columns = columns.map { |c| Column.new(label: c[:label], value: c[:value], align: c[:align] || :left) }
    @new_path = new_path
    @new_label = new_label
    @show_path = show_path
    @edit_path = edit_path
    @delete_label = delete_label
    @delete_confirm = delete_confirm
    @empty_icon = empty_icon
    @empty_title = empty_title
    @empty_description = empty_description
    @empty_action_label = empty_action_label
  end

  def col_class(column)
    column.align == :right ? "px-4 py-3 text-right" : "px-4 py-3"
  end

  def cell_value(record, column)
    column.value.call(record)
  end
end
