class AddExtensions < ActiveRecord::Migration
  def up
    execute 'create extension if not exists tablefunc;'
  end

  def down
    execute 'drop extension if exists tablefunc;'
  end

end
