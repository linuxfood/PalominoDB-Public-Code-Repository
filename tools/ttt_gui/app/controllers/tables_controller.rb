require 'ttt'
require 'ttt/collector'
require 'ttt/table'

class TablesController < ApplicationController
  def show
    @show_diff=false
    @show_diff=true if params[:show_diff]
    if params[:at]
      @table=Table.find_at(params[:server_id], params[:database_id], params[:id], params[:at])
    else
      @table=Table.find(params[:server_id], params[:database_id], params[:id])
    end
    r=Rrdtool.new
    r.table_graph(@table, @since_string, :full)
  end

end
