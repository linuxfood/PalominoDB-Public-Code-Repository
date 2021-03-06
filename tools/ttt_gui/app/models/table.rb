require 'ttt'
require 'ttt/collector'
require 'ttt/server'

class Table
  attr_reader :server
  attr_reader :database
  attr_reader :name
  attr_reader :stats
  def self.find(server,db,name)
    stats={}
    TTT::TrackingTable.tables.each do |s,k|
      stats[s]=k.find(:last, :conditions => ["server = ? and database_name = ? and table_name = ?", server, db, name])
    end
    self.new(server,db,name,stats)
  end

  def self.find_at(server,db,name,at)
    stats={}
    TTT::TrackingTable.tables.each do |s,k|
      stats[s]=k.find(:last, :conditions => ["server = ? and database_name = ? and table_name = ? and run_time = ?", server, db, name, Time.at(at.to_i)])
    end
    self.new(server,db,name,stats)
  end

  def get_volume
    @stats[:volume]
  end

  def stats?
    @stats[:definition] || @stats[:view] || @stats[:volume]
  end

  def size
    (table_type == :base and !@stats[:volume].nil?) ? @stats[:volume].size : nil
  end

  def get_history(since=Time.at(0))
    r={}
    @stats.each do |k,v|
      r[k] = v.history(since) unless v.nil?
    end
    r
  end

  def table_name
    name
  end

  def created_at
    table_type == :base ? @stats[:definition].created_at : @stats[:view].run_time
  end

  def run_time
    table_type == :base ? @stats[:definition].run_time : @stats[:view].run_time
  end

  def previous_version
    table_type == :base ? @stats[:definition].previous_version : @stats[:view].previous_version
  end

  def create_syntax
    get_create
  end

  def get_create
    if table_type == :base
      @stats[:definition].create_syntax
    elsif table_type == :view
      @stats[:view].create_syntax
    else
      nil
    end
  end

  def table_type
    type=:base
    if @stats[:definition].nil? and @stats[:view].nil?
      type=:unknown
    elsif @stats[:definition].nil? and @stats[:view]
      type=:view
    end
    type
  end

  private
  def initialize(server,database,name,stats)
    @server=server
    @database=database
    @name=name
    @stats=stats
  end
end
