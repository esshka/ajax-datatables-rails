# require 'rails'

class AjaxDatatablesRails
  
  class MethodError < StandardError; end

  VERSION = '0.0.10'
    
  attr_reader :columns, :model_name, :searchable_columns, :filters_parameter

  def initialize(view)
    @view = view
  end

  def method_missing(meth, *args, &block)
    @view.send(meth, *args, &block)
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: @model_name.count,
      iTotalDisplayRecords: filtered_record_count,
      aaData: data
    }
  end

private

  def data
    raise MethodError, "The method `data' is not defined."
  end

  def get_raw_records
    raise MethodError, "The method `get_raw_records' is not defined."
  end

  def get_raw_record_count
    search_records(get_raw_records).count
  end

  def filtered_record_count
    search_records(filter_records(get_raw_records)).count
  end

  def fetch_records
    search_records(filter_records(sort_records(paginate_records(get_raw_records))))
  end

  def paginate_records(records)
    records.page(page).per_page(per_page)
  end

  def search_records(records)
    if params[:sSearch].present?
      query = @searchable_columns.map do |column|
        "#{column} LIKE :search"
      end.join(" OR ")
      records = records.where(query, search: "%#{params[:sSearch]}%")
    end
    return records
  end

  def sort_records(records)
    records.order_by(sort_column.to_s => sort_direction)
  end

  def filter_records(records, filters = nil)
    filters ||= @filters_parameter ? @view.request.filtered_parameters[@filters_parameter.to_s] : nil
    if @model_name.respond_to? :filter_criteria
      records.where(@model_name.filter_criteria(filters))
    else
      records
    end
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    @columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? 1 : -1
  end

end
