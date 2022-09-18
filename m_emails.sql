drop table [noblelawreports].[dbo].[tmp_matter_emails]
select 

--parent_email_id
association_id as LegacyAssociation_Id
,e.email_id as LegacyId__c
,action_id
,sm.Id as RelatedToId
--,case 
--when eat.attachment_id is not null then '1'
--else 0
--end as HasAttachment
--,[status]
,left(isnull(email_bcc , '') , 4000) as BccAddress
,left(isnull(email_cc , '') ,4000) as CcAddress_tmp
,left(isnull([subject] , ''),3000) as [Subject]
,left(isnull(body_html , '') , 32000) as HtmlBody
,left(isnull(body_text, '') , 32000) as TextBody
,left(isnull(email_to , '') ,4000) as ToAddress_tmp
--,isnull(replace(substring(email_to,charindex( '<' , email_to)+1,LEN(ltrim(rtrim(email_to)))) ,'>' , ''),'') as ToAddress
,isnull(replace(substring(email_from,charindex( '<' , email_from)+1,LEN(ltrim(rtrim(email_from)))) ,'>' , ''),'') as FromAddress

,case 
when direction = 'I' then  '1'
else '0'
end as Incoming
,left(isnull(received_timestamp , '') ,19) as Received_Date__c
,left(isnull(created_timestamp , '') , 19) as  createddate
,left(isnull(sent_timestamp , ''),19) as MessageDate
,created_by_participant_id
,xx.display_name
,isnull(u.id , '') as createdById
INTO [noblelawreports].[dbo].[tmp_matter_emails]
from 
email_association ea
join
email e
on ea.email_id = e.email_id
join
z_sf_Matters sm
on sm.Legacy_Id_c = ea.action_id
--left join
--email_attachment eat
--on e.email_id = eat.email_id
left join
(select participant_id , display_name from action_participants  
group by participant_id , display_name) xx
on xx.participant_id = created_by_participant_id
left join
[User] u
on u.Name = xx.display_name
where ea.action_id is not null and action_id = 998 


--- WORKING ON CC ADDRESS



------------------------ WORKING TOADDRESS ------------------------------------------
drop table [noblelawreports].[dbo].[tmp_to_emails]
select 
LegacyId__c , ToAddress_tmp 
,isnull(replace(substring([value],charindex( '<' , [value])+1,LEN(ltrim(rtrim([value])))) ,'>' , ''),'') as [mains]
INTO [noblelawreports].[dbo].[tmp_to_emails]
from
(
select LegacyId__c,ToAddress_tmp 
from 
tmp_matter_emails
)aa
CROSS APPLY STRING_SPLIT(ToAddress_tmp, ',') 

-- UPD

alter table [noblelawreports].[dbo].[tmp_matter_emails]
ADD ToAddress nvarchar(max)

update  [noblelawreports].[dbo].[tmp_matter_emails]
set ToAddress = 
CcAddress_1
from [noblelawreports].[dbo].[tmp_matter_emails] tme
left join
(select LegacyId__c,
isnull(stuff
(STUFF ((select distinct ',' + [mains]  
from [noblelawreports].[dbo].[tmp_to_emails] t2
where t2.LegacyId__c = t1.LegacyId__c 
for xml path ('')),1,1,''),1,1,''),'')
 AS CcAddress_1
from [noblelawreports].[dbo].[tmp_to_emails] t1
group by LegacyId__c
)aa
on tme.LegacyId__c = aa.LegacyId__c





------------------------ Working CCADDRESS  ------------------------------------------


drop table [noblelawreports].[dbo].[tmp_cc_emails]
select 
LegacyId__c , CcAddress_tmp 
,isnull(replace(substring([value],charindex( '<' , [value])+1,LEN(ltrim(rtrim([value])))) ,'>' , ''),'') as [mains]
INTO [noblelawreports].[dbo].[tmp_cc_emails]
from
(
select LegacyId__c,CcAddress_tmp 
from 
tmp_matter_emails
)aa
CROSS APPLY STRING_SPLIT(CcAddress_tmp, ',') 

-- UPD
alter table [noblelawreports].[dbo].[tmp_matter_emails]
ADD CcAddress nvarchar(max)

update  [noblelawreports].[dbo].[tmp_matter_emails]
set CcAddress = 
CcAddress_1
from [noblelawreports].[dbo].[tmp_matter_emails] tme
left join
(select LegacyId__c,
isnull(stuff
(STUFF ((select distinct ',' + [mains]  
from [noblelawreports].[dbo].[tmp_cc_emails] t2
where t2.LegacyId__c = t1.LegacyId__c 
for xml path ('')),1,1,''),1,1,''),'')
 AS CcAddress_1
from [noblelawreports].[dbo].[tmp_cc_emails] t1
group by LegacyId__c
)aa
on tme.LegacyId__c = aa.LegacyId__c