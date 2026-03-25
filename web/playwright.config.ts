import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
	webServer: {
		command: 'npm run build && npm run preview',
		port: 4173
	},
	testDir: 'e2e',
	testMatch: /(.+\.)?spec\.ts/,
	projects: [
		{
			name: 'chromium',
			use: { ...devices['Desktop Chrome'] }
		}
	]
});
