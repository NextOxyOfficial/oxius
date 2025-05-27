#!/usr/bin/env python
"""
Script to recreate the elearning tables in the database.
This is a direct fix for when migrations are not working properly.
"""

import os
import django

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

# Now that Django is set up, we can import models
from django.db import connection

# SQL statements to create tables
CREATE_BATCH_TABLE = """
CREATE TABLE IF NOT EXISTS elearning_batch (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(500),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
"""

CREATE_DIVISION_TABLE = """
CREATE TABLE IF NOT EXISTS elearning_division (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(500),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
"""

CREATE_DIVISION_BATCH_TABLE = """
CREATE TABLE IF NOT EXISTS elearning_division_batches (
    id SERIAL PRIMARY KEY,
    division_id INTEGER NOT NULL REFERENCES elearning_division(id),
    batch_id INTEGER NOT NULL REFERENCES elearning_batch(id),
    UNIQUE(division_id, batch_id)
);
"""

CREATE_SUBJECT_TABLE = """
CREATE TABLE IF NOT EXISTS elearning_subject (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(30) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(500),
    color VARCHAR(20) DEFAULT '#3B82F6',
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
"""

CREATE_SUBJECT_DIVISION_TABLE = """
CREATE TABLE IF NOT EXISTS elearning_subject_divisions (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER NOT NULL REFERENCES elearning_subject(id),
    division_id INTEGER NOT NULL REFERENCES elearning_division(id),
    UNIQUE(subject_id, division_id)
);
"""

CREATE_VIDEOLESSON_TABLE = """
CREATE TABLE IF NOT EXISTS elearning_videolesson (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    title_bn VARCHAR(200),
    description TEXT NOT NULL,
    description_bn TEXT,
    youtube_url VARCHAR(200) NOT NULL,
    lesson_name VARCHAR(100) NOT NULL,
    lesson_name_bn VARCHAR(100),
    duration VARCHAR(10) NOT NULL,
    thumbnail_url VARCHAR(200),
    views_count INTEGER NOT NULL DEFAULT 0,
    subject_id INTEGER NOT NULL REFERENCES elearning_subject(id),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
"""

def recreate_tables():
    """Recreate all elearning tables."""
    with connection.cursor() as cursor:
        # Create tables
        cursor.execute(CREATE_BATCH_TABLE)
        cursor.execute(CREATE_DIVISION_TABLE)
        cursor.execute(CREATE_DIVISION_BATCH_TABLE)
        cursor.execute(CREATE_SUBJECT_TABLE)
        cursor.execute(CREATE_SUBJECT_DIVISION_TABLE)
        cursor.execute(CREATE_VIDEOLESSON_TABLE)
        
        print("Tables created successfully!")

if __name__ == "__main__":
    recreate_tables()
