# Prints the pages script/ui_snapshots.mjs captures, as JSON.
# Needs the demo data from `bin/rails db:seed:replant dev:ui_states`.
#
#   bin/rails runner script/ui_pages.rb > tmp/ui_pages.json
include Rails.application.routes.url_helpers

yoga = Client.find_by!(code: "DEMOYOGA")
cafe = Client.find_by!(code: "DEMOCAFE")
course = yoga.projects.find_by!(name: "網上課程 + Landing page")
site = yoga.projects.find_by!(name: "品牌網站")
app = cafe.projects.find_by!(name: "會員 App")
failed_round = app.uat_rounds.find_by!(number: 1)
open_round = app.uat_rounds.find_by!(number: 2)
ticket = site.tickets.order(:id).first
sign_off = SignOff.order(:id).last

pages = {
  guest: [
    [ "sign-in", new_session_path ],
    [ "forgot-password", new_password_path ]
  ],
  admin: [
    [ "dashboard", admin_root_path ],
    [ "clients", admin_clients_path ],
    [ "client-retainer", admin_client_path(yoga) ],
    [ "client-no-retainer", admin_client_path(cafe) ],
    [ "client-new", new_admin_client_path ],
    [ "projects", admin_projects_path ],
    [ "project-uat", admin_project_path(app) ],
    [ "project-open-round", admin_project_path(course) ],
    [ "project-maintenance", admin_project_path(site) ],
    [ "external-sign-off-new", new_admin_project_external_sign_off_path(site) ],
    [ "system-link-new", new_admin_project_system_link_path(site) ],
    [ "round-failed", admin_project_uat_round_path(app, failed_round) ],
    [ "test-case-new", new_admin_project_test_case_path(app) ],
    [ "cr-new", new_admin_project_change_request_path(app) ],
    [ "tickets", admin_tickets_path ],
    [ "ticket", admin_ticket_path(ticket) ],
    [ "report", admin_maintenance_report_path(client_id: yoga.id) ],
    [ "retention", admin_retention_path ],
    [ "retainer-edit", edit_admin_client_retainer_plan_path(yoga) ],
    [ "sign-offs", admin_sign_offs_path ],
    ([ "sign-off", admin_sign_off_path(sign_off) ] if sign_off),
    [ "not-found", "/does-not-exist" ]
  ].compact,
  yoga: [
    [ "portal-projects", portal_projects_path ],
    [ "portal-project-uat", portal_project_path(course) ],
    [ "portal-project-maintenance", portal_project_path(site) ],
    [ "portal-round", portal_project_uat_round_path(course, course.uat_rounds.first) ],
    [ "portal-ticket-new-extra", new_portal_project_ticket_path(site) ],
    [ "portal-ticket", portal_project_ticket_path(site, ticket) ],
    [ "portal-retainer", portal_retainer_path ],
    [ "portal-system", portal_project_system_path(site) ],
    [ "portal-report", portal_report_path ],
    ([ "portal-sign-off", portal_sign_off_path(sign_off) ] if sign_off)
  ].compact,
  cafe: [
    [ "portal-cafe-project", portal_project_path(app) ],
    [ "portal-cafe-round", portal_project_uat_round_path(app, open_round) ]
  ],
  tutor: [
    [ "portal-retainer-notice", portal_retainer_path ]
  ]
}

puts JSON.pretty_generate(pages)
