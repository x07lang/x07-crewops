import type { Role } from '$lib/wasm/types.js';

export interface NavItem {
	id: string;
	label: string;
	href: string;
	icon: string;
}

export interface NavSection {
	title: string;
	items: NavItem[];
}

export const NAV_BY_ROLE: Record<Role, NavSection[]> = {
	technician: [
		{
			title: 'Field',
			items: [
				{ id: 'today', label: 'Today', href: '/today', icon: 'calendar' },
				{ id: 'activity', label: 'Activity', href: '/activity', icon: 'activity' }
			]
		}
	],
	dispatcher: [
		{
			title: 'Dispatch',
			items: [
				{ id: 'dispatch', label: 'Dispatch Board', href: '/dispatch', icon: 'dispatch' },
				{ id: 'customers', label: 'Customers', href: '/customers', icon: 'users' },
				{ id: 'sites', label: 'Sites', href: '/sites', icon: 'map-pin' },
				{ id: 'assets', label: 'Assets', href: '/assets', icon: 'wrench' }
			]
		}
	],
	supervisor: [
		{
			title: 'Quality',
			items: [
				{ id: 'review', label: 'Review Queue', href: '/review', icon: 'check-circle' },
				{ id: 'activity', label: 'Activity', href: '/activity', icon: 'activity' }
			]
		}
	],
	manager: [
		{
			title: 'Operations',
			items: [
				{ id: 'manager', label: 'Dashboard', href: '/manager', icon: 'layout-dashboard' },
				{ id: 'finance', label: 'Finance', href: '/finance', icon: 'dollar-sign' },
				{ id: 'pricing', label: 'Pricing', href: '/pricing', icon: 'tag' },
				{ id: 'invoices', label: 'Invoices', href: '/invoices', icon: 'file-text' },
				{ id: 'receivables', label: 'Receivables', href: '/receivables', icon: 'trending-up' },
				{ id: 'exports', label: 'Exports', href: '/exports', icon: 'download' }
			]
		},
		{
			title: 'Commercial',
			items: [
				{ id: 'estimates', label: 'Estimates', href: '/estimates', icon: 'clipboard' },
				{ id: 'contracts', label: 'Contracts', href: '/contracts', icon: 'file-check' },
				{ id: 'recurring', label: 'Recurring', href: '/recurring', icon: 'repeat' },
				{
					id: 'integrations',
					label: 'Integrations',
					href: '/integrations',
					icon: 'plug'
				}
			]
		}
	],
	portal_user: [
		{
			title: 'Portal',
			items: [{ id: 'portal', label: 'Portal', href: '/portal', icon: 'globe' }]
		}
	],
	enterprise_admin: [
		{
			title: 'Enterprise',
			items: [
				{
					id: 'enterprise',
					label: 'Administration',
					href: '/enterprise',
					icon: 'shield'
				},
				{ id: 'inventory', label: 'Inventory', href: '/inventory', icon: 'package' },
				{
					id: 'procurement',
					label: 'Procurement',
					href: '/procurement',
					icon: 'shopping-cart'
				},
				{
					id: 'integration_dashboard',
					label: 'Connectors',
					href: '/integration-dashboard',
					icon: 'link'
				}
			]
		}
	]
};

export const ROLE_LABELS: Record<Role, string> = {
	technician: 'Technician',
	dispatcher: 'Dispatcher',
	supervisor: 'Supervisor',
	manager: 'Manager',
	portal_user: 'Portal User',
	enterprise_admin: 'Enterprise Admin'
};

export const ROLE_DEFAULT_ROUTE: Record<Role, string> = {
	technician: '/today',
	dispatcher: '/dispatch',
	supervisor: '/review',
	manager: '/manager',
	portal_user: '/portal',
	enterprise_admin: '/enterprise'
};
