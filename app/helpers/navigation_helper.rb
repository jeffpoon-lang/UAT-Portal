# The admin sidebar and the client portal tabs. Each item lists the
# controllers that count as "inside" it, for the active state.
module NavigationHelper
  NavItem = Data.define(:label, :path, :icon, :match)

  def admin_nav_sections
    [
      [ "概覽", [
        NavItem.new("Dashboard", admin_root_path, "layout-dashboard", %w[admin/dashboard])
      ] ],
      [ "交付", [
        NavItem.new("Projects", admin_projects_path, "folder-kanban",
                    %w[admin/projects admin/uat_rounds admin/test_cases admin/change_requests]),
        NavItem.new("客戶", admin_clients_path, "users", %w[admin/clients admin/retainer_plans admin/handover_items]),
        NavItem.new("Sign-offs", admin_sign_offs_path, "file-check-2", %w[admin/sign_offs])
      ] ],
      [ "維護", [
        NavItem.new("Tickets", admin_tickets_path, "life-buoy", %w[admin/tickets admin/ticket_logs]),
        NavItem.new("月尾報告", admin_maintenance_report_path, "file-text", %w[admin/reports admin/monthly_updates]),
        NavItem.new("Retention", admin_retention_path, "activity", %w[admin/retention])
      ] ]
    ]
  end

  def portal_nav_items(user = Current.user)
    items = [ NavItem.new("我嘅 project", portal_projects_path, "folder-kanban",
                          %w[portal/projects portal/uat_rounds portal/test_results portal/tickets portal/sign_offs]) ]
    if user.client&.retainer_plan
      items << NavItem.new("月費維護", portal_retainer_path, "wallet", %w[portal/retainers portal/handover_items])
    end
    items
  end

  def nav_current?(item) = item.match.include?(controller_path)

  def nav_link(item, css: "nav-item", count: nil)
    link_to item.path, class: css, "aria-current": (nav_current?(item) ? "page" : nil) do
      safe_join([
        (icon(item.icon) unless css == "tab"),
        tag.span(item.label),
        (tag.span(safe_join([ count, tag.span(" 張未解決", class: "sr-only") ]), class: "nav-count") if count.to_i.positive?)
      ].compact)
    end
  end
end
