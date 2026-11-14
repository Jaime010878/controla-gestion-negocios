-- Add private payment receipt attachment support to sales.
-- Existing private receipts bucket and business-folder RLS policies are reused.
alter table public.sales add column if not exists receipt_path text;
