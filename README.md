```sh
# create a posts model
rails g model Post body:text

# create a rejections model
rails g model Rejection post:references reason:integer
```

```ruby
class Rejection < ActiveRecord::Base
  belongs_to :post

  enum reason: [ :spam, :boring, :mansplaining ]
end

# add seed data
20.times.map { Lorem::Base.new(:paragraphs, 1).output }
        .map { |text| Post.create! body:text }
        .map { |post| Rejection.create! post:post, reason:rand(2) }
```

```sh
# enable tablefunc extension for crosstab support
$ create extension if not exists tablefunc;
```

explain crosstab basics
explain crosstab with 2 args

```sql
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

select * from report_overall;
 overall | jan | feb | mar | apr | may | jun | jul | aug | sep | oct | nov | dec
---------+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----
 overall |   2 |   1 |   2 |     |   1 |   2 |   1 |   4 |     |   4 |   2 |   1
```

add YTD
talk about union, matching column output

```sql
create view overall as
  select      count(rejections.id),
              date_part('month', rejections.created_at) as month
  from        rejections
  where       date_part('year', rejections.created_at) = date_part('year', current_date)
  group by    date_part('month', rejections.created_at)

  union

  select      count(rejections.id),
              13 as month
  from        rejections
  where       date_part('year', rejections.created_at) = date_part('year', current_date);

create view report_overall as
  select * from crosstab(
    'select ''overall'', month, count from overall',
    'select m from generate_series(1,13) m'
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
    "dec" int,
    "ytd" int
  );
```

```sql
select * from report_overall;
 overall | jan | feb | mar | apr | may | jun | jul | aug | sep | oct | nov | dec | ytd
---------+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----
 overall |   2 |   1 |   2 |     |   1 |   2 |   1 |   4 |     |   4 |   2 |   1 |  20
```

add breakdown by reason, also clean up with Common table expressions

```sql
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
    group by    reason;
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
```

```sql
select * from report_rejection_reasons;
 reason | jan | feb | mar | apr | may | jun | jul | aug | sep | oct | nov | dec | ytd
--------+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----
 0      |   1 |     |   2 |     |     |     |     |   1 |     |   2 |   2 |     |   8
 1      |   1 |     |     |     |   1 |   1 |     |   1 |     |   1 |     |     |   5
 2      |     |   1 |     |     |     |   1 |   1 |   2 |     |   1 |     |   1 |   7
```

## Use in rails:
```ruby
class RejectionReasonReport < ActiveRecord::Base
  self.table_name = 'report_rejection_reasons'

  def each_column(&block)
    %i(jan feb mar apr may jun jul aug sep oct nov dec ytd).map do |col|
      block.call public_send(col)
    end
  end

  def reason_text
    Rejection.reasons.invert[reason.to_i].titlecase # lol
  end
end

class ReportsController < ApplicationController

  def rejection_reasons
    @report = RejectionReasonReport.all
  end

end
```

```erb
<table>
  <thead>
    <th></th>
    <th>Jan</th>
    <th>Feb</th>
    <th>Mar</th>
    <th>Apr</th>
    <th>May</th>
    <th>Jun</th>
    <th>Jul</th>
    <th>Aug</th>
    <th>Sep</th>
    <th>Oct</th>
    <th>Nov</th>
    <th>Dec</th>
    <th>YTD</th>
  </thead>
  <tbody>
    <% @report.each do |row| %>
      <tr>
        <td><%= row.reason_text %></td>
        <% row.each_column do |col| %>
          <td><%= col %></td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>
```

![rejections by reason](https://raw.githubusercontent.com/drteeth/pg-reports/master/rejections_by_reason.png)
