class FixSlugColumnInCompanies < ActiveRecord::Migration[8.0]
  def up
    # Mark the CreateCompanies migration as executed since the table already exists
    execute "INSERT INTO schema_migrations (version) VALUES ('20250806182330') ON CONFLICT (version) DO NOTHING;"
    
    # Only add the slug column if it doesn't already exist
    unless column_exists?(:companies, :slug)
      add_column :companies, :slug, :string
      add_index :companies, :slug, unique: true
    end
  end

  def down
    # This migration is not reversible since we're fixing a state issue
  end
end
