from django.urls import path

from .views import (
    zonal_areas,
    zonal_dashboard,
    zonal_manager_detail,
    zonal_manager_report,
    zonal_managers,
    zonal_me,
    zonal_note_detail,
    zonal_notes,
    zonal_notices,
)

urlpatterns = [
    path("me/", zonal_me, name="zonal-me"),
    path("dashboard/", zonal_dashboard, name="zonal-dashboard"),
    path("notices/", zonal_notices, name="zonal-notices"),
    path("areas/", zonal_areas, name="zonal-areas"),
    path("notes/", zonal_notes, name="zonal-notes"),
    path("notes/<int:note_id>/", zonal_note_detail, name="zonal-note-detail"),
    path("managers/", zonal_managers, name="zonal-managers"),
    path("managers/<int:manager_id>/", zonal_manager_detail, name="zonal-manager-detail"),
    path("managers/<int:manager_id>/report/", zonal_manager_report, name="zonal-manager-report"),
]
