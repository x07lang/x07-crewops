const currencyFmt = new Intl.NumberFormat('en-US', {
	style: 'currency',
	currency: 'USD'
});

export function formatCurrency(cents: number): string {
	return currencyFmt.format(cents / 100);
}

export function formatDate(iso: string): string {
	if (!iso) return '—';
	const d = new Date(iso);
	return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export function formatDateTime(iso: string): string {
	if (!iso) return '—';
	const d = new Date(iso);
	return d.toLocaleString('en-US', {
		month: 'short',
		day: 'numeric',
		hour: 'numeric',
		minute: '2-digit'
	});
}

export function capitalize(s: string): string {
	return s.charAt(0).toUpperCase() + s.slice(1);
}

export function statusTone(
	status: string
): 'success' | 'warning' | 'danger' | 'info' | undefined {
	switch (status) {
		case 'completed':
		case 'approved':
		case 'paid':
		case 'active':
		case 'accepted':
		case 'healthy':
			return 'success';
		case 'in_progress':
		case 'pending':
		case 'awaiting_review':
		case 'awaiting_approval':
		case 'partial':
			return 'warning';
		case 'overdue':
		case 'rejected':
		case 'failed':
		case 'cancelled':
		case 'error':
		case 'unhealthy':
			return 'danger';
		case 'draft':
		case 'new':
		case 'open':
		case 'scheduled':
		case 'issued':
			return 'info';
		default:
			return undefined;
	}
}
