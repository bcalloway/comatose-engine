#
# This migration adds a table for pages and its correspoding version
# table for acts_as_versioned.
#
class ComatosePage < ActiveRecord::Base
  set_table_name 'comatose_pages'

  acts_as_versioned :table_name => 'comatose_page_versions',
                    :if_changed => [:title, :slug, :keywords, :body]
end


class AddComatoseSupport < ActiveRecord::Migration

  # Schema for Comatose version 0.8+
  def self.up
    create_table :comatose_pages, :force => true do |t|
      t.integer    "parent_id"
      t.text       "full_path",   :default => ""
      t.string     "title",       :limit => 255
      t.string     "slug",        :limit => 255
      t.string     "keywords",    :limit => 255
      t.text       "body"
      t.string     "filter_type", :limit => 25, :default => "Textile"
      t.string     "author",      :limit => 255
      t.integer    "position",    :default => 0
      t.integer    "version"
      t.string     "state"
      t.integer    "role-id"
      t.date       "created_on"
      t.date       "updated_on"
      t.timestamps
      t.references "author_user"
    end

    ComatosePage.create_versioned_table
    puts "Creating the default 'Home Page'..."
    ComatosePage.create(
        :title  => 'Home Page',
        :body   => File.open(
                 File.join(RAILS_ROOT, "vendor" , "plugins", "comatose_engine",
                           "UserManual.textile")).read,
        :author => 'System'.
        :state => "approved" )
  end

  def self.down
    ComatosePage.drop_versioned_table
    drop_table :comatose_pages
  end

end
