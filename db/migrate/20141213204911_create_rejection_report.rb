class CreateRejectionReport < ActiveRecord::Migration

  def up
    execute <<-SQL
      drop view if exists rejection_reasons;
      drop view if exists report_rejection_reasons;

      create view rejection_reasons as
        with

        monthly as (
          select      count(rejections.id),
                      reason,
                      date_part('month', rejections.created_at) as month
          from        rejections
          where       date_part('year', rejections.created_at) = date_part('year', current_date)
          group by    reason,
                      date_part('month', rejections.created_at)
        ),

        yearly as (
          select      count(rejections.id),
                      reason,
                      13 as month
          from        rejections
          where       date_part('year', rejections.created_at) = date_part('year', current_date)
          group by    reason
        )

        select * from monthly
        union
        select * from yearly;

      create view report_rejection_reasons as
        select * from crosstab(
          'select reason, month, count from rejection_reasons order by reason',
          'select m from generate_series(1,13) m'
        ) as (
          "reason" text,
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
          "dec" int,
          "ytd" int
        );
    SQL
  end

  def down
    execute 'drop view if exists report_rejection_reasons'
    execute 'drop view if exists rejection_reasons'
  end

end
