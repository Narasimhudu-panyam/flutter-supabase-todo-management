-- Safe additive migration to add reminder_at for task notifications
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS reminder_at TIMESTAMP WITH TIME ZONE;
