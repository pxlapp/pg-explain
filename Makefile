pxl:
	@./node_modules/.bin/vue-tsc --noEmit
	@./node_modules/.bin/vite -c vite.pxl.config.ts build