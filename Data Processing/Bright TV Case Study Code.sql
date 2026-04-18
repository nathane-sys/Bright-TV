--Confirming the exact table names
show tables in `workspace`.`default`;

--Previewing both tables
select *
from `workspace`.`default`.`viewership`
limit 10;


select *
from `workspace`.`default`.`user_profile`
limit 10;

--Check the columns
describe `workspace`.`default`.`viewership`;
describe `workspace`.`default`.`user_profile`;

--Create a joined base table
create or replace table `workspace`.`default`.`brighttv_joined` as
select
    v.userid,
    v.channel2,
    v.recorddate2,
    v.`Duration 2` as raw_duration,
    u.name,
    u.surname,
    u.email,
    u.gender,
    u.race,
    u.age,
    u.province,
    u.`Social Media Handle` as social_media_handle
from `workspace`.`default`.`viewership` v
left join `workspace`.`default`.`user_profile` u
on v.userid = u.userid;

--Preview the joined table
select *
from `workspace`.`default`.`brighttv_joined`
limit 20;


--Testing the timestamp conversion
select recorddate2,
       to_timestamp(recorddate2, 'yyyy/MM/dd HH:mm') as event_time_utc
from `workspace`.`default`.`viewership`
limit 20;


--testing the duration
select raw_duration,
hour(raw_duration) * 3600
+ minute(raw_duration) * 60
+ second(raw_duration) as duration_seconds
from `workspace`.`default`.`brighttv_joined`
limit 20;


--Creating the clean final table
create or replace table `workspace`.`default`.`brighttv_final` as
select
    userid,
    channel2 as channel,
    name,
    surname,
    email,
    gender,
    race,
    age,
    province,
    social_media_handle,
    raw_duration,

    to_timestamp(recorddate2, 'yyyy/MM/dd HH:mm') as event_time_utc,

    from_utc_timestamp(to_timestamp(recorddate2, 'yyyy/MM/dd HH:mm'),
        'Africa/Johannesburg') as event_time_sa,

    hour(raw_duration) * 3600
    + minute(raw_duration) * 60
    + second(raw_duration) as duration_seconds,

    date(from_utc_timestamp(to_timestamp(recorddate2, 'yyyy/MM/dd HH:mm'),
            'Africa/Johannesburg')) as watch_date,

    hour(from_utc_timestamp(to_timestamp(recorddate2, 'yyyy/MM/dd HH:mm'),
            'Africa/Johannesburg')) as watch_hour,

    dayofweek(from_utc_timestamp(to_timestamp(recorddate2, 'yyyy/MM/dd HH:mm'),
            'Africa/Johannesburg')) as day_of_week,

    case dayofweek(from_utc_timestamp(to_timestamp(recorddate2, 'yyyy/MM/dd HH:mm'),
            'Africa/Johannesburg'))
        when 1 then 'Sunday'
        when 2 then 'Monday'
        when 3 then 'Tuesday'
        when 4 then 'Wednesday'
        when 5 then 'Thursday'
        when 6 then 'Friday'
        when 7 then 'Saturday'
    end as day_name

from `workspace`.`default`.`brighttv_joined`;

--Check final table
select *
from `workspace`.`default`.`brighttv_final`
limit 20;

select
    channel,
    raw_duration,
    duration_seconds,
    watch_date,
    watch_hour,
    day_name,
    province,
    gender,
    age
from `workspace`.`default`.`brighttv_final`
limit 20;


------------------------------------------------
---Daily Active Users
------------------------------------------------
select watch_date,
       count(distinct userid) as active_users
from `workspace`.`default`.`brighttv_final`
group by watch_date
order by watch_date;


------------------------------------------------
---Daily total sessions
------------------------------------------------
select
    watch_date,
    count(*) as total_sessions
from `workspace`.`default`.`brighttv_final`
group by watch_date
order by watch_date;



------------------------------------------------
---Daily total watch time
------------------------------------------------
select
    watch_date,
    sum(duration_seconds) as total_watch_time_seconds,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    round(sum(duration_seconds) / 3600.0, 2) as total_watch_time_hours
from `workspace`.`default`.`brighttv_final`
group by watch_date
order by watch_date;



------------------------------------------------
---Sessions by hour
------------------------------------------------
select
    watch_hour,
    count(*) as total_sessions
from `workspace`.`default`.`brighttv_final`
group by watch_hour
order by watch_hour;




------------------------------------------------
---Watch time by hour
------------------------------------------------
select
    watch_hour,
    sum(duration_seconds) as total_watch_time_seconds,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes
from `workspace`.`default`.`brighttv_final`
group by watch_hour
order by watch_hour;



------------------------------------------------
---Day and hour combination
------------------------------------------------
select
    day_name,
    watch_hour,
    count(*) as total_sessions
from `workspace`.`default`.`brighttv_final`
group by day_name, watch_hour
order by
    case day_name
        when 'Monday' then 1
        when 'Tuesday' then 2
        when 'Wednesday' then 3
        when 'Thursday' then 4
        when 'Friday' then 5
        when 'Saturday' then 6
        when 'Sunday' then 7
    end,
    watch_hour;




------------------------------------------------
---Low-consumption days
------------------------------------------------
select
    day_name,
    count(*) as total_sessions,
    sum(duration_seconds) as total_watch_time_seconds,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    round(avg(duration_seconds), 2) as avg_session_duration_seconds
from `workspace`.`default`.`brighttv_final`
group by day_name
order by
    case day_name
        when 'Monday' then 1
        when 'Tuesday' then 2
        when 'Wednesday' then 3
        when 'Thursday' then 4
        when 'Friday' then 5
        when 'Saturday' then 6
        when 'Sunday' then 7
    end;

--lowest to highest watch time
    select
    day_name,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes
from `workspace`.`default`.`brighttv_final`
group by day_name
order by total_watch_time_minutes asc;



------------------------------------------------
---Most viewed channels
------------------------------------------------
select
    channel,
    count(*) as total_views
from `workspace`.`default`.`brighttv_final`
group by channel
order by total_views desc;



------------------------------------------------
---Channels with highest total watch time
------------------------------------------------
select
    channel,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    count(*) as total_views
from `workspace`.`default`.`brighttv_final`
group by channel
order by total_watch_time_minutes desc;


------------------------------------------------
---Channels with highest average watch time
------------------------------------------------
select
    channel,
    round(avg(duration_seconds), 2) as avg_watch_time_seconds,
    round(avg(duration_seconds) / 60.0, 2) as avg_watch_time_minutes,
    count(*) as total_views
from `workspace`.`default`.`brighttv_final`
group by channel
order by avg_watch_time_seconds desc;


---
select
    channel,
    round(avg(duration_seconds), 2) as avg_watch_time_seconds
from `workspace`.`default`.`brighttv_final`
group by channel
order by avg_watch_time_seconds desc
limit 10;

------------------------------------------------
---Top channels on low-consumption days
------------------------------------------------
select
    day_name,
    channel,
    count(*) as total_views,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes
from `workspace`.`default`.`brighttv_final`
where day_name in ('Monday', 'Tuesday', 'Wednesday', 'Thursday')
group by day_name, channel
order by
    case day_name
        when 'Monday' then 1
        when 'Tuesday' then 2
        when 'Wednesday' then 3
        when 'Thursday' then 4
    end,
    total_watch_time_minutes desc;


------------------------------------------------
---Top users by total watch time
------------------------------------------------
select
    userid,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    count(*) as total_sessions
from `workspace`.`default`.`brighttv_final`
group by userid
order by total_watch_time_minutes desc;


------------------------------------------------
---Average sessions per user
------------------------------------------------
select
    round(count(*) * 1.0 / count(distinct userid), 2) as avg_sessions_per_user
from `workspace`.`default`.`brighttv_final`;


------------------------------------------------
---Average watch time per user
------------------------------------------------
select
    round(sum(duration_seconds) * 1.0 / count(distinct userid), 2) as avg_watch_time_per_user_seconds,
    round((sum(duration_seconds) * 1.0 / count(distinct userid)) / 60.0, 2) as avg_watch_time_per_user_minutes
from `workspace`.`default`.`brighttv_final`;


------------------------------------------------
---Engagement by gender
------------------------------------------------
select
    gender,
    count(distinct userid) as unique_users,
    count(*) as total_sessions,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    round(avg(duration_seconds), 2) as avg_session_duration_seconds
from `workspace`.`default`.`brighttv_final`
group by gender
order by total_watch_time_minutes desc;


------------------------------------------------
---Engagement by province
------------------------------------------------
select
    province,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes
from `workspace`.`default`.`brighttv_final`
group by province
order by total_watch_time_minutes desc
limit 8;

------------------------------------------------
---Age group segmentation
------------------------------------------------
select
    case
        when age < 18 then 'under 18'
        when age between 18 and 24 then '18-24'
        when age between 25 and 34 then '25-34'
        when age between 35 and 44 then '35-44'
        when age between 45 and 54 then '45-54'
        else '55+'
    end as age_group,
    count(distinct userid) as unique_users,
    count(*) as total_sessions,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    round(avg(duration_seconds), 2) as avg_session_duration_seconds
from `workspace`.`default`.`brighttv_final`
group by
    case
        when age < 18 then 'under 18'
        when age between 18 and 24 then '18-24'
        when age between 25 and 34 then '25-34'
        when age between 35 and 44 then '35-44'
        when age between 45 and 54 then '45-54'
        else '55+'
    end
order by age_group;


------------------------------------------------
---Most watched channels by gender
------------------------------------------------
select
    gender,
    channel,
    count(*) as total_views,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes
from `workspace`.`default`.`brighttv_final`
group by gender, channel
order by gender, total_watch_time_minutes desc;


------------------------------------------------
---Most watched channels by province
------------------------------------------------
select
    province,
    channel,
    count(*) as total_views,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes
from `workspace`.`default`.`brighttv_final`
group by province, channel
order by province, total_watch_time_minutes desc;


------------------------------------------------
---What performs best on low days
------------------------------------------------
select
    channel,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    count(*) as total_views,
    round(avg(duration_seconds), 2) as avg_session_duration_seconds
from `workspace`.`default`.`brighttv_final`
where day_name in ('Monday', 'Tuesday', 'Wednesday', 'Thursday')
group by channel
order by total_watch_time_minutes desc;


------------------------------------------------
---Which age groups engage more on low days
------------------------------------------------
select
    case
        when age < 18 then 'under 18'
        when age between 18 and 24 then '18-24'
        when age between 25 and 34 then '25-34'
        when age between 35 and 44 then '35-44'
        when age between 45 and 54 then '45-54'
        else '55+'
    end as age_group,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes
from `workspace`.`default`.`brighttv_final`
where day_name in ('Monday', 'Tuesday', 'Wednesday', 'Thursday')
group by
    case
        when age < 18 then 'under 18'
        when age between 18 and 24 then '18-24'
        when age between 25 and 34 then '25-34'
        when age between 35 and 44 then '35-44'
        when age between 45 and 54 then '45-54'
        else '55+'
    end
order by total_watch_time_minutes desc;


------------------------------------------------
---Provinces with strongest opportunity
------------------------------------------------
select
    province,
    count(distinct userid) as unique_users,
    round(sum(duration_seconds) / 60.0, 2) as total_watch_time_minutes,
    round(avg(duration_seconds), 2) as avg_session_duration_seconds
from `workspace`.`default`.`brighttv_final`
group by province
order by unique_users desc;


------------------------------------------------
---Peak Viewing Hours
------------------------------------------------
select
    watch_hour,
    count(*) as total_sessions
from `workspace`.`default`.`brighttv_final`
group by watch_hour
order by watch_hour;
