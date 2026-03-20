-- Supabase-oriented seed data for AgroBrain360
-- Before running this file, make sure a user already exists in auth.users
-- and therefore in public.profiles. Replace the email below with a real user.

insert into public.crop_scans (
  user_id,
  disease,
  confidence,
  crop_type,
  severity,
  treatment
)
select
  p.id,
  'Tomato___Early_blight',
  0.91,
  'Tomato',
  'medium',
  'Spray Mancozeb or Chlorothalonil every 7 days.'
from public.profiles p
where p.email = 'farmer@example.com';

insert into public.livestock_recs (
  user_id,
  animal_type,
  symptoms,
  disease,
  risk_level,
  treatment
)
select
  p.id,
  'Cow',
  'fever lethargy reduced appetite',
  'Respiratory Infection',
  'medium',
  'Consult a vet for Respiratory Infection treatment protocol.'
from public.profiles p
where p.email = 'farmer@example.com';

insert into public.health_index (
  user_id,
  crop_score,
  soil_score,
  water_score,
  livestock_score,
  machinery_score,
  fhi_score
)
select
  p.id,
  82,
  75,
  78,
  70,
  68,
  76.6
from public.profiles p
where p.email = 'farmer@example.com';
