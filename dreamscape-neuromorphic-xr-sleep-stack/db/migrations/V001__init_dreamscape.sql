-- V001 migration: apply the DreamScape initial schema

-- This migration applies the schema in db/schema/dreamscape_neuro_xr_v1_0_0.sql
-- For CI or migration tools, you may choose to include the raw SQL instead.

\i db/schema/dreamscape_neuro_xr_v1_0_0.sql
