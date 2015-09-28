class MakeRedirectsUnique < Mongoid::Migration
  def self.up
    redirects_by_from_path = Redirect.all.group_by(&:from_path)
    redirects_by_from_path.each do |from_path, redirects|
      if redirects.size > 1
        # This is in oldest => newest. We want to keep the newest.
        redirects_ordered_by_date = redirects.sort_by(&:created_at)
        # Select all but the most recent
        older_duplicates = redirects_ordered_by_date[0..-2]

        older_duplicates.each do |older_duplicate|
          older_duplicate.delete
        end
      end
    end
  end

  def self.down
  end
end