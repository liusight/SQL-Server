use msdb;
Select top 20 sj.job_id as [Job ID]
,       sj.name as [Job Name]
,       sl.name as [Owner Name]
,       (Select count(*) from sysjobschedules js1 where js1.job_id = sj.job_id ) as [Schedules Count]
,       (Select count(*) from sysjobsteps js2 where js2.job_id = sj.job_id ) as [Steps Count]
,       (Select count(*) from sysjobhistory jh1 where jh1.job_id=sj.job_id and jh1.step_id = 0 and jh1.run_status = 0 and datediff( day, convert(datetime, convert( varchar, jh1.run_date) ), getdate()) < 7  ) as [Failure Count]
,       (Select avg(((run_duration/10000*3600) + ((run_duration%10000)/100*60) + (run_duration%100))+0.0) from sysjobhistory jh2 where jh2.job_id=sj.job_id and jh2.step_id = 0 and datediff( day, convert(datetime, convert( varchar, jh2.run_date) ), getdate()) < 7  ) as [Average Run Duration]
,       (Select avg(retries_attempted+0.0) from sysjobhistory jh2 where jh2.job_id=sj.job_id and jh2.step_id = 0 and datediff( day, convert(datetime, convert( varchar, jh2.run_date) ), getdate()) < 7  ) as [Average  Retries Attempted]
,       Count(*) as [Execution Count]
, 1 as l1
from sysjobhistory jh
inner join sysjobs sj on ( jh.job_id = sj.job_id )
inner join sys.syslogins sl on ( sl.sid = sj.owner_sid )
where jh.step_id = 0 and datediff( day, convert(datetime, convert( varchar, jh.run_date) ), getdate()) < 7 
group by sj.job_id, sj.name, sl.name
order by [Execution Count] desc