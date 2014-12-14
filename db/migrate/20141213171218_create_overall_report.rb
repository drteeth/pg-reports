class CreateOverallReport < ActiveRecord::Migration

  def up
    execute <<-SQL
      create view overall as
        select      count(rejections.id),
                    date_part('month', rejections.created_at) as month
        from        rejections
        where       date_part('year', rejections.created_at) = date_part('year', current_date)
        group by    date_part('month', rejections.created_at);

      create view report_overall as
        select * from crosstab(
          'select ''overall'', month, count from overall',
          'select m from generate_series(1,12) m'
        ) as (
          "overall" text,
          "jan" int,
          "feb" int,
          "mar" int,
          "apr" int,
          "may" int,
          "jun" int,
          "jul" int,
          "aug" int,
          "sep" int,
          "oct" int,
          "nov" int,
          "dec" int
        );
    SQL
  end

  def down
    execute 'drop view if exists report_overall'
    execute 'drop view if exists overall'
  end

end
